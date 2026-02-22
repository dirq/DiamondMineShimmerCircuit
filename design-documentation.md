# Design Documentation — Diamond Mine Shimmer Circuit

## 1. Design Philosophy

The goal is a self-sustaining "bioluminescent cave" — something that feels alive
without any digital intelligence. Every design choice serves this:

- **No microcontroller**: Analog randomness is inherently organic. Two free-running
  oscillators with irrational frequency ratios produce quasi-random patterns that
  never exactly repeat.
- **Solar + NiMH**: The circuit runs itself indefinitely with zero user intervention.
- **CMOS logic at 3.6V**: The CD4093 operates down to 3V with nanoamp-level
  quiescent current — perfect for battery life.
- **Schmitt-trigger hysteresis**: Prevents chatter at the dusk/dawn boundary and
  creates clean oscillator waveforms.
- **PNP high-side twinkle switches**: Ensures zero LED current during daytime when
  the NAND gate outputs are stuck HIGH.

---

## 2. Power System

### 2.1 Solar Charging

```
Solar Panels (5.5V, parallel) ── R_charge (10Ω) ──►|── 3×AA NiMH (3.6V)
                                                   1N5819
```

**Why 5.5V panels?** The battery pack reaches 4.35V when fully charged. Adding
the Schottky drop (0.3V), the solar source must exceed 4.65V. Panels rated at
5.5V provide adequate headroom across all conditions.

**Why parallel wiring?** Parallel panels produce the same voltage at combined
current. Series wiring would give 11V — far too high for direct NiMH charging
without a regulator.

**Why R_charge (10 ohm)?** Without current limiting, a fully discharged battery
could draw the panel's full short-circuit current. The resistor self-tapers
the charge rate:

| Battery State | Voltage | Charge Current | Rate |
|--------------|---------|---------------|------|
| Deeply discharged | 3.0V | 220 mA | C/9 |
| Nominal | 3.6V | 160 mA | C/12.5 |
| Near full | 4.0V | 120 mA | C/17 |
| Fully charged | 4.35V | 85 mA | C/24 |

NiMH cells safely tolerate indefinite trickle at C/10 or below. The resistor
keeps the circuit in the safe zone for all practical conditions.

**Why Schottky?** At night, solar panels become low-impedance paths to ground.
Without D1, the battery discharges backward through the panels. A standard
silicon diode (1N4001) drops ~0.6V — at 3.6V that is a 17% loss. The 1N5819
Schottky drops only ~0.3V.

**Why NiMH?** NiMH cells tolerate continuous trickle charging without a charge
controller (unlike Li-ion). At the C/24 rates typical of this design at full
charge, they charge safely and indefinitely. Eneloop cells provide 2100-cycle
life and <15% self-discharge over 6 months.

### 2.2 Battery Sizing

Three NiMH cells give 3.6V nominal (3.0V discharged, 4.35V freshly charged).
This keeps the CD4093 comfortably in its 3–18V operating range and provides
enough headroom above red/amber LED forward voltage (~1.8–2.1V).

---

## 3. Dusk Detector

```
VDD ──── [LDR] ──── SENSE ──┬── [470k] ──┬── [100k trimpot] ── GND
                             │            └── [47k] ── GND
                        CD4093 Gate 1
                        (pins 1+2 tied)
```

### 3.1 Voltage Divider Behavior

| Condition | LDR Resistance | SENSE Voltage | Gate 1 Output |
|-----------|---------------|---------------|---------------|
| Bright light | ~5–10 kΩ | High (~VDD) | LOW (disabled) |
| Dim indoor | ~100–500 kΩ | Mid | Depends on trimpot |
| Darkness | ~500 kΩ–2 MΩ | Low (~GND) | HIGH (enabled) |

### 3.2 Pull-Down Network

The three-element pull-down (470k fixed + 100k trimpot || 47k) provides:

With trimpot at 0Ω: pull-down = 470k + (0 || 47k) = 470k
With trimpot at 100k: pull-down = 470k + (100k || 47k) = 470k + 32k = 502k

The trimpot provides fine adjustment (~7% range) rather than coarse control.
This is appropriate for a set-once installation.

### 3.3 Schmitt-Trigger Advantage

The CD4093 has built-in hysteresis (~30% of VDD). At 3.6V:
- Upper threshold (VT+): ~2.4V
- Lower threshold (VT-): ~1.2V
- Hysteresis band: ~1.2V

This prevents rapid on/off cycling during gradual dusk transitions. The SENSE
voltage must cross VT- (falling) to turn LEDs on, and VT+ (rising) to turn
them off. The ~1.2V gap means the LDR must change by hundreds of kilohms
between the two states — ensuring clean, single transitions.

---

## 4. Fade-In Ramp

```
DARK (HIGH) ──── [470kΩ] ──── FADE ──┬──── [100µF] ──── GND
                                      │
                                      └── [10k] → Q1 base
```

### 4.1 RC Time Constant

```
τ = R × C = 470,000 Ω × 0.0001 F = 47 seconds
```

### 4.2 Voltage Profile

```
V_FADE(t) = V_DARK × (1 - e^(-t/τ))
```

| Time | V_FADE | % of V_DARK | Perceived Effect |
|------|--------|-------------|------------------|
| 0 s | 0.00V | 0% | LEDs off |
| 10 s | 0.72V | 19% | First hint of glow (Vbe threshold) |
| 20 s | 1.21V | 34% | Visible dim glow |
| 47 s | 2.27V | 63% | Moderate brightness (1τ) |
| 94 s | 3.10V | 86% | Near full (2τ) |
| 141 s | 3.42V | 95% | Essentially full (3τ) |

Q1 operates in its active (linear) region during the ramp, so LED current
rises proportionally with V_FADE. The visual effect is a smooth, organic bloom.

### 4.3 Dawn Fade-Out

When DARK goes LOW at dawn:
1. The 100uF cap discharges through 10k into Q1 base (τ = 1s) while Q1 conducts
2. LEDs fade out in ~2–3 seconds
3. Below Vbe (~0.7V), Q1 turns off and remaining charge bleeds through 470k

The fade-out is fast but not jarring — an appropriate "lights going to sleep"
transition.

### 4.4 Modification Options

| Desired Fade Time | R_fade | τ (seconds) | 95% Time |
|-------------------|--------|-------------|----------|
| Quick (10 s) | 100 kΩ | 10 s | ~30 s |
| Medium (47 s) | 470 kΩ | 47 s | ~2.5 min |
| Slow (100 s) | 1 MΩ | 100 s | ~5 min |
| Very slow (220 s) | 2.2 MΩ | 220 s | ~11 min |

---

## 5. Schmitt-Trigger Oscillators

Each oscillator is a classic CD4093 relaxation oscillator with gating:

```
    DARK ──── Pin 5 (Gate 2 InA)         ← gating input

         ┌──── [R_osc (1MΩ + Trim)] ────┐
         │                                │
    Pin 6 (InB) ──────────────── Pin 4 (Out)
         │
      [C_osc 0.47µF]
         │
        GND
```

### 5.1 How It Works

1. When DARK = HIGH, the gate acts as an inverter on Pin 6.
2. Capacitor charges through R_osc toward VDD.
3. When voltage crosses the **upper Schmitt threshold** (~2.4V), the output snaps LOW.
4. Capacitor discharges through R_osc toward GND.
5. When voltage crosses the **lower Schmitt threshold** (~1.2V), the output snaps HIGH.
6. Cycle repeats.

When DARK = LOW, the NAND output is stuck HIGH regardless of Pin 6. No
oscillation occurs.

### 5.2 Frequency Formula

```
f ≈ 1 / (1.2 × R × C)
```

For R = 1.05MΩ (1M + 50k trim) and C = 0.47µF:
```
f ≈ 1 / (1.2 × 1,050,000 × 0.00000047)
f ≈ 1 / 0.592
f ≈ 1.69 Hz  (theoretical)
```

Actual frequency is typically 2.4–2.6 Hz due to Schmitt threshold ratios differing
from the 1.2x approximation at low VDD. The trimpot allows fine adjustment.

### 5.3 Frequency Range

| Trimpot Setting | Total R | Frequency | Character |
|-----------------|---------|-----------|-----------|
| 0 ohm (min) | 1.0M | ~2.6 Hz | Quick shimmer |
| 50k (mid) | 1.05M | ~2.5 Hz | Medium shimmer |
| 100k (max) | 1.1M | ~2.4 Hz | Slightly slower |

### 5.4 The Shimmer Effect

The magic happens because the two oscillators run at **slightly different
frequencies**. If Osc 1 runs at 2.6 Hz and Osc 2 at 2.4 Hz, the beat frequency is:

```
f_beat = |f1 - f2| = |2.6 - 2.4| = 0.2 Hz → 5-second drift cycle
```

The steady-glow bank provides a constant "floor" while the two twinkle banks
create overlapping shimmer. Together, the three layers produce a complex,
organic light field:

```
Brightness
    ▲
    │   ╱╲   ╱╲   ╱╲   ╱╲       ← Twinkle Bank 1 (~2.6 Hz)
    │  ╱  ╲ ╱  ╲ ╱  ╲ ╱  ╲
    │──────────────────────────  ← Steady Glow (base)
    │    ╱╲  ╱╲  ╱╲  ╱╲
    │   ╱  ╲╱  ╲╱  ╲╱  ╲       ← Twinkle Bank 2 (~2.4 Hz)
    │
    └──────────────────────────► Time
           ↕ 5s beat cycle ↕
```

---

## 6. LED Driver Design

### 6.1 Q1: Steady Bank (NPN 2N3904, Low-Side)

```
VDD ──── [1.5k] ──── LED ──── Q1 Collector
                               Q1 Emitter ── GND
FADE ──── [10k] ──── Q1 Base
```

During fade-in, Q1 operates in its **active region** — collector current rises
proportionally with base voltage. Once V_FADE reaches full VDD, Q1 saturates and
LED current is limited by the 1.5k resistor:

```
I_LED = (VDD - V_LED - Vce_sat) / R = (3.6 - 2.0 - 0.2) / 1500 = 0.93 mA
```

### 6.2 Q2/Q3: Twinkle Banks (PNP 2N3906, High-Side)

```
                   VDD
                    │
                Q2 Emitter (PNP)
                    │
OSC1 ── [100k] ── Q2 Base
                    │
                Q2 Collector
                    │
                   LED
                    │
                  [2.2k]
                    │
                   GND
```

**Why PNP high-side?** The oscillator NAND gates output HIGH when DARK = LOW
(daytime). With NPN low-side switches, this HIGH would turn the transistors ON —
keeping twinkle LEDs lit during the day. PNP transistors turn OFF when their
base is at VDD (HIGH), solving this naturally:

| Oscillator Output | PNP Base | PNP State | LEDs |
|-------------------|----------|-----------|------|
| HIGH (day, stuck) | ≈ VDD | OFF (Veb ≈ 0) | Dark |
| HIGH (night, osc) | ≈ VDD | OFF | Dark |
| LOW (night, osc) | ≈ 0V | ON (Veb ≈ VDD) | Lit |

Base drive through 100k ensures reliable saturation for 3 LEDs per bank:
```
Ib = (VDD - Vbe) / 100k = (3.6 - 0.7) / 100k = 29 uA
Ic_max = hFE × Ib = 100 × 29 uA = 2.9 mA (> 1.92 mA needed)
```

LED current when ON:
```
I_LED = (VDD - Vce_sat - V_LED) / R = (3.6 - 0.2 - 2.0) / 2200 = 0.64 mA
```

### 6.3 Why Individual LED Resistors?

Each LED has manufacturing variations in forward voltage (±0.2V typical). With
a shared resistor, the lowest-Vf LED hogs current while others go dim. Individual
resistors ensure equal current sharing — critical for visual uniformity in the
"diamond field."

---

## 7. Component Selection Rationale

### CD4093 (not CD4011)

The Schmitt-trigger inputs provide:
1. **Clean oscillation** — defined thresholds prevent erratic behavior
2. **Noise immunity** — ~1.2V hysteresis rejects power supply ripple
3. **Reliable dusk switching** — clean snap despite slowly-changing LDR voltage

### 2N3906 PNP (not 2N3904 NPN) for Twinkle Banks

NAND gate with one LOW input gives HIGH output. For zero daytime current:
- NPN + HIGH output = ON (wrong)
- PNP + HIGH output = OFF (correct)

### Film Capacitors (not ceramic) for Oscillators

Film capacitors have:
- Tight tolerance (±5% vs ±20% for ceramic)
- Zero piezoelectric effect
- Excellent long-term stability
- Negligible leakage

For timing, this means twinkle rate stays consistent over temperature and years.

### Red/Amber LEDs (not white/blue)

At 3.6V supply with 2.2k resistors:
- Red/amber (Vf ~2.0V): I = (3.6-0.2-2.0)/2200 = 0.64 mA (bright enough)
- White/blue (Vf ~3.0V): I = (3.6-0.2-3.0)/2200 = 0.18 mA (very dim)

Red and amber also evoke the warm "crystal mine" aesthetic.

---

## 8. Power Budget

### 8.1 Standby (Daytime)

| Component | Current |
|-----------|---------|
| CD4093 quiescent (static) | ~0.005 µA |
| LDR divider (bright: ~5k + ~500k) | ~7 µA |
| Q1 OFF (FADE = 0V) | 0 |
| Q2/Q3 OFF (PNP, base HIGH) | 0 |
| **Total standby** | **~7 µA** |

### 8.2 Active (Nighttime)

| Component | Current |
|-----------|---------|
| CD4093 + oscillators (dynamic) | ~0.1 mA |
| LDR divider (dark) | ~2.4 µA |
| Steady bank: 3 × 0.93 mA | 2.79 mA |
| Twinkle 1: 3 × 0.64 mA × 50% | 0.96 mA |
| Twinkle 2: 3 × 0.64 mA × 50% | 0.96 mA |
| Q1 base drive | 0.29 mA |
| Q2/Q3 base drive | 0.06 mA |
| **Total active (average)** | **~5.1 mA** |
| **Total active (peak)** | **~7.0 mA** |

### 8.3 Battery Life

```
Without solar:
  Continuous: 2000 / 5.1 = 392 hours ≈ 16.3 days
  10 hrs/night: 39 nights

With solar (2 panels, 4 hrs sun):
  Daily charge: 200 mA × 4 hrs = 800 mAh
  Daily discharge: 5.1 mA × 10 hrs = 51 mAh
  Net surplus: +749 mAh/day → battery stays full indefinitely
```

---

## 9. Tuning Guide

### 9.1 Dusk Sensitivity (RV1)

Turn the 100k dusk trimpot:
- **Clockwise** (more resistance): triggers at slightly less darkness
- **Counter-clockwise** (less resistance): requires deeper darkness

Test by slowly covering the LDR and observing when the DARK signal goes HIGH
(measure Pin 3 with a multimeter).

### 9.2 Twinkle Rates (RV2, RV3)

Set each oscillator's trimpot to a different position:
- Both at similar settings: synchronized flashing (less interesting)
- Slightly different: slow beat pattern (optimal shimmer)
- Very different: fast, complex pattern

**Recommended starting point:** RV2 at 30%, RV3 at 70%. This gives a beat
period of about 5 seconds — a gentle, natural-feeling drift.

### 9.3 Fade Speed

The fade-in time is set by R_fade (470k) and C_fade (100uF). To change:
- Faster: replace R_fade with 220k (τ ≈ 22s)
- Slower: replace R_fade with 1M (τ ≈ 100s)

### 9.4 LED Brightness

| Change | Method | Effect |
|--------|--------|--------|
| Brighter steady | Reduce 1.5k to 680Ω | ~2.1 mA per LED |
| Dimmer steady | Increase 1.5k to 3.3k | ~0.42 mA per LED |
| Brighter twinkle | Reduce 2.2k to 1k | ~1.4 mA per LED |
| Dimmer twinkle | Increase 2.2k to 4.7k | ~0.30 mA per LED |
| More LEDs | Add LEDs to any bank | Scale resistor count to match |
| Mixed colors | Use different Vf LEDs | Adjust resistors per-LED for equal brightness |

---

## 10. Advanced Modifications

### 10.1 Third Oscillator (Gate 4)

Gate 4 is currently unused. Wire it as a third oscillator for an additional
shimmer layer:

- **Slow breathing (0.2 Hz):** 1M + 2.2µF → drives another PNP + LED cluster
- **Fast glitter (8–10 Hz):** 220k + 0.47µF → subtle high-speed sparkle overlay

### 10.2 PWM Dimming via Gate Mixing

Use Gate 4 as an AND/OR combiner of the two oscillator outputs. The resulting
complex waveform drives a single LED bank through a PNP transistor, creating
pulse patterns impossible with a single oscillator.

### 10.3 Solar Panel Voltage Indicator

Add a single LED + 100kΩ from the solar panel positive (before R_charge) to
GND. It glows faintly during daylight to confirm panels are producing power.
Current: (5.5 - 2.0) / 100k = 35µA — negligible impact on charging.

### 10.4 Under-Voltage Lockout

For extra NiMH protection, add a TL431 or MAX809 voltage supervisor ($0.50)
that disables the circuit below 3.0V. This prevents deep discharge damage
during extended cloudy periods.

---

## 11. References

- CD4093 datasheet: [Texas Instruments CD4093B](https://www.ti.com/product/CD4093B)
- 2N3904 datasheet: [ON Semiconductor 2N3904](https://www.onsemi.com/pdf/datasheet/2n3904-d.pdf)
- 2N3906 datasheet: [ON Semiconductor 2N3906](https://www.onsemi.com/pdf/datasheet/2n3906-d.pdf)
- 1N5819 datasheet: [Vishay 1N5819](https://www.vishay.com/docs/88526/1n5819.pdf)
- NiMH charging guide: [Battery University — NiMH](https://batteryuniversity.com/article/bu-407-charging-nickel-metal-hydride)
