# Deep-Dive Circuit Evaluation — Diamond Mine Shimmer

## Scope

This evaluation examines the **corrected** design for solar self-sufficiency, energy
storage integrity, day/night transition behavior, and multi-year longevity as a
permanent art installation. It builds on the original circuit-evaluation.md (which
identified four critical bugs in the first draft) and finds **two new critical flaws**
in the corrected design plus several longevity concerns.

---

## Executive Summary

| Category | Verdict |
|----------|---------|
| Analog shimmer concept | Excellent — dual beat-frequency oscillators are elegant and organic |
| Dusk detection + fade-in | Solid — Schmitt hysteresis and 47-second RC ramp work well |
| LED current design | Good — per-LED resistors, red/amber Vf match, low current |
| Solar charging | **CRITICAL FLAW** — 2V panels cannot charge a 3.6V NiMH pack |
| Daytime LED gating | **CRITICAL FLAW** — NAND gate stuck-HIGH turns twinkle LEDs ON during the day |
| NiMH longevity | Needs attention — no over-discharge cutoff, no charge regulation |
| Component lifetime | Good for 5–10 years with battery replacement every 2–3 years |

---

## Critical Flaw 1: Solar Panels Cannot Charge the Battery

### The Problem

The BOM specifies **"~2V, 50–100 mA" solar panels wired in parallel**.

Parallel wiring preserves voltage and sums current. So 2–4 panels in parallel
produce **2V** at 100–400 mA.

The battery pack is **3x AA NiMH in series = 3.6V nominal** (range: 3.0V discharged
to 4.35V fully charged).

**A 2V source cannot push current into a 3.6V battery.** This is a fundamental
voltage mismatch. The Schottky diode is reverse-biased at all times — zero charging
current flows, ever.

```
Required:  V_solar > V_battery + V_diode
           V_solar > 4.35V + 0.3V = 4.65V  (worst case, fully charged)
           V_solar > 3.0V + 0.3V  = 3.3V   (best case, fully discharged)

Actual:    V_solar = 2.0V  (open circuit, parallel panels)

Result:    2.0V < 3.3V → NO CHARGING UNDER ANY CONDITION
```

### Why the Original Design Notes Seemed Plausible

The DESIGN-NOTES.md calculates "daily charge: ~100 mA x 4 hrs = 400 mAh" — but this
assumes the current actually flows. With a 2V source and 3.6V battery, the diode is
reverse-biased and **zero milliamps** flow regardless of panel current rating.

### The Fix

**Option A (recommended): Use higher-voltage panels**

Replace the 2V panels with **5V–6V solar panels** (common in NiMH garden-light
applications). Wire them in parallel for current:

```
2–3 panels rated 5.5V / 80–100 mA each, in parallel
→ 5.5V at 160–300 mA combined
→ After Schottky: 5.2V
→ Charges 3.6V NiMH pack comfortably
```

Add a **current-limiting resistor** (R_charge) in series to keep trickle rate safe:

```
R_charge = (V_panel - V_battery_max - V_diode) / I_target
         = (5.5 - 4.35 - 0.3) / 0.1
         = 8.5 ohm → use 10 ohm, 1/2W

At minimum battery voltage (3.0V):
  I = (5.5 - 3.0 - 0.3) / 10 = 220 mA  (C/9 — acceptable for NiMH)

At maximum battery voltage (4.35V):
  I = (5.5 - 4.35 - 0.3) / 10 = 85 mA   (C/24 — safe indefinite trickle)
```

**Option B: Wire three 2V panels in series**

```
3 panels in series: 6.0V at 50–100 mA per panel
After Schottky: 5.7V
```

This works but reduces available current to the weakest panel (series = current-limited
by the dimmest panel). Also 5.7V is high enough to need the current-limiting resistor.

**Option C: Use two pairs in series-parallel**

```
4 panels total:
  Panel 1 + Panel 2 in series = 4.0V
  Panel 3 + Panel 4 in series = 4.0V
  Two series strings in parallel = 4.0V at 2x current

After Schottky: 3.7V
```

This barely works when the battery is below 3.4V but fails to charge above that. Not
recommended — too little headroom.

### Updated BOM Entry

```
| 2–3 | Solar panels (5.5V) | 5–6V, 80–100 mA | Wired in parallel. Indoor-rated. |
| 1   | R_charge             | 10 ohm, 1/2W     | Series current limiter (solar → diode) |
```

---

## Critical Flaw 2: NAND Gating Bug — Twinkle LEDs ON During Daytime

### The Problem

The corrected design gates the oscillators by feeding DARK to one input of each
NAND gate. The intent was to disable oscillation (and LED current) during daylight.

**NAND gate truth table:**

| DARK (Pin 5/8) | RC Node (Pin 6/9) | Output (Pin 4/10) |
|:-:|:-:|:-:|
| 0 (day) | 0 | **1** |
| 0 (day) | 1 | **1** |
| 1 (night) | 0 | 1 |
| 1 (night) | 1 | 0 |

When DARK = LOW (daytime), the output is **stuck HIGH** regardless of the RC node.

The output (Pin 4 / Pin 10) connects through 220k to the base of Q2 / Q3 (NPN):

```
Ib = (V_out - Vbe) / 220k = (3.6 - 0.7) / 220,000 = 13.2 uA
```

With hFE ~100 (typical for 2N3904 at low Ic):

```
Ic = hFE x Ib = 100 x 13.2 uA = 1.32 mA
```

Three LEDs per bank at 0.64 mA each = 1.92 mA needed. Q2/Q3 can supply ~1.3 mA —
enough to visibly illuminate the LEDs (dimmer than night mode, but clearly ON).

**Daytime current through twinkle LEDs:**

```
Twinkle Bank 1:  ~1.3 mA (constant, not oscillating)
Twinkle Bank 2:  ~1.3 mA (constant, not oscillating)
Base drive:       2 x 13 uA = 0.03 mA
─────────────────────────────────────
Total wasted:    ~2.6 mA during the day
```

This is **worse** than the original ungated oscillators (Issue 4), which at least had
50% duty cycle (~1.9 mA average). The "fix" made the problem larger.

The circuit-evaluation.md states "Zero LED current" during daytime — this is
**incorrect** for NPN common-emitter drivers fed by NAND-gate-stuck-HIGH.

### The Fix

**Option A (simplest, no extra parts): Switch Q2 and Q3 to PNP high-side drivers**

Replace the 2N3904 NPN transistors for Q2 and Q3 with **2N3906 PNP** transistors
wired as high-side switches:

```
                       VDD
                        │
                    Q2 Emitter (PNP 2N3906)
                        │
                    Q2 Collector
                        │
                       LED (anode)
                        │
                       LED (cathode)
                        │
                      2.2k
                        │
                       GND

Pin 4 (OSC1) ── 220k ── Q2 Base
```

PNP behavior:
- Base HIGH (≈ VDD) → Vbe ≈ 0 → PNP OFF → LEDs OFF
- Base LOW (≈ 0V) → Vbe ≈ -VDD → PNP ON → LEDs ON

Day: Output stuck HIGH → Q2 base ≈ VDD → PNP OFF → **LEDs OFF** (correct!)
Night: Output oscillates HIGH/LOW → LEDs blink ON/OFF (correct!)

LED current is identical:

```
I = (VDD - Vce_sat - Vf_LED) / R = (3.6 - 0.2 - 2.0) / 2200 = 0.64 mA
```

**BOM change:** Replace 2x 2N3904 (Q2, Q3) with 2x 2N3906. Same price, same package.
Q1 (steady bank) stays as 2N3904 NPN since it's controlled by the FADE ramp (0V
during day = already OFF).

**Option B: Add a common ground-path enable transistor (Q4)**

Keep Q2/Q3 as NPN but add a fourth transistor (Q4, 2N3904) in the shared emitter
return path:

```
Q2 Emitter ──┬── Q4 Collector
Q3 Emitter ──┘
                  Q4 Base ← 47k ← DARK (Pin 3)
                  Q4 Emitter → GND
```

Day:  DARK = LOW → Q4 OFF → Q2/Q3 emitters floating → no LED current
Night: DARK = HIGH → Q4 ON → Q2/Q3 emitters at ~0.2V → normal operation

Penalty: Extra Vce_sat (~0.2V) in series → LED current drops to:

```
I = (3.6 - 2.0 - 0.2 - 0.2) / 2200 = 0.55 mA  (14% dimmer)
```

**BOM change:** +1x 2N3904, +1x 47k resistor.

**Option C: Use Gate 4 to invert one oscillator output**

Rewire Gate 4 as an inverter on the Osc 1 output:

```
Pin 12 = Pin 4 (Osc 1 output)
Pin 13 = Pin 4 (tied together = inverter mode)
Pin 11 = inverted Osc 1 output → 220k → Q2 base
```

Day: Pin 4 stuck HIGH → Pin 11 LOW → Q2 OFF (correct!)
Night: Pin 4 oscillates → Pin 11 oscillates (inverted) → Q2 blinks (correct!)

Problem: Only fixes ONE oscillator. Gate 3 (Osc 2, Pin 10 → Q3) still has the
stuck-HIGH bug. No spare gate for a second inversion.

**Recommendation: Option A (PNP) is cleanest.** No extra parts, no voltage penalty,
fixes both banks.

---

## Power Budget — Recalculated

### Daytime (Standby) — With Both Fixes Applied

| Component | Current |
|-----------|---------|
| CD4093 quiescent (static, no oscillation) | ~0.005 uA |
| LDR divider (bright: LDR ~5k, pull-down ~500k) | ~7 uA |
| Pin 3 LOW, FADE cap discharged, Q1 OFF | 0 |
| Pin 4/10 HIGH, PNP Q2/Q3 OFF | 0 |
| **Total standby** | **~7 uA** |

At 7 uA, the battery would last 2000 mAh / 0.007 mA = **285,000 hours** (~32 years)
on standby alone. Daytime draw is negligible.

### Nighttime (Active) — Corrected Component Values

| Component | Current | Notes |
|-----------|---------|-------|
| CD4093 + oscillators (dynamic) | ~0.1 mA | Two gates oscillating at ~2.5 Hz |
| LDR divider (dark: LDR ~1M, pull-down ~500k) | ~2.4 uA | Negligible |
| Q1 base drive (FADE/10k) | ~0.29 mA | At full FADE voltage |
| Q2/Q3 base drive (2 x 13 uA) | ~0.03 mA | Through 220k each |
| Steady Bank: 3 LEDs x 0.93 mA | 2.79 mA | Through 1.5k each |
| Twinkle Bank 1: 3 LEDs x 0.64 mA x 50% duty | 0.96 mA | Square wave, 50% avg |
| Twinkle Bank 2: 3 LEDs x 0.64 mA x 50% duty | 0.96 mA | Square wave, 50% avg |
| **Total active (average)** | **~5.1 mA** | |
| **Total active (peak, all on)** | **~7.0 mA** | |

### Battery Life Without Solar

```
Continuous darkness: 2000 mAh / 5.1 mA = 392 hours ≈ 16.3 days
10 hrs/night cycle:  392 / 10 = ~39 nights
14 hrs/night (winter): 392 / 14 = ~28 nights
```

### Solar Energy Balance (with corrected 5.5V panels)

```
Solar input (2 panels, 100 mA combined, 4 hrs effective indoor light):
  Daily charge = 100 mA x 4 hrs = 400 mAh

Nighttime consumption (10 hrs):
  Daily discharge = 5.1 mA x 10 hrs = 51 mAh

Net daily surplus = +349 mAh → Battery stays full indefinitely

Even worst case (1 panel, dim window, 2 hrs effective):
  Daily charge = 50 mA x 2 hrs = 100 mAh
  Daily discharge = 51 mAh
  Net surplus = +49 mAh → Still self-sustaining
```

### Break-Even Analysis

Minimum solar input to sustain the circuit:

```
Required:  I_solar x t_sun  >=  I_active x t_night
           I_solar x t_sun  >=  5.1 mA x 10 hrs = 51 mAh

With 2 panels (100 mA combined):
  Minimum effective sun = 51 / 100 = 0.51 hours (31 minutes)

With 1 panel (50 mA):
  Minimum effective sun = 51 / 50 = 1.02 hours (61 minutes)
```

Even one hour of decent indoor light per day is enough. The design has excellent
solar margin.

---

## Longevity Analysis

### NiMH Battery Lifecycle

| Factor | Value | Impact |
|--------|-------|--------|
| Cycle life | 500–1000 cycles (Eneloop: 2100) | At 1 cycle/day: **1.4–5.8 years** |
| Self-discharge | Standard: 1–5%/day; Eneloop: ~15%/6 months | Use low-self-discharge cells |
| Voltage per cell at end-of-life | Drops from 1.2V to ~1.0V nominal | Circuit still runs (3.0V > CD4093 minimum) |
| Over-discharge damage threshold | Below 1.0V/cell (3.0V pack) | See protection discussion below |
| Temperature sensitivity | Loses 20–40% capacity below 0C | Indoor installation avoids this |
| Memory effect | Minimal with NiMH (unlike NiCd) | Not a concern |

**Recommendation:** Use **Eneloop or Eneloop Pro** cells. Their 2100-cycle rating at
1 cycle/day gives **5.8 years** before capacity drops below 80%. Plan for battery
replacement every 3–5 years as part of installation maintenance.

### Over-Discharge Protection

The corrected design notes (Issue 8) acknowledge this gap. NiMH cells are damaged
when discharged below 1.0V/cell (3.0V for the pack). The CD4093 stops functioning
cleanly below ~3V, providing a rough natural cutoff — but it's imprecise.

**During the transition zone (3.0–3.3V):**
- CD4093 oscillators may become erratic
- LED brightness drops significantly (Vdd - Vf headroom shrinks)
- The dusk detector threshold shifts (Schmitt thresholds are proportional to VDD)

**Low-cost protection options:**

1. **Zener voltage monitor (simplest):** Add a 3.0V zener diode + 100k resistor from
   VDD to the DARK signal path. When VDD drops below ~3.2V, the zener stops conducting
   and pulls the DARK line low via a divider — disabling all LEDs.

2. **Voltage supervisor IC:** A TL431 or MAX809 (costs ~$0.50) provides a clean
   under-voltage lockout at a precise threshold.

3. **Accept the natural cutoff:** The CD4093's graceful degradation below 3V effectively
   shuts down the LEDs. NiMH cells can tolerate occasional shallow over-discharge.
   For an art installation checked periodically, this may be acceptable.

### Charge Regulation

With the recommended 10-ohm current-limiting resistor and 5.5V panels:

| Condition | Charge Current | Rate |
|-----------|---------------|------|
| Battery at 3.0V (discharged) | ~220 mA | C/9 |
| Battery at 3.6V (nominal) | ~160 mA | C/12.5 |
| Battery at 4.35V (full) | ~85 mA | C/24 |

NiMH cells safely tolerate continuous charge at C/10 or below. The 220 mA peak
(C/9) at deeply discharged state is slightly above C/10 but occurs only briefly.
The self-tapering characteristic of the resistor (higher battery voltage = lower
current) provides crude but effective regulation.

For extra safety, increase R_charge to **15 ohm** (limits peak to ~147 mA = C/14).

### Component Lifetime Estimates

| Component | Expected Life | Failure Mode | Notes |
|-----------|--------------|--------------|-------|
| CD4093 CMOS IC | 20+ years | Latch-up, ESD | Essentially indefinite at room temp |
| 2N3904 / 2N3906 | 20+ years | None expected | Solid-state, no wear mechanism |
| 1N5819 Schottky | 15+ years | Increased Vf | Minimal degradation |
| Film capacitors (0.47uF) | 20+ years | None expected | Excellent long-term stability |
| Electrolytic cap (100uF) | 10–15 years | Dry-out, ESR rise | Replace at 10-year mark |
| LDR (GL5528, CdS) | 5–10 years | Sensitivity drift | CdS degrades with UV and humidity |
| NiMH batteries | 3–5 years | Capacity fade | Replace when runtime noticeably drops |
| Trimpots | 10+ years | Wiper wear (rare) | Set-and-forget, minimal wear |
| Breadboard contacts | 2–5 years | Intermittent connections | Transfer to perfboard for permanence |

**Key maintenance schedule for a permanent installation:**

| Interval | Action |
|----------|--------|
| Year 1 | Check battery voltage, re-tune trimpots if needed |
| Year 2–3 | Replace NiMH cells (standard) or check (Eneloop) |
| Year 3–5 | Replace NiMH cells (Eneloop), inspect solder joints |
| Year 5 | Transfer from breadboard to perfboard if not already done |
| Year 5–10 | Replace LDR if dusk sensitivity has drifted |
| Year 10 | Replace electrolytic capacitor (100uF) |

---

## What Works Well — Design Strengths

### 1. Dual Beat-Frequency Shimmer (Excellent)

The two oscillators at slightly different frequencies (~2.4 Hz and ~2.6 Hz) create a
beat pattern with period ≈ 1/(2.6-2.4) = 5 seconds. This produces a slowly drifting
shimmer that never exactly repeats — far more organic than a single blink rate or any
digital PWM pattern.

The 100k trimpots give fine control over the frequency offset, allowing the installer
to tune the "personality" of the shimmer from quick sparkle to slow breathing.

### 2. Schmitt-Trigger Dusk Detection (Solid)

The CD4093's built-in hysteresis (~30% of VDD = ~1.08V band at 3.6V) prevents
rapid on/off cycling during gradual twilight transitions. This is a textbook
application of Schmitt-trigger logic and works reliably.

The three-element pull-down (470k + 100k trimpot || 47k) provides:
- A fixed baseline threshold (470k + 47k = 517k minimum)
- Fine adjustment via trimpot (470k + 32k = 502k maximum)
- The adjustment range is narrow (~3%), which means the trimpot acts as a
  sensitivity fine-tune rather than a coarse control. This is appropriate for
  a set-once installation.

### 3. Fade-In Ramp (Well-Designed)

The 470k + 100uF RC network (tau = 47 seconds) creates a natural exponential bloom:

| Time | Voltage | Perceived Brightness |
|------|---------|---------------------|
| 0s | 0V | Dark |
| 10s | 0.7V | First visible glow (Vbe threshold) |
| 25s | 1.5V | Moderate |
| 47s | 2.3V | ~63% (one time constant) |
| 90s | 3.1V | ~86% |
| 141s | 3.4V | ~95% (effectively full) |

The Q1 transistor operates in its linear (active) region during the ramp, so LED
current rises smoothly rather than snapping on. The visual effect is an organic
"bloom" that feels like bioluminescence waking up.

At dawn (DARK goes LOW), the capacitor discharges through the 10k base resistor
(tau = 10k x 100uF = 1 second) while Q1 is conducting, then slowly through 470k
after Q1 turns off. The LEDs fade out in ~2–3 seconds — a fast but not jarring
transition.

### 4. Per-LED Current Limiting (Correct Practice)

Individual resistors per LED (1.5k for steady, 2.2k for twinkle) ensure equal
current sharing despite LED manufacturing Vf variations. This is essential for
visual uniformity in the "diamond field" and prevents one LED from hogging current
while others go dark.

### 5. Component Selection (Appropriate)

- **CD4093 CMOS** — runs from 3–18V with nanoamp quiescent current. Perfect for
  battery operation.
- **1N5819 Schottky** — 0.3V drop vs 0.6V for silicon. At 3.6V supply, this saves
  8% of the rail voltage — significant.
- **Film capacitors for oscillators** — tight tolerance, zero piezo effect, stable
  over temperature and time. Critical for consistent twinkle rates.
- **Red/amber LEDs (Vf 1.8–2.1V)** — correct choice for 3.6V supply. White/blue
  LEDs (Vf 3.0–3.2V) would leave almost no headroom and be extremely dim.

### 6. Ultra-Low Standby Power (with fixes applied)

At ~7 uA standby, the circuit essentially disappears from the battery's perspective
during daylight. This means 100% of solar energy goes to charging, with no parasitic
drain fighting the panels.

---

## Minor Issues and Recommendations

### 1. Breadboard Is Not Permanent

Solderless breadboard contacts degrade over time (oxidation, vibration, thermal
cycling). For an art installation meant to run for years:

**Recommendation:** Prototype on breadboard, then transfer to perfboard or stripboard
with soldered connections. Use a DIP socket for the CD4093 to allow replacement.

### 2. No Power Switch

Fine for a permanent installation, but makes debugging difficult. Adding an SPST
toggle between battery+ and VDD costs nothing and saves hours of troubleshooting.

### 3. Twinkle Banks Lack Fade-In

The steady bank fades in beautifully via the RC ramp, but the twinkle banks switch
on abruptly once the DARK signal enables the oscillators. This is acceptable
aesthetically — the "sparkle emerging from darkness" effect works — but for maximum
polish, you could:

- Route the oscillator outputs through resistors to the FADE node via diodes (OR
  gate), so twinkle brightness also tracks the fade ramp
- Or accept the abrupt onset as a deliberate design choice (diamonds "appearing")

### 4. Environmental Concerns (CdS LDR)

The GL5528 LDR contains cadmium sulfide, which is restricted under RoHS in some
jurisdictions. For a personal art project this is fine, but be aware:

- Dispose of responsibly (electronic waste, not household trash)
- If the installation is in a humid environment, seal the LDR or replace with a
  phototransistor (e.g., TEPT5700) and adjust the divider resistors accordingly

### 5. Oscillator Frequency Range Is Narrow

With 1M fixed + 100k trimpot, the adjustable range is only 2.4–2.6 Hz (an 8% span).
The beat frequency varies from 0 to 0.2 Hz — a range of "perfectly in sync" to
"5-second drift cycle."

For more dramatic shimmer variation, consider:
- Increase trimpots to **500k** → range becomes 1.3–2.6 Hz
- Or use different fixed resistors for each oscillator (e.g., 1M and 680k) to
  guarantee a permanent frequency offset even with trimpots centered

### 6. Gate 4 Could Add a Third Shimmer Layer

Gate 4 is currently wasted (inputs tied to VDD). It could be wired as a third
oscillator at a very different rate:

- **Slow breathing (0.2 Hz):** 1M + 2.2uF → drives a fourth LED group through
  another PNP transistor. Creates a "breathing" underlayer.
- **Fast glitter (8–10 Hz):** 220k + 0.47uF → drives a small LED cluster. Creates
  a subtle high-speed sparkle overlay.

This would add one more layer to the visual complexity at the cost of one transistor,
a few resistors, and some LEDs.

---

## Discrepancies Between Documents

The original BUILD-GUIDE.md has several conflicts with the corrected design:

| BUILD-GUIDE.md Says | Corrected Design Says | Issue |
|---------------------|----------------------|-------|
| Step 5: Gate 4 pins 12+13 tied to **GND** | Pins 12+13 tied to **VDD** | Both work, but VDD is conventional (output LOW = lower power) |
| Step 10: Pins 4+5 tied (inverter mode) | Pin 5 = DARK gating input | Different oscillator topology |
| Steps 14–15: 47k base resistors | 220k base resistors | 47k gives ~62 uA Ib (original), 220k gives ~13 uA (corrected) |
| Step 10: Pin 6 = output (2Y) | Pin 4 = output (2Y) | The corrected schematic matches the actual CD4093 datasheet (TI) |
| BOM.md: Gate 2 = pins 4,5 → 6 | Corrected: Gate 2 = pins 5,6 → 4 | Original BOM had pin assignments backwards |

The corrected documents are authoritative. The BUILD-GUIDE.md should be updated to
match.

---

## Summary of Required Changes

### Must Fix (circuit will not work without these)

| # | Issue | Fix | BOM Impact |
|---|-------|-----|------------|
| **F1** | Solar panels (2V) cannot charge 3.6V battery | Replace with 5–6V panels; add 10–15 ohm series resistor | Change panel spec, +1 resistor |
| **F2** | NAND stuck-HIGH turns twinkle LEDs ON during day | Replace Q2, Q3 with 2N3906 PNP high-side switches | Change 2x 2N3904 → 2x 2N3906 |

### Should Fix (longevity and reliability)

| # | Issue | Fix | BOM Impact |
|---|-------|-----|------------|
| **S1** | No NiMH over-discharge protection | Accept natural CD4093 cutoff at ~3V, or add voltage supervisor | Optional: +1 IC ($0.50) |
| **S2** | Breadboard not permanent | Transfer to perfboard after prototyping | Perfboard + solder |
| **S3** | No power switch | Add SPST toggle on VDD line | +1 switch ($0.50) |
| **S4** | BUILD-GUIDE.md contradicts corrected schematic | Update BUILD-GUIDE.md | Documentation only |

### Nice to Have (enhanced experience)

| # | Issue | Fix |
|---|-------|-----|
| **N1** | Narrow oscillator frequency range | Use 500k trimpots or different fixed resistors per oscillator |
| **N2** | Gate 4 wasted | Wire as third oscillator for breathing or glitter layer |
| **N3** | Twinkle banks lack fade-in | Add diode-OR from oscillators through FADE node (complex) |

---

## Updated BOM Delta (changes from corrected BOM)

```diff
  ## Power
- | 2–4 | Small solar panels | ~2V, 50–100 mA each. Wired in parallel. Indoor-rated. |
+ | 2–3 | Solar panels (5.5V) | 5–6V, 80–100 mA each. Wired in parallel. Indoor-rated. |
+ | 1   | Resistor (R_charge) | 10–15 ohm, 1/2W. Series current limiter in solar charge path. |

  ## Active Components
  (Q2 and Q3 change)
- | 3 | 2N3904 | TO-92 | NPN general-purpose transistor (Q1, Q2, Q3). |
+ | 1 | 2N3904 | TO-92 | NPN general-purpose transistor (Q1 — steady bank). |
+ | 2 | 2N3906 | TO-92 | PNP general-purpose transistor (Q2, Q3 — twinkle banks). |
```

### Revised Twinkle LED Wiring (PNP High-Side)

```
              VDD (+3.6V)
                │
         Q2 Emitter (2N3906 PNP)
                │
         Q2 Collector
           ┌────┼────┐
           │    │    │
          LED  LED  LED   (anodes)
           │    │    │
          LED  LED  LED   (cathodes)
           │    │    │
         2.2k  2.2k 2.2k
           │    │    │
           └────┼────┘
                │
               GND

Pin 4 (OSC1) ── 220k ── Q2 Base

Day:   Pin 4 = HIGH → Q2 base ≈ VDD → Veb ≈ 0 → OFF → LEDs dark
Night: Pin 4 oscillates → Q2 toggles → LEDs shimmer
```

---

## Conclusion

The Diamond Mine Shimmer Circuit is a clever and elegant analog design. The
dual-oscillator beat-frequency concept, Schmitt-trigger dusk detection, and RC
fade-in ramp are all well-conceived and produce a genuinely organic visual effect.

However, the two critical flaws (solar voltage mismatch and NAND gating bug) must
be corrected before the circuit can function as intended — charging by day and
shimmering by night. Both fixes are simple, low-cost, and don't change the
fundamental character of the design.

With the fixes applied and Eneloop batteries installed, this circuit should run
autonomously for **3–5 years** between battery changes, with the electronics
themselves lasting **10–20 years** in an indoor environment. It is an excellent
foundation for a permanent art installation.
