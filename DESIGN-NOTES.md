# Design Notes

> Circuit theory, timing math, and tuning guidance for the Diamond Mine Shimmer Circuit.

---

## Design Philosophy

The goal is a self-sustaining "bioluminescent cave" — something that feels alive without any digital intelligence. Every design choice serves this:

- **No microcontroller**: Analog randomness is inherently organic. Two free-running oscillators with irrational frequency ratios produce quasi-random patterns that never exactly repeat.
- **Solar + NiMH**: The circuit runs itself indefinitely with zero user intervention.
- **CMOS logic at 3.6 V**: The CD4093 operates down to 3 V with nanoamp-level quiescent current — perfect for battery life.
- **Schmitt-trigger hysteresis**: Prevents chatter at the dusk/dawn boundary and creates clean oscillator waveforms.

---

## Circuit Theory

### 1. Power System

```
Solar Panels (parallel) ──►|── 3×AA NiMH (3.6 V nominal)
                          1N5819
```

**Why Schottky?** At night, the solar panels become a low-impedance path to ground. Without D1, the battery would discharge backward through the panels. A standard silicon diode (1N4001) drops ~0.6 V — at 3.6 V that is a 17% loss. The 1N5819 Schottky drops only ~0.2 V, leaving more voltage for the circuit.

**Why NiMH?** NiMH cells are tolerant of continuous trickle charging (unlike Li-ion, which requires a charge controller). At C/20 rates typical of small indoor panels, they charge safely and indefinitely.

**Why 3 cells?** Three NiMH cells give 3.6 V nominal (3.0 V discharged → 4.2 V freshly charged). This keeps the CD4093 comfortably in its 3–15 V operating range and provides enough headroom above the LED forward voltage (~2.8 V for warm white).

---

### 2. Dusk Detector

```
VDD ──── [LDR] ──── SENSE ──── [500k Pot] ──── GND
                       │
                    CD4093 Gate 1
                    (pins 1+2 tied)
```

**Voltage divider behavior:**

| Condition | LDR Resistance | SENSE Voltage | Gate 1 Output |
|-----------|---------------|---------------|---------------|
| Bright light | ~10 kΩ | High (~VDD) | LOW (disabled) |
| Darkness | ~1 MΩ+ | Low (~GND) | HIGH (enabled) |

The 500 kΩ potentiometer sets the trip point. Turn clockwise → more sensitive (triggers at higher ambient light). Turn counterclockwise → less sensitive (requires deeper darkness).

**Schmitt-trigger advantage:** The CD4093 has built-in hysteresis (~30% of VDD). At 3.6 V:
- Upper threshold: ~2.4 V
- Lower threshold: ~1.2 V
- Hysteresis band: ~1.2 V

This prevents rapid on/off cycling during gradual dusk transitions.

---

### 3. Fade-In Ramp

```
DARK (HIGH) ──── [470kΩ] ──── FADE ──┬──── [100µF] ──── GND
                                      │
                                      └── Q1 base resistor
```

**RC time constant:**

```
τ = R × C = 470,000 Ω × 0.0001 F = 47 seconds
```

**Voltage at time t:**

```
V_FADE(t) = V_DARK × (1 - e^(-t/τ))
```

| Time | V_FADE | % of V_DARK | Perceived Effect |
|------|--------|-------------|------------------|
| 0 s | 0.00 V | 0% | LEDs off |
| 10 s | 0.72 V | 19% | First hint of glow |
| 20 s | 1.21 V | 34% | Visible dim glow |
| 47 s | 2.27 V | 63% | Moderate brightness |
| 94 s | 3.10 V | 86% | Near full |
| 141 s | 3.42 V | 95% | Essentially full |

The Q1 transistor operates in its active (linear) region during the ramp, so LED current rises proportionally with V_FADE. The visual effect is a smooth, organic bloom.

**Modification options:**

| Desired Fade Time | R_fade | τ (seconds) | 95% Time |
|-------------------|--------|-------------|----------|
| Quick (10 s) | 100 kΩ | 10 s | ~30 s |
| Medium (47 s) | 470 kΩ | 47 s | ~2.5 min |
| Slow (100 s) | 1 MΩ | 100 s | ~5 min |
| Very slow (220 s) | 2.2 MΩ | 220 s | ~11 min |

---

### 4. Schmitt-Trigger Oscillators

Each oscillator is a classic CD4093 relaxation oscillator:

```
         ┌──── [R_osc (1MΩ + Trim)] ────┐
         │                                │
Input ───┤                         Output (Y)
         │
      [C_osc 0.47µF]
         │
        GND
```

**How it works:**

1. Capacitor charges through R_osc toward VDD.
2. When voltage crosses the **upper Schmitt threshold** (~2.4 V), the gate output snaps LOW.
3. Capacitor now discharges through R_osc toward GND.
4. When voltage crosses the **lower Schmitt threshold** (~1.2 V), the gate output snaps HIGH.
5. Cycle repeats.

**Frequency formula:**

```
f ≈ 1 / (1.2 × R × C)
```

For R = 1 MΩ and C = 0.47 µF:

```
f ≈ 1 / (1.2 × 1,000,000 × 0.00000047)
f ≈ 1 / 0.564
f ≈ 1.77 Hz
```

**Output waveform:** Asymmetric square wave (~50% duty cycle). The LED bank blinks on and off at this rate.

---

### 5. Creating the "Shimmer" Effect

The magic happens because the two oscillators run at **slightly different frequencies**. If Osc 1 runs at 1.77 Hz and Osc 2 at 1.60 Hz, the difference is 0.17 Hz — meaning the two patterns drift in and out of sync over a ~6-second cycle.

**Beat frequency:**

```
f_beat = |f1 - f2|
```

| Osc 1 | Osc 2 | Beat Period | Visual Effect |
|-------|-------|-------------|---------------|
| 1.77 Hz | 1.60 Hz | ~5.9 s | Moderate drift |
| 1.77 Hz | 1.70 Hz | ~14.3 s | Slow, subtle drift |
| 1.77 Hz | 1.50 Hz | ~3.7 s | Faster, more dynamic |

The steady-glow bank (driven by the fade ramp) provides a constant "floor" while the two twinkle banks create overlapping shimmer. Together, the three layers produce a complex, organic light field:

```
Brightness
    ▲
    │   ╱╲   ╱╲   ╱╲   ╱╲       ← Twinkle Bank 1
    │  ╱  ╲ ╱  ╲ ╱  ╲ ╱  ╲
    │──────────────────────────  ← Steady Glow (base)
    │    ╱╲  ╱╲  ╱╲  ╱╲
    │   ╱  ╲╱  ╲╱  ╲╱  ╲       ← Twinkle Bank 2
    │
    └──────────────────────────► Time
```

---

### 6. LED Driver Analysis

Each transistor stage is a common-emitter switch/amplifier:

```
VDD ──── [R_LED] ──── LED ──── Collector
                                  │
                               2N3904
                                  │
                               Emitter ──── GND

Signal ──── [R_base] ──── Base
```

**Q1 (Steady driver) — linear mode during fade:**

During the fade-in ramp, V_FADE rises from 0 → VDD over ~47 s. Q1 operates in its active region, so collector current (and LED brightness) increases smoothly:

```
I_C ≈ (V_FADE - V_BE) / R_base × h_FE    (active region)
```

Once V_FADE reaches full VDD, Q1 saturates and the LED current is limited by R_LED:

```
I_LED = (VDD - V_LED - V_CE(sat)) / R_LED
      = (3.6 - 2.8 - 0.2) / 1500
      ≈ 0.4 mA per LED
```

**Q2 / Q3 (Twinkle drivers) — switching mode:**

The oscillator outputs are square waves, so Q2 and Q3 switch fully on and off. Current per LED while ON:

```
I_LED = (VDD - V_LED - V_CE(sat)) / R_LED
      = (3.6 - 2.8 - 0.2) / 2200
      ≈ 0.27 mA per LED
```

---

## Component Selection Rationale

### Why CD4093 and not CD4011 (non-Schmitt NAND)?

The Schmitt-trigger inputs provide:
1. **Clean oscillation** — defined thresholds prevent erratic behavior near transitions
2. **Noise immunity** — the ~1.2 V hysteresis band rejects power supply ripple and coupled noise
3. **Reliable dusk switching** — the LDR voltage changes slowly; Schmitt inputs give a clean snap

### Why NPN common-emitter and not direct IC drive?

The CD4093 output can source/sink only ~1 mA at 3.6 V. With multiple LEDs per bank, a transistor buffer is essential. The 2N3904 easily handles 50+ mA, far beyond what we need.

### Why individual LED resistors and not shared?

Each LED has manufacturing variations in forward voltage. Individual resistors ensure equal current sharing. Shared resistors would cause the lowest-V_F LED to hog current while others stay dim.

### Why 0.47 µF film caps for oscillators?

Film capacitors have:
- Tight tolerance (±5% typical vs ±20% for ceramic)
- Zero piezoelectric effect (ceramic caps change value with vibration)
- Excellent long-term stability
- Negligible leakage

For timing applications, this means your twinkle rate stays consistent over temperature and time.

---

## Advanced Modifications

### Mixed LED Colors

Replace some warm white LEDs with:
- **Amber** (V_F ≈ 2.0 V) — adjust resistors to compensate for lower forward voltage
- **Cool white** (V_F ≈ 3.0 V) — may need lower resistors for similar brightness
- **UV** (V_F ≈ 3.2 V) — near the voltage limit; works but dimmer

### Third Oscillator (using Gate 4)

Gate 4 is unused in the basic design. You can add a third oscillator for even more complexity:
- Use a much slower rate (0.2–0.5 Hz) for a "breathing" layer
- Or a much faster rate (5–10 Hz) for a subtle "glitter" overlay

### PWM Dimming via Oscillator Mixing

Instead of driving LED banks directly, use the two oscillator outputs as inputs to an AND or OR gate (using the spare Gate 4) to create a combined pattern that drives a single LED bank through a transistor. This creates pulse patterns impossible with a single oscillator.

### Solar Panel Voltage Indicator

Add a single LED + high-value resistor (100 kΩ) from the solar panel output (before the diode) to GND. It will glow faintly during daylight to confirm the panels are producing power.

---

## Power Budget Deep Dive

### Standby (Daytime — LDR in light)

| Component | Current |
|-----------|---------|
| CD4093 quiescent | ~5 µA |
| LDR divider | ~5 µA |
| **Total standby** | **~10 µA** |

At 10 µA, the battery would last **200,000 hours** (~23 years) on standby alone. Daytime power consumption is negligible.

### Active (Nighttime — LEDs on)

| Component | Current |
|-----------|---------|
| CD4093 + oscillators | ~50 µA |
| Steady bank (5 LEDs × 0.4 mA) | ~2 mA |
| Twinkle bank 1 (5 LEDs × 0.27 mA × 50%) | ~0.68 mA |
| Twinkle bank 2 (5 LEDs × 0.27 mA × 50%) | ~0.68 mA |
| Base drive (3 × ~10 µA) | ~30 µA |
| **Total active** | **~3.4 mA** |

### Battery Life Without Solar

At 2000 mAh and 3.4 mA active draw:
- Continuous: ~588 hours (~24.5 days)
- 10 hrs/night: ~59 nights

### Solar Recharge Rate

Two 50 mA panels in parallel under indoor light (window sill, ~4 hrs effective sun):
- Daily charge: ~100 mA × 4 hrs = 400 mAh
- Daily discharge: 3.4 mA × 10 hrs = 34 mAh
- **Net daily surplus: +366 mAh** — the battery stays full indefinitely.

---

## References

- CD4093 datasheet: [Texas Instruments CD4093B](https://www.ti.com/product/CD4093B)
- 2N3904 datasheet: [ON Semiconductor 2N3904](https://www.onsemi.com/pdf/datasheet/2n3904-d.pdf)
- 1N5819 datasheet: [Vishay 1N5819](https://www.vishay.com/docs/88526/1n5819.pdf)
- NiMH charging guide: [Battery University — NiMH](https://batteryuniversity.com/article/bu-407-charging-nickel-metal-hydride)
