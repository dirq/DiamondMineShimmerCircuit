# Build Guide

> Step-by-step assembly instructions for the Diamond Mine Shimmer Circuit.

---

## Before You Begin

### Tools Required

- Soldering iron (25–40 W) and solder
- Wire cutters / strippers
- Needle-nose pliers
- Multimeter (for voltage checks and continuity)
- Small screwdriver (for trim pots)
- Prototyping board (perfboard) or breadboard for testing

### Safety Notes

- NiMH cells are low-voltage and safe, but avoid shorting them — they can deliver high current briefly.
- The 1N5819 Schottky diode has polarity — band (cathode) faces the battery positive terminal.
- Electrolytic capacitors are polarized — observe the stripe (negative) marking.

---

## Phase 1: Power Rail

### Step 1 — Battery Holder

1. Insert 3× AA NiMH cells into the holder (series connection = ~3.6 V).
2. Identify the positive (red) and negative (black) leads.
3. Measure open-circuit voltage with a multimeter — expect 3.6–4.0 V fully charged.

### Step 2 — Solar Charging Input

1. Wire 2–3 solar panels in **parallel**:
   - All positive leads joined together
   - All negative leads joined together
2. Solder the 1N5819 Schottky diode in series with the positive solar bus:
   ```
   Solar (+) ──►|── Battery (+)
              1N5819
              Band toward battery
   ```
3. Connect solar negative directly to battery negative.
4. Verify: cover panels (no light) → measure ~0 V across diode → battery does not discharge backward.

### Step 3 — Power Rails on Perfboard

1. Establish a VDD rail (top copper strip) and GND rail (bottom copper strip).
2. Connect battery positive → VDD rail.
3. Connect battery negative → GND rail.
4. Solder 0.1 µF ceramic capacitor across VDD and GND near the IC socket location.

---

## Phase 2: CD4093 Logic IC

### Step 4 — IC Socket (recommended)

1. Place a 14-pin DIP socket on the perfboard.
2. Solder pin 14 (VDD) to the VDD rail.
3. Solder pin 7 (GND) to the GND rail.
4. **Do not insert the IC yet** — solder surrounding components first.

### Step 5 — Unused Gate 4

1. Tie pin 12 (4A) to GND.
2. Tie pin 13 (4B) to GND.
3. Leave pin 11 (4Y) unconnected.

> Unused CMOS inputs must **never** float — they draw excessive current and may oscillate.

---

## Phase 3: Dusk Detector

### Step 6 — LDR Voltage Divider

1. Connect one leg of the LDR to VDD.
2. Connect the other leg to the **SENSE node** (a junction point).
3. Connect the 500 kΩ potentiometer from SENSE to GND:

```
VDD ──── [LDR] ──── SENSE ──── [500k Pot] ──── GND
                       │
                       └── To CD4093 Gate 1 input
```

### Step 7 — Gate 1 Wiring

1. Connect SENSE node to **both** pin 1 (1A) and pin 2 (1B) of the CD4093.
   - Tying both NAND inputs together makes it act as a Schmitt-trigger inverter.
2. Pin 3 (1Y) is now the **DARK enable signal**:
   - High when SENSE is below the lower Schmitt threshold (dark)
   - Low when SENSE is above the upper threshold (light)

### Step 8 — Test the Dusk Detector

1. Insert the CD4093 into its socket.
2. Power on (connect battery).
3. Measure pin 3:
   - In bright light → should read near 0 V (LOW)
   - Cover the LDR → should snap to ~3.6 V (HIGH)
4. Adjust the 500 kΩ pot to set the trip point for your desired ambient light level.
5. **Remove the IC** before continuing soldering (heat protection).

---

## Phase 4: Fade-In Ramp

### Step 9 — RC Fade Network

1. Connect the 470 kΩ resistor from pin 3 (DARK signal) to the **FADE node**.
2. Connect the 100 µF electrolytic capacitor from FADE node to GND.
   - **Positive lead** of the cap goes to the FADE node.
   - **Negative lead** (stripe) goes to GND.

```
Pin 3 (DARK) ──── [470kΩ] ──── FADE ──── [100µF +] ──── GND
                                  │
                                  └── To Q1 base resistor
```

When DARK goes high, the capacitor charges through 470 kΩ over ~47 seconds (τ = RC), creating a smooth voltage ramp that gradually turns on the steady LED bank.

---

## Phase 5: Twinkle Oscillators

### Step 10 — Oscillator 1 (Gate 2)

1. Connect pin 4 (2A) and pin 5 (2B) together — this is the oscillator input/feedback node.
2. From this node, wire in **series**: 1 MΩ resistor + 100 kΩ trim pot → back to pin 6 (2Y, output).
3. Connect a 0.47 µF capacitor from the input node (pins 4+5) to GND.

```
         ┌──── [1MΩ + 100k Trim] ────┐
         │                            │
Pin 4+5 ─┤                     Pin 6 (2Y) ──── TW1 signal
         │
        [0.47µF]
         │
        GND
```

4. **Enable gating**: connect the DARK signal (pin 3) through a 100 kΩ resistor to the oscillator input node. This ensures the oscillator only runs when DARK is HIGH.

> Alternative enable method: use the DARK signal to pull the oscillator input low via a diode or transistor when DARK is LOW.

### Step 11 — Oscillator 2 (Gate 3)

1. Repeat the same topology using Gate 3 (pins 9, 10 → 8).
2. Use a second 1 MΩ resistor, second 100 kΩ trim pot, and second 0.47 µF cap.
3. Enable from the DARK signal the same way.

### Step 12 — Test Oscillators

1. Re-insert the CD4093.
2. Cover the LDR to enable the circuit (DARK = HIGH).
3. Probe pin 6 (Osc 1 output) with a multimeter on AC or connect an LED+resistor temporarily — you should see a blinking signal at roughly 1–2 Hz.
4. Probe pin 8 (Osc 2 output) — confirm a similar but slightly different rate.
5. Adjust trim pots so the two rates are close but not identical (this creates the organic beat pattern).

---

## Phase 6: LED Driver Transistors

### Step 13 — Q1 (Steady Glow Driver)

1. Identify the 2N3904 pinout (flat side facing you): **E – B – C** (left to right).
2. Connect a 47 kΩ base resistor from the FADE node to Q1's **base**.
3. Connect Q1's **emitter** to GND.
4. Q1's **collector** connects to the steady LED bank (next step).

### Step 14 — Q2 (Twinkle Driver 1)

1. Connect a 47 kΩ base resistor from TW1 (pin 6) to Q2's **base**.
2. Emitter → GND.
3. Collector → twinkle LED bank 1.

### Step 15 — Q3 (Twinkle Driver 2)

1. Connect a 47 kΩ base resistor from TW2 (pin 8) to Q3's **base**.
2. Emitter → GND.
3. Collector → twinkle LED bank 2.

---

## Phase 7: LED Banks

### Step 16 — Steady LED Bank

1. For each LED in the steady bank:
   - Anode (long leg) connects through a **1.5 kΩ resistor** to VDD.
   - Cathode (short leg / flat side) connects to Q1's **collector**.
2. Wire 3–6 LEDs in this parallel arrangement.

### Step 17 — Twinkle LED Bank 1

1. Same arrangement but:
   - Use **2.2 kΩ resistors** per LED.
   - Cathodes connect to Q2's **collector**.
2. Wire 4–7 LEDs.

### Step 18 — Twinkle LED Bank 2

1. Mirror of bank 1:
   - **2.2 kΩ resistors** per LED.
   - Cathodes connect to Q3's **collector**.
2. Wire 4–7 LEDs.

---

## Phase 8: Final Assembly + Tuning

### Step 19 — Insert IC and Power On

1. Double-check all connections against the [schematic](schematic.png).
2. Insert the CD4093 into its socket (notch/dot aligned with pin 1).
3. Connect the battery pack.

### Step 20 — Daylight Test

1. Expose the LDR to room light.
2. All LEDs should be **off** (DARK signal LOW).
3. Verify pin 3 reads near 0 V.

### Step 21 — Dusk Simulation

1. Cup your hand over the LDR (or use a dark cloth).
2. The DARK signal should go HIGH.
3. Over ~30–60 seconds, the steady LEDs should gradually brighten (fade-in ramp).
4. The twinkle LEDs should start blinking in two independent patterns.

### Step 22 — Fine-Tuning

| Parameter | Adjustment | Effect |
|-----------|------------|--------|
| Dusk sensitivity | 500 kΩ pot (RV1) | Earlier or later activation |
| Fade-in speed | Swap R_fade (470 kΩ → 220 kΩ for faster, 1 MΩ for slower) | Bloom time |
| Twinkle rate 1 | Trim pot RV2 | Faster ↔ slower sparkle |
| Twinkle rate 2 | Trim pot RV3 | Faster ↔ slower sparkle |
| LED brightness | Change bank resistor values | Brighter (lower R) or dimmer (higher R) |
| LED count | Add/remove LEDs per bank | More or fewer sparkle points |

### Step 23 — Install

1. Mount solar panels near a window or under a desk lamp.
2. Place the LED array inside your "diamond mine" enclosure (shadow box, geode, glass jar, etc.).
3. Scatter or arrange the LEDs for maximum sparkle effect — randomness is your friend.
4. The system will charge during the day and auto-activate at dusk.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| LEDs always on | SENSE node stuck low / pot misadjusted | Adjust RV1; check LDR orientation |
| LEDs never turn on | SENSE node stuck high / dead battery | Check battery voltage; verify LDR works |
| No twinkle, just steady glow | Oscillator not running | Check osc wiring; probe pin 6/8 for square wave |
| LEDs very dim | Low battery / high resistor values | Charge battery; reduce LED resistors |
| Harsh snap-on (no fade) | Fade cap shorted or wrong polarity | Check C_fade polarity and value |
| IC gets hot | Floating input on Gate 4 | Tie pins 12+13 to VDD or GND |
| Circuit draws too much current | Shorted LED / wrong resistor | Check for solder bridges; measure each bank |

---

## Current Budget Estimate

| Section | Estimated Draw |
|---------|---------------|
| CD4093 quiescent | ~0.01 mA |
| Dusk detector divider | ~0.005 mA |
| Steady LED bank (5 LEDs) | ~2 mA |
| Twinkle bank 1 (5 LEDs, 50% duty) | ~0.7 mA |
| Twinkle bank 2 (5 LEDs, 50% duty) | ~0.7 mA |
| **Total** | **~3.4 mA** |

At 2000 mAh battery capacity, this gives roughly **24+ days** of nighttime-only operation (assuming 10 hrs/night) between charges — easily sustained by even modest indoor solar.
