# Bill of Materials (BOM)

> Diamond Mine Shimmer Circuit — complete parts list with values, quantities, and sourcing notes.

---

## Power + Charging Section

| Qty | Part | Value / Rating | Reference | Notes |
|-----|------|----------------|-----------|-------|
| 3 | AA NiMH rechargeable cells | 1.2 V / 2000 mAh typ. | BAT1–3 | Eneloop or similar low-self-discharge preferred |
| 1 | 3×AA battery holder | — | — | With leads or snap connector |
| 2–3 | Small indoor solar panels | 2 V / 20–40 mA each | SOL1–3 | Wire in **parallel** (same voltage, additive current); keep total \(I_{SC}\) at or below ~80 mA for 2000 mAh cells |
| 1 | 1N5819 Schottky diode | 40 V / 1 A | D1 | Prevents battery discharging back through panels at night |

### Charging Notes

- Typical indoor current is usually much lower than panel nameplate current; expect roughly 5–40 mA depending on light and panel orientation.
- The Schottky diode drops only ~0.2 V vs ~0.6 V for a standard 1N4001 — important at a 3.6 V rail.
- For long-term safe trickle charging of 2000 mAh NiMH cells, keep sustained charge current at or below ~C/25 to C/20 (about 80–100 mA max).
- If you expect strong sunlight exposure, reduce panel count or add charge-current limiting.

---

## Logic + Control Section

| Qty | Part | Value / Rating | Reference | Notes |
|-----|------|----------------|-----------|-------|
| 1 | CD4093 | Quad 2-input Schmitt-trigger NAND | U1 | CMOS, runs 3–18 V, ultra-low quiescent current |
| 1 | LDR (photoresistor) | ~10 kΩ (light) / ~1 MΩ (dark) | LDR1 | GL5528 or similar; any CdS photoresistor works |
| 1 | Potentiometer | 500 kΩ linear | RV1 | Dusk sensitivity adjustment |

### IC Pinout Reference (CD4093)

```
        ┌───U───┐
  1A  1 │       │ 14  VDD
  1B  2 │       │ 13  4A
  1Y  3 │       │ 12  4B
  2A  4 │CD4093 │ 11  4Y
  2B  5 │       │ 10  3A
  2Y  6 │       │  9  3B
 GND  7 │       │  8  3Y
        └───────┘
```

Gate assignments in this circuit:
- **Gate 1** (pins 1, 2 → 3): Dusk detector / enable switch
- **Gate 2** (pins 4, 5 → 6): Twinkle oscillator 1
- **Gate 3** (pins 9, 10 → 8): Twinkle oscillator 2
- **Gate 4** (pins 12, 13 → 11): Unused — tie inputs to VDD or GND

---

## Fade-In Ramp Section

| Qty | Part | Value | Reference | Notes |
|-----|------|-------|-----------|-------|
| 1 | Resistor | 470 kΩ ¼W | R_fade | Fade charge resistor; controls ramp speed |
| 1 | Electrolytic capacitor | 100 µF / 10 V | C_fade | Fade ramp storage; low-ESR preferred |

### Fade Timing

τ = R × C = 470 kΩ × 100 µF = **47 seconds**

The LEDs reach ~63% brightness in 47 s and ~95% in ~2.5 minutes — a gentle, organic bloom.

---

## Oscillator Section (×2 Twinkle Channels)

| Qty | Part | Value | Reference | Notes |
|-----|------|-------|-----------|-------|
| 2 | Resistor | 1 MΩ ¼W | R_osc1, R_osc2 | Oscillator timing resistors |
| 2 | Trimmer potentiometer | 100 kΩ | RV2, RV3 | Twinkle speed fine-tune |
| 2 | Film capacitor | 0.47 µF (470 nF) | C_osc1, C_osc2 | Timing caps; film preferred over ceramic for stability |

### Oscillator Frequency Estimates

Using f ≈ 1 / (1.2 × R × C) for a Schmitt-trigger oscillator:

| Trim pot setting | Total R | Frequency | Period |
|------------------|---------|-----------|--------|
| 0 Ω (bypassed) | 1.0 MΩ | ~1.8 Hz | ~0.57 s |
| 50 kΩ | 1.05 MΩ | ~1.7 Hz | ~0.59 s |
| 100 kΩ (max) | 1.1 MΩ | ~1.6 Hz | ~0.63 s |

Adjust each channel's trim pot so the two rates are **slightly different** (e.g., 1.6 Hz vs 1.8 Hz). The resulting beat frequency creates a slow, drifting shimmer pattern.

---

## LED Driver Stage

| Qty | Part | Value | Reference | Notes |
|-----|------|-------|-----------|-------|
| 2–3 | NPN transistor | 2N3904 | Q1, Q2, Q3 | Or BC547, 2N2222 — any small-signal NPN |
| 3 | Base resistor | 10 kΩ–220 kΩ | R_b1–R_b3 | Limits base current; 47 kΩ is a good starting point |
| 2 | Signal diode | 1N4148 | D_t1, D_t2 | Twinkle base clamp to guarantee OFF during daylight |

### Transistor Selection Notes

- 2N3904: V_CE(sat) ≈ 0.2 V, h_FE ≥ 100 — plenty for LED-driving duty.
- At 3.6 V rail and ~2 mA per LED, collector current stays well under the 200 mA max.
- For the steady-glow channel (Q1), the fade ramp voltage rises slowly, so Q1 acts as a variable gain amplifier during fade-in.

---

## LED Banks

| Qty | Part | Value | Reference | Notes |
|-----|------|-------|-----------|-------|
| 3–6 | Warm white LED | 3 mm or 5 mm diffused | D_s1–D_s6 | Steady bank — "base glow" |
| 4–7 | Warm white LED | 3 mm or 5 mm diffused | D_t1–D_t7 | Twinkle bank 1 |
| 4–7 | Warm white LED | 3 mm or 5 mm diffused | D_t8–D_t14 | Twinkle bank 2 |
| 3–6 | Resistor | 1.5 kΩ ¼W | R_Ls | Steady LED current limiters |
| 4–7 | Resistor | 2.2 kΩ ¼W | R_Lt1 | Twinkle 1 LED current limiters |
| 4–7 | Resistor | 2.2 kΩ ¼W | R_Lt2 | Twinkle 2 LED current limiters |

### LED Current Estimates

At V_DD = 3.6 V, V_LED ≈ 2.8 V (warm white), V_CE(sat) ≈ 0.2 V:

| Bank | Resistor | I_LED | Brightness |
|------|----------|-------|------------|
| Steady | 1.5 kΩ | ~0.4 mA | Dim warm glow |
| Twinkle | 2.2 kΩ | ~0.27 mA | Subtle sparkle |

These are intentionally low currents — the "diamond mine" aesthetic calls for delicate pinpoints of light, not blazing floodlights. For brighter results, reduce resistor values (minimum ~220 Ω for standard LEDs).

---

## Decoupling

| Qty | Part | Value | Reference | Notes |
|-----|------|-------|-----------|-------|
| 1 | Ceramic capacitor | 0.1 µF (100 nF) | C_dec | Place as close to CD4093 VDD/GND pins as possible |

---

## Summary Totals

| Category | Count |
|----------|-------|
| Resistors | ~15–20 |
| Capacitors | 5 |
| Transistors | 3 |
| LEDs | 10–20 |
| ICs | 1 |
| Diodes | 3 |
| Potentiometers | 3 |
| Solar panels | 2–3 |
| Battery cells | 3 |

**Estimated total cost:** $8–$15 USD (excluding battery holder and solar panels from common component kits)

---

## Recommended Suppliers

- **Mouser / Digi-Key** — full catalog, exact values
- **Amazon / AliExpress** — component assortment kits (resistor kits, LED bags, solar panels)
- **Tayda Electronics** — budget-friendly discrete components
- **Adafruit / SparkFun** — solar panels, battery holders, and prototyping supplies
