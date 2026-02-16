`timescale 1ns/1ps

module diamond_mine_shimmer #(
    parameter integer CLK_HZ = 1000,
    parameter integer OSC1_HALF_PERIOD_MS = 280,
    parameter integer OSC2_HALF_PERIOD_MS = 320,
    parameter integer FADE_STEP_MS = 184
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       dark,
    output wire       steady_drive,
    output wire       twinkle1_drive,
    output wire       twinkle2_drive,
    output reg  [7:0] fade_level
);

    localparam integer MS_TICKS = CLK_HZ / 1000;

    reg [31:0] ms_div;
    reg        tick_1ms;

    reg [15:0] osc1_ctr;
    reg [15:0] osc2_ctr;
    reg        tw1;
    reg        tw2;

    reg [15:0] fade_ctr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ms_div <= 0;
            tick_1ms <= 1'b0;
        end else if (ms_div == (MS_TICKS - 1)) begin
            ms_div <= 0;
            tick_1ms <= 1'b1;
        end else begin
            ms_div <= ms_div + 1'b1;
            tick_1ms <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            osc1_ctr <= 0;
            osc2_ctr <= 0;
            tw1 <= 1'b0;
            tw2 <= 1'b0;
        end else if (tick_1ms) begin
            if (!dark) begin
                tw1 <= 1'b0;
                tw2 <= 1'b0;
                osc1_ctr <= 0;
                osc2_ctr <= 0;
            end else begin
                if (osc1_ctr >= OSC1_HALF_PERIOD_MS - 1) begin
                    osc1_ctr <= 0;
                    tw1 <= ~tw1;
                end else begin
                    osc1_ctr <= osc1_ctr + 1'b1;
                end

                if (osc2_ctr >= OSC2_HALF_PERIOD_MS - 1) begin
                    osc2_ctr <= 0;
                    tw2 <= ~tw2;
                end else begin
                    osc2_ctr <= osc2_ctr + 1'b1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fade_level <= 8'd0;
            fade_ctr <= 0;
        end else if (tick_1ms) begin
            if (dark) begin
                if (fade_level < 8'hFF) begin
                    if (fade_ctr >= FADE_STEP_MS - 1) begin
                        fade_ctr <= 0;
                        fade_level <= fade_level + 1'b1;
                    end else begin
                        fade_ctr <= fade_ctr + 1'b1;
                    end
                end
            end else begin
                fade_level <= 8'd0;
                fade_ctr <= 0;
            end
        end
    end

    assign steady_drive = dark && (fade_level > 8'd20);
    assign twinkle1_drive = dark && tw1;
    assign twinkle2_drive = dark && tw2;

endmodule
