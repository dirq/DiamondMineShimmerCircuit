// ===========================================================================
// Diamond Mine Shimmer Circuit — Verilog Behavioral Model
// ===========================================================================
//
// This is a behavioral (non-synthesizable) Verilog model of the Diamond Mine
// Shimmer Circuit. It models the digital logic of the CD4093 gates and the
// high-level analog behavior of the RC timing networks, dusk detector, and
// LED drivers.
//
// PURPOSE:
//   - Functional verification of the logic flow
//   - Timing visualization of oscillator beat patterns
//   - Day/night state machine verification
//
// LIMITATIONS:
//   - Analog voltages approximated with real-valued variables
//   - Schmitt hysteresis modeled with explicit thresholds, not feedback
//   - LED current not precisely modeled (on/off only)
//   - Solar charging not modeled (power assumed available)
//
// SIMULATOR: Icarus Verilog (iverilog) or any Verilog simulator
//   iverilog -o sim diamond-mine-shimmer.v && vvp sim
//
// ===========================================================================

`timescale 1ms / 1us

// ===========================================================================
// CD4093 Schmitt-Trigger NAND Gate — Behavioral
// ===========================================================================
module cd4093_gate (
    input  wire inA,
    input  wire inB,
    output reg  out,
    input  wire vdd_ok    // power good indicator
);
    // Propagation delay ~125ns at 3.6V (modeled as 1us for simulation scale)
    parameter TPROP = 1;  // microseconds (scaled to 1ms timescale = 0.001)

    always @(*) begin
        if (!vdd_ok) begin
            out = 1'b0;
        end else begin
            // NAND: output LOW only when both inputs HIGH
            #0 out = ~(inA & inB);
        end
    end
endmodule

// ===========================================================================
// Schmitt-Trigger Oscillator — Behavioral
// ===========================================================================
// Models a CD4093 relaxation oscillator with gating input.
// When gate_enable is LOW, output is stuck HIGH (NAND behavior).
// When gate_enable is HIGH, oscillates at approximately 1/(1.2*R*C).
//
module schmitt_oscillator #(
    parameter real R_OHM   = 1050000.0,  // Total R (1M + trimpot)
    parameter real C_FARAD = 0.00000047  // 0.47uF
)(
    input  wire gate_enable,  // DARK signal (HIGH = night = oscillate)
    output reg  osc_out,
    input  wire vdd_ok
);
    // Calculate period: T = 1.2 * R * C (in milliseconds for timescale)
    localparam real PERIOD_SEC = 1.2 * R_OHM * C_FARAD;
    // Convert to integer ms for delay (half-period for 50% duty)
    localparam integer HALF_PERIOD_MS = $rtoi(PERIOD_SEC * 500.0);

    initial osc_out = 1'b1;

    always begin
        if (!vdd_ok) begin
            osc_out = 1'b0;
            #1;
        end else if (!gate_enable) begin
            // NAND with one input LOW → output stuck HIGH
            osc_out = 1'b1;
            #1;
        end else begin
            // Oscillating: toggle at half-period intervals
            osc_out = ~osc_out;
            #(HALF_PERIOD_MS);
        end
    end
endmodule

// ===========================================================================
// Fade-In Ramp — Behavioral
// ===========================================================================
// Models the 470k + 100uF RC charge/discharge with 8-bit resolution.
// Output represents the FADE voltage as a fraction of VDD (0–255).
//
module fade_ramp #(
    parameter real TAU_SEC = 47.0  // R * C = 470k * 100uF
)(
    input  wire       dark,       // DARK signal (HIGH = charging)
    output reg  [7:0] fade_level, // 0–255 representing 0V to VDD
    input  wire       clk_1ms,    // 1 ms tick clock
    input  wire       vdd_ok
);
    real voltage;          // 0.0 to 1.0 (fraction of VDD)
    real step_charge;      // per-ms charge increment
    real step_discharge;   // per-ms discharge (through 10k, ~1s tau)

    initial begin
        voltage = 0.0;
        fade_level = 8'd0;
        // Charge step: delta_V per ms = (1/tau) * dt = (1/47000) * 1 = 0.0000213
        step_charge = 1.0 / (TAU_SEC * 1000.0);
        // Discharge step: 10k * 100uF = 1s tau → fast discharge while Q1 conducts
        step_discharge = 1.0 / (1.0 * 1000.0);
    end

    always @(posedge clk_1ms) begin
        if (!vdd_ok) begin
            voltage = 0.0;
        end else if (dark) begin
            // Exponential charge toward 1.0
            voltage = voltage + (1.0 - voltage) * step_charge * 1000.0 / TAU_SEC;
            if (voltage > 1.0) voltage = 1.0;
        end else begin
            // Discharge (fast through Q1 base path, then slow through 470k)
            if (voltage > 0.194) begin
                // Above Vbe/VDD threshold: fast discharge through 10k path
                voltage = voltage - voltage * step_discharge * 1000.0;
            end else begin
                // Below Vbe: slow discharge through 470k
                voltage = voltage - voltage * step_charge * 1000.0 / TAU_SEC;
            end
            if (voltage < 0.001) voltage = 0.0;
        end
        fade_level = $rtoi(voltage * 255.0);
    end
endmodule

// ===========================================================================
// Dusk Detector — Behavioral
// ===========================================================================
// Models the LDR voltage divider + Schmitt-trigger Gate 1.
// Input: ambient_light (0 = pitch dark, 255 = bright)
// Output: dark signal (HIGH when dark enough)
//
module dusk_detector (
    input  wire [7:0] ambient_light,  // 0=dark, 255=bright
    output reg        dark,
    input  wire       vdd_ok
);
    // Schmitt thresholds (as fraction of 255):
    //   VT+ ~ 0.66 * 255 = 168 (rising threshold, light increasing)
    //   VT- ~ 0.33 * 255 = 84  (falling threshold, light decreasing)
    // SENSE voltage is inversely proportional to light (LDR on high side)
    // So: SENSE high in bright → Gate 1 output LOW
    //     SENSE low in dark   → Gate 1 output HIGH

    parameter THRESH_DARK = 80;   // Below this → DARK goes HIGH
    parameter THRESH_LIGHT = 160; // Above this → DARK goes LOW

    initial dark = 1'b0;

    always @(*) begin
        if (!vdd_ok) begin
            dark = 1'b0;
        end else if (ambient_light < THRESH_DARK && !dark) begin
            dark = 1'b1;  // Just got dark enough
        end else if (ambient_light > THRESH_LIGHT && dark) begin
            dark = 1'b0;  // Just got bright enough
        end
        // Otherwise hold current state (hysteresis)
    end
endmodule

// ===========================================================================
// LED Bank — Behavioral
// ===========================================================================
// Models a bank of LEDs driven by a transistor switch.
// For NPN: LED_on when drive is HIGH and fade_level > Vbe threshold
// For PNP: LED_on when drive is LOW (inverted)
//
module led_bank #(
    parameter NUM_LEDS = 3,
    parameter IS_PNP   = 0,       // 0 = NPN low-side, 1 = PNP high-side
    parameter USE_FADE = 0        // 1 = brightness controlled by fade_level
)(
    input  wire       drive,      // transistor base drive signal
    input  wire [7:0] fade_level, // fade brightness (0-255), used if USE_FADE=1
    output wire       leds_on,    // aggregate: are LEDs illuminated?
    output reg  [7:0] brightness  // 0-255 brightness level
);
    wire active_drive;
    assign active_drive = IS_PNP ? ~drive : drive;

    assign leds_on = (brightness > 0);

    always @(*) begin
        if (USE_FADE && active_drive) begin
            // Fade-controlled: brightness tracks fade_level
            // Q1 Vbe threshold ~ 0.7V/3.6V ~ 20% ~ 50/255
            if (fade_level > 50)
                brightness = fade_level;
            else
                brightness = 8'd0;
        end else if (!USE_FADE && active_drive) begin
            // Digital on/off (oscillator-driven)
            brightness = 8'd163;  // ~0.64 mA / 1.0 mA ≈ 64% of max
        end else begin
            brightness = 8'd0;
        end
    end
endmodule

// ===========================================================================
// TOP MODULE: Diamond Mine Shimmer Circuit
// ===========================================================================
module diamond_mine_shimmer (
    input  wire [7:0] ambient_light,  // External: light level (0=dark, 255=bright)
    input  wire       vdd_ok,         // External: power good
    output wire       dark,           // Dusk detector output
    output wire [7:0] fade_level,     // Fade ramp voltage (0-255)
    output wire       osc1_out,       // Oscillator 1 output
    output wire       osc2_out,       // Oscillator 2 output
    output wire       steady_on,      // Steady LED bank active
    output wire       twinkle1_on,    // Twinkle bank 1 active
    output wire       twinkle2_on,    // Twinkle bank 2 active
    output wire [7:0] steady_bright,  // Steady bank brightness
    output wire [7:0] twinkle1_bright,// Twinkle 1 brightness
    output wire [7:0] twinkle2_bright // Twinkle 2 brightness
);

    // --- 1 ms system tick for fade ramp ---
    reg clk_1ms;
    initial clk_1ms = 0;
    always #1 clk_1ms = ~clk_1ms;  // 1 ms period (with 1ms timescale)

    // --- Dusk Detector (Gate 1) ---
    dusk_detector u_dusk (
        .ambient_light(ambient_light),
        .dark(dark),
        .vdd_ok(vdd_ok)
    );

    // --- Fade-In Ramp ---
    fade_ramp #(.TAU_SEC(47.0)) u_fade (
        .dark(dark),
        .fade_level(fade_level),
        .clk_1ms(clk_1ms),
        .vdd_ok(vdd_ok)
    );

    // --- Oscillator 1 (Gate 2): 1M + 50k trim + 0.47uF → ~2.5 Hz ---
    schmitt_oscillator #(
        .R_OHM(1050000.0),
        .C_FARAD(0.00000047)
    ) u_osc1 (
        .gate_enable(dark),
        .osc_out(osc1_out),
        .vdd_ok(vdd_ok)
    );

    // --- Oscillator 2 (Gate 3): 1M + 80k trim + 0.47uF → ~2.4 Hz ---
    schmitt_oscillator #(
        .R_OHM(1080000.0),
        .C_FARAD(0.00000047)
    ) u_osc2 (
        .gate_enable(dark),
        .osc_out(osc2_out),
        .vdd_ok(vdd_ok)
    );

    // --- LED Bank: Steady (NPN Q1, fade-controlled) ---
    led_bank #(.NUM_LEDS(3), .IS_PNP(0), .USE_FADE(1)) u_steady (
        .drive(dark),          // Q1 driven by fade, but only if DARK
        .fade_level(fade_level),
        .leds_on(steady_on),
        .brightness(steady_bright)
    );

    // --- LED Bank: Twinkle 1 (PNP Q2) ---
    led_bank #(.NUM_LEDS(3), .IS_PNP(1), .USE_FADE(0)) u_twinkle1 (
        .drive(osc1_out),
        .fade_level(8'd0),
        .leds_on(twinkle1_on),
        .brightness(twinkle1_bright)
    );

    // --- LED Bank: Twinkle 2 (PNP Q3) ---
    led_bank #(.NUM_LEDS(3), .IS_PNP(1), .USE_FADE(0)) u_twinkle2 (
        .drive(osc2_out),
        .fade_level(8'd0),
        .leds_on(twinkle2_on),
        .brightness(twinkle2_bright)
    );

endmodule

// ===========================================================================
// TESTBENCH
// ===========================================================================
module tb_diamond_mine;
    reg  [7:0] ambient_light;
    reg        vdd_ok;
    wire       dark;
    wire [7:0] fade_level;
    wire       osc1_out, osc2_out;
    wire       steady_on, twinkle1_on, twinkle2_on;
    wire [7:0] steady_bright, twinkle1_bright, twinkle2_bright;

    diamond_mine_shimmer uut (
        .ambient_light(ambient_light),
        .vdd_ok(vdd_ok),
        .dark(dark),
        .fade_level(fade_level),
        .osc1_out(osc1_out),
        .osc2_out(osc2_out),
        .steady_on(steady_on),
        .twinkle1_on(twinkle1_on),
        .twinkle2_on(twinkle2_on),
        .steady_bright(steady_bright),
        .twinkle1_bright(twinkle1_bright),
        .twinkle2_bright(twinkle2_bright)
    );

    initial begin
        $dumpfile("diamond-mine-shimmer.vcd");
        $dumpvars(0, tb_diamond_mine);

        // --- Scenario: Full day/night cycle ---
        vdd_ok = 1;
        ambient_light = 8'd200;  // Bright daylight

        $display("=== Diamond Mine Shimmer — Behavioral Simulation ===");
        $display("Time(ms)  Light  Dark  Fade  Osc1  Osc2  Steady  Tw1  Tw2");

        // Daylight for 5 seconds (verify all LEDs off)
        #5000;
        $display("%0t    %0d     %b     %0d    %b     %b     %b       %b    %b",
                 $time, ambient_light, dark, fade_level,
                 osc1_out, osc2_out, steady_on, twinkle1_on, twinkle2_on);

        // Gradual dusk (light drops over 10 seconds)
        repeat (20) begin
            #500;
            if (ambient_light > 10)
                ambient_light = ambient_light - 10;
            else
                ambient_light = 0;
        end

        $display("%0t    %0d     %b     %0d    %b     %b     %b       %b    %b",
                 $time, ambient_light, dark, fade_level,
                 osc1_out, osc2_out, steady_on, twinkle1_on, twinkle2_on);

        // Full darkness for 60 seconds (observe fade-in and shimmer)
        ambient_light = 8'd0;
        #60000;
        $display("%0t    %0d     %b     %0d    %b     %b     %b       %b    %b",
                 $time, ambient_light, dark, fade_level,
                 osc1_out, osc2_out, steady_on, twinkle1_on, twinkle2_on);

        // Dawn (light returns)
        ambient_light = 8'd200;
        #5000;
        $display("%0t    %0d     %b     %0d    %b     %b     %b       %b    %b",
                 $time, ambient_light, dark, fade_level,
                 osc1_out, osc2_out, steady_on, twinkle1_on, twinkle2_on);

        $display("=== Simulation Complete ===");
        $finish;
    end

    // Periodic monitoring (every 5 seconds of simulation time)
    always #5000 begin
        if ($time > 0)
            $display("%0t    %0d     %b     %0d    %b     %b     %b       %b    %b",
                     $time, ambient_light, dark, fade_level,
                     osc1_out, osc2_out, steady_on, twinkle1_on, twinkle2_on);
    end

endmodule
