# Build Guide — Diamond Mine Shimmer (Breadboard Prototype)

Step-by-step assembly and testing for the corrected circuit on a solderless
breadboard. Follow in order — each phase includes a verification step so you
catch wiring errors before they compound.

**Required references during assembly:**
- [breadboard-layout.md](breadboard-layout.md) — physical row/column placement
- [schematic.md](schematic.md) — electrical connections
- [bill-of-materials.md](bill-of-materials.md) — parts list

---

## Tools Required

- Multimeter (DC voltage, continuity)
- Needle-nose pliers and wire cutters
- Small flat-blade screwdriver (for trimpots)
- 830-point solderless breadboard
- 22 AWG solid-core jumper wire kit (assorted colors)
- Dark cloth or opaque cup (to cover LDR during testing)

---

## Phase 1 — Power Rails

### Step 1: Battery and Rails

1. Connect 3x AA NiMH cells into the battery holder (series = ~3.6V).
2. Wire Battery+ to the (+) rail, Battery- to the (-) rail.
3. Measure across the rails with a multimeter: expect 3.6–4.0V.

### Step 2: Solar Charge Path

1. Insert the 10-ohm (1/2W) resistor from Row 1 to Row 2.
2. Insert the 1N5819 Schottky diode: anode at Row 2, cathode (banded end) at Row 3.
3. Jumper from Row 3 to the (+) rail.
4. Connect Solar+ wire to Row 1, Solar- wire to the (-) rail.

### Step 3: Bypass Capacitor

1. Place a 0.1uF ceramic cap spanning the (+) and (-) rails at Row 14
   (within one row of where Pin 14 will land).

### Verify Phase 1

- Disconnect solar panels (or cover them).
- Measure (+) to (-) rail: should read battery voltage (~3.6V).
- With panels connected in light: measure voltage at Row 1 (solar side of R_charge).
  Should read ~5V. Measure at Row 3 (after diode): should read ~4.5–5V.

---

## Phase 2 — CD4093 IC

### Step 4: IC Socket / Placement

1. Place the CD4093 (or DIP-14 socket) straddling the center channel at rows 15–21.
   Pin 1 at Row 15 col E, Pin 14 at Row 15 col F.
2. Wire Pin 14 (Row 15, col J side) to (+) rail — IC power.
3. Wire Pin 7 (Row 21, col E side) to (-) rail — IC ground.

### Step 5: Unused Gate 4

1. Wire Pin 13 (Row 16, col J) to (+) rail.
2. Wire Pin 12 (Row 17, col J) to (+) rail.
3. Leave Pin 11 unconnected.

### Step 6: Tie Gate 1 Inputs

1. Jumper from Row 15 col A (Pin 1) to Row 16 col A (Pin 2).

### Verify Phase 2

- Power on. Measure Pin 14 vs Pin 7: should read ~3.6V.
- Measure Pin 11 (Gate 4 output): should read near 0V (NAND with both inputs HIGH = LOW).
- Touch a jumper wire from Pin 1 to (-) rail briefly: Pin 3 should snap HIGH (~3.6V).
  Release: Pin 3 should return LOW.

---

## Phase 3 — Dusk Detector

### Step 7: LDR and Divider

1. Insert LDR: one leg at Row 6 (wire to (+) rail), other leg at Row 8 (SENSE node).
2. Jumper from Row 8 to Row 15 col A (connects SENSE to Pin 1/2).
3. Insert 470k resistor from Row 8 to Row 11.
4. Wire the 100k dusk trimpot: wiper + end 1 at Row 11, end 2 to (-) rail.
5. Insert 47k resistor from Row 11 to (-) rail.

### Verify Phase 3

- In room light: measure Pin 3 (Row 17, col A). Should read near 0V (LOW).
- Cover LDR with dark cloth: Pin 3 should snap to ~3.6V (HIGH).
- Adjust the dusk trimpot until the transition happens at your desired light level.
- Uncover LDR: Pin 3 should return LOW cleanly (no flickering — Schmitt hysteresis).

---

## Phase 4 — Fade-In Ramp

### Step 8: RC Network

1. Insert 470k resistor from Row 17 col C (DARK/Pin 3) to Row 23.
2. Jumper from Row 23 to Row 25 (FADE node).
3. Insert 100uF electrolytic: positive leg at Row 25, negative leg to (-) rail.

### Verify Phase 4

- Cover LDR (DARK = HIGH).
- Probe Row 25 (FADE node): voltage should start at ~0V and rise slowly toward 3.6V.
- After ~10 seconds: expect ~0.7V. After ~47 seconds: expect ~2.3V.
- Uncover LDR: voltage should drop back toward 0V within a few seconds.

---

## Phase 5 — Oscillators

### Step 9: Oscillator 1 (Gate 2)

1. Jumper DARK signal: Row 17 col A to Row 19 col A (connects Pin 3 to Pin 5).
2. Insert 1M resistor from Row 18 col A (Pin 4, output) to Row 28.
3. Wire 100k trimpot: Row 28 to Row 30.
4. Jumper from Row 30 to Row 20 col A (connects RC node to Pin 6).
5. Insert 0.47uF film cap from Row 30 to (-) rail.

### Step 10: Oscillator 2 (Gate 3)

1. Jumper DARK signal: Row 17 col A to Row 21 col J (connects Pin 3 to Pin 8).
2. Insert 1M resistor from Row 19 col J (Pin 10, output) to Row 33.
3. Wire 100k trimpot: Row 33 to Row 35.
4. Jumper from Row 35 to Row 20 col J (connects RC node to Pin 9).
5. Insert 0.47uF film cap from Row 35 to (-) rail.

### Verify Phase 5

- Cover LDR (DARK = HIGH).
- Probe Pin 4 (Row 18): should see a square wave. An LED + 1k resistor temporarily
  clipped from Pin 4 to (-) rail will blink visibly at ~2–3 Hz.
- Probe Pin 10 (Row 19 col J): same, slightly different rate.
- Adjust trimpots so the two rates are close but not identical. Recommended: RV2 at
  ~30%, RV3 at ~70%.
- Uncover LDR: both outputs should go HIGH and stay there (no blinking).

---

## Phase 6 — Transistor Drivers

### Step 11: Q1 — Steady Bank (NPN 2N3904)

1. Insert 2N3904 at Row 40 (flat side facing you: E-B-C left to right).
2. Wire col A (Emitter) to (-) rail.
3. Insert 10k resistor from FADE node (Row 25) to Row 40 col B (Base).
4. Col C (Collector) will connect to steady LEDs in Phase 7.

### Step 12: Q2 — Twinkle Bank 1 (PNP 2N3906)

1. Insert 2N3906 at Row 45 (flat side facing you: E-B-C left to right).
2. Wire col A (Emitter) to **(+) rail** — not GND! PNP emitter goes to VDD.
3. Insert 100k resistor from Pin 4/OSC1 (Row 18 col A) to Row 45 col B (Base).
4. Col C (Collector) will connect to twinkle LEDs in Phase 7.

### Step 13: Q3 — Twinkle Bank 2 (PNP 2N3906)

1. Insert 2N3906 at Row 50 (flat side facing you: E-B-C left to right).
2. Wire col A (Emitter) to **(+) rail**.
3. Insert 100k resistor from Pin 10/OSC2 (Row 19 col J) to Row 50 col B (Base).
4. Col C (Collector) will connect to twinkle LEDs in Phase 7.

### Verify Phase 6

- Cover LDR. Wait ~15 seconds for FADE to rise.
- Measure Q1 collector (Row 40 col C) to (-) rail: should show low voltage
  (transistor pulling toward GND), confirming Q1 is ON.
- Measure Q2 emitter (Row 45 col A) to Q2 collector (Row 45 col C): should toggle
  between ~0V (OFF) and ~3.4V (ON) at the oscillator rate.
- Same for Q3.
- Uncover LDR: all transistors should turn OFF. Q1 collector floats, Q2/Q3
  collectors float (no current path yet without LEDs).

---

## Phase 7 — LED Banks

### Step 14: Steady Bank (3 LEDs)

For each of 3 LEDs (Rows 55, 56, 57):
1. Insert 1.5k resistor from (+) rail to the row.
2. Insert LED: anode (long leg) to the resistor output, cathode (short leg/flat)
   toward Q1.
3. Wire cathode to Q1 collector (Row 40 col D).

### Step 15: Twinkle Bank 1 (3 LEDs)

For each of 3 LEDs (Rows 58, 59, 60):
1. Wire from Q2 collector (Row 45 col D) to the LED anode (long leg).
2. Insert LED: cathode (short leg) toward the resistor.
3. Insert 2.2k resistor from LED cathode to (-) rail.

### Step 16: Twinkle Bank 2 (3 LEDs)

For each of 3 LEDs (Rows 61, 62, 63):
1. Wire from Q3 collector (Row 50 col D) to the LED anode.
2. Insert LED: cathode toward the resistor.
3. Insert 2.2k resistor from LED cathode to (-) rail.

### Verify Phase 7

- In room light (LDR exposed): **all 9 LEDs should be OFF**.
  If any glow, check wiring — likely a PNP emitter/collector swap.
- Cover LDR with dark cloth. Within seconds:
  - Twinkle LEDs should begin blinking in two independent patterns.
  - Steady LEDs should slowly fade in over ~30–60 seconds.
- Uncover LDR: all LEDs should turn off within a few seconds.

---

## Phase 8 — Final Tuning

### Step 17: Dusk Sensitivity

1. Simulate twilight by partially covering the LDR.
2. Adjust the dusk trimpot (RV1) until the circuit activates at your desired
   ambient light level.
3. The Schmitt hysteresis provides a ~1.2V dead band, so the on/off points will
   differ slightly — this is correct and prevents flicker.

### Step 18: Shimmer Character

1. Cover LDR fully and observe the twinkle pattern.
2. Adjust RV2 (Oscillator 1 speed) and RV3 (Oscillator 2 speed).
3. For best shimmer: set the two rates close but not equal. The beat frequency
   (difference) creates the drift pattern:
   - Very close rates → slow, subtle drift (recommended)
   - Far apart → fast, complex pattern
   - Identical → synchronized flashing (avoid)

### Step 19: Brightness (optional)

If LEDs are too dim or too bright, swap resistor values:

| Change | Swap To | New Current |
|--------|---------|-------------|
| Brighter steady | 680 ohm | ~2.1 mA |
| Dimmer steady | 3.3k | ~0.42 mA |
| Brighter twinkle | 1k | ~1.4 mA |
| Dimmer twinkle | 4.7k | ~0.30 mA |

### Step 20: Solar Integration

1. Connect solar panels (parallel: all + together, all - together).
2. Place panels near a window or under a desk lamp.
3. Verify charging: measure voltage at Row 3 (after diode) — should exceed
   battery voltage by at least 0.5V when panels are illuminated.
4. Leave running overnight to confirm auto-activation at dusk.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| All LEDs always ON | DARK stuck HIGH; LDR disconnected or wrong | Check LDR wiring; adjust dusk trimpot |
| LEDs never turn on | DARK stuck LOW; battery dead | Check battery voltage (>3.0V); check Pin 3 while covering LDR |
| Steady LEDs on but no twinkle | Oscillators not running | Probe Pin 4/10 for square wave; check 0.47uF caps and 1M resistors |
| Twinkle on during daylight | PNP wired backwards (E/C swapped) | Verify Q2/Q3 emitters go to (+) rail, not (-) |
| Steady LEDs snap on (no fade) | Fade cap shorted, wrong polarity, or missing | Check 100uF polarity; verify 470k fade resistor |
| IC gets hot | Floating input on Gate 4 | Verify Pin 12 and Pin 13 tied to (+) rail |
| Very dim LEDs | Low battery or wrong LED color (white/blue) | Charge battery; use red/amber LEDs (Vf ~2.0V) |
| One LED bank dimmer than others | Resistor value wrong | Measure each resistor before inserting |
| Oscillators at same rate | Trimpots at identical positions | Adjust RV2/RV3 to different settings |
| Solar not charging | Panels too low voltage or reversed | Verify 5.5V panels; check diode orientation (band toward battery) |

---

## Current Draw Quick-Check

Use your multimeter in series with the battery (+) lead:

| Condition | Expected |
|-----------|----------|
| Daylight (LDR exposed) | < 0.05 mA (essentially zero) |
| Darkness (all LEDs active) | 4–7 mA (depends on instantaneous oscillator state) |
| Darkness (average over 30s) | ~5.1 mA |

If daylight draw exceeds 0.5 mA, a transistor is leaking — check Q2/Q3 PNP wiring.

---

## Next Steps After Prototyping

1. **Run for 24 hours** — verify day/night cycling, solar charging, and battery health.
2. **Transfer to perfboard** — solder all connections for permanent installation.
   Use a DIP-14 socket for the CD4093 so it can be replaced.
3. **Scatter LEDs** — extend LED leads with thin wire to position them throughout
   your "mine" enclosure. Randomness in placement adds to the organic feel.
4. **Seal the LDR** — if the installation is humid, coat the LDR with clear nail
   polish or epoxy to prevent moisture degradation.
