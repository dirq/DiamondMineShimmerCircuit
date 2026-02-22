# Breadboard Layout — Diamond Mine Shimmer

## Board Overview

Standard 830-point solderless breadboard. Power rails top and bottom, IC centered,
components grouped by function zone.

![Breadboard zone overview](assets/diamond-mine-breadboard-overview.png)

```mermaid
graph TD
    subgraph "Breadboard Zones (left to right)"
        direction LR
        ZA["Zone A<br/>POWER INPUT<br/>Solar, R_charge,<br/>Diode, Battery<br/>(rows 1–5)"]
        ZB["Zone B<br/>DUSK DETECTOR<br/>LDR, R_sense,<br/>Trimpot<br/>(rows 6–14)"]
        ZC["Zone C<br/>IC + OSCILLATORS<br/>CD4093, RC networks,<br/>Fade cap<br/>(rows 15–35)"]
        ZD["Zone D<br/>TRANSISTORS<br/>Q1 (NPN), Q2/Q3 (PNP)<br/>(rows 38–52)"]
        ZE["Zone E<br/>LED BANKS<br/>Resistors + LEDs<br/>(rows 55–63)"]
        ZA --> ZB --> ZC --> ZD --> ZE
    end
```

---

## Power Rails

```
(+) rail ═══════════════════════════════════════════════ VDD (Battery+)
                    board top edge

 ... breadboard rows ...

(−) rail ═══════════════════════════════════════════════ GND (Battery−)
                    board bottom edge
```

Place a **0.1uF ceramic cap** spanning (+) and (−) rails near the IC location (around row 15).

---

## Zone A: Power Input (rows 1–5)

![Power section — solar panels, R_charge, diode, battery connections](assets/diamond-mine-power-section.png)

```
Row 1:  Solar+ wire → 10 ohm R_charge (1/2W) → Row 2
Row 2:  R_charge output → 1N5819 anode (band faces right toward row 3)
Row 3:  1N5819 cathode → jumper wire to (+) rail
Row 1:  Solar− wire → jumper to (−) rail
        Battery+ → (+) rail
        Battery− → (−) rail
```

> **R_charge (10 ohm, 1/2W):** Limits solar charge current to safe NiMH trickle
> range. Must be rated 1/2W minimum (0.48W worst-case dissipation).

---

## Zone B: Dusk Detector (rows 6–14)

```
Row 6:   (+) rail → LDR leg 1
Row 8:   LDR leg 2 (SENSE node)
Row 8:   jumper from here → Row 15 (Pin 1/2 node)
Row 8:   470k resistor: Row 8 → Row 11
Row 11:  100k trimpot wiper → Row 11
         trimpot end 1 → Row 11 (connects to 470k)
         trimpot end 2 → (−) rail
Row 11:  47k resistor → (−) rail
```

---

## Zone C: IC + Oscillators (rows 15–35)

![CD4093 pinout and connections](assets/diamond-mine-cd4093-pinout.png)

![Dusk detector, fade ramp, and oscillator RC networks](assets/diamond-mine-dusk-and-oscillators.png)

### Bypass Capacitor

```
Row 14:  0.1uF ceramic cap: (+) rail → (−) rail   (within 1 row of Pin 14)
```

### CD4093 Placement

IC straddles center channel at rows 15–21:

```
         Column E (lower)     Column F (upper)
Row 15:    Pin 1  ──────────  Pin 14    → wire to (+) rail
Row 16:    Pin 2  ──────────  Pin 13    → wire to (+) rail
Row 17:    Pin 3  ──────────  Pin 12    → wire to (+) rail
Row 18:    Pin 4  ──────────  Pin 11    (no connection)
Row 19:    Pin 5  ──────────  Pin 10
Row 20:    Pin 6  ──────────  Pin 9
Row 21:    Pin 7  ──────────  Pin 8
             │
             └→ wire to (−) rail
```

### IC-Side Jumpers

| From | To | Purpose |
|------|----|---------|
| Row 15 col A (Pin 1) | Row 16 col A (Pin 2) | Tie Gate 1 inputs together |
| Row 16 col J (Pin 13) | (+) rail | Tie Gate 4 input A to VDD |
| Row 17 col J (Pin 12) | (+) rail | Tie Gate 4 input B to VDD |
| Row 15 col J (Pin 14) | (+) rail | IC power |
| Row 21 col E (Pin 7) | (−) rail | IC ground |

### DARK Signal Distribution (Pin 3, Row 17)

| From | To | Purpose |
|------|----|---------|
| Row 17 col A | Row 19 col A (Pin 5) | Gate oscillator 1 |
| Row 17 col A | Row 21 col J (Pin 8) | Gate oscillator 2 |
| Row 17 col C | Row 23 (470k to FADE) | Start of fade ramp |

### Fade-In Ramp

```
Row 23:  470k resistor: Row 17 col C → Row 23
Row 25:  100uF electrolytic (+) at Row 25, (−) to (−) rail
         Row 23 → Row 25 jumper (FADE node)
```

### Oscillator 1 (Gate 2)

```
Row 18 col A (Pin 4 output):
    1M resistor: Row 18 col A → Row 28
Row 28:
    100k trimpot: Row 28 → Row 30
Row 30 (RC1 node):
    jumper → Row 20 col A (Pin 6)
    0.47uF film cap: Row 30 → (−) rail
```

### Oscillator 2 (Gate 3)

```
Row 19 col J (Pin 10 output):
    1M resistor: Row 19 col J → Row 33
Row 33:
    100k trimpot: Row 33 → Row 35
Row 35 (RC2 node):
    jumper → Row 20 col J (Pin 9)
    0.47uF film cap: Row 35 → (−) rail
```

---

## Zone D: Transistors (rows 38–52)

![Transistor orientation — E-B-C pin order, NPN vs PNP wiring](assets/diamond-mine-transistor-orientation.png)

All transistors: flat side facing you, pins left-to-right: E, B, C.

### Q1 — Steady Bank Driver (NPN 2N3904)

```
Row 40:  col A = Emitter → (−) rail
         col B = Base    ← 10k ← FADE node (Row 25)
         col C = Collector → jumper to Steady LED bank
```

### Q2 — Twinkle Bank 1 Driver (PNP 2N3906)

```
Row 45:  col A = Emitter → (+) rail       ← NOTE: VDD, not GND
         col B = Base    ← 100k ← Pin 4 / OSC1 (Row 18 col A)
         col C = Collector → jumper to Twinkle LED bank 1
```

### Q3 — Twinkle Bank 2 Driver (PNP 2N3906)

```
Row 50:  col A = Emitter → (+) rail       ← NOTE: VDD, not GND
         col B = Base    ← 100k ← Pin 10 / OSC2 (Row 19 col J)
         col C = Collector → jumper to Twinkle LED bank 2
```

> **PNP wiring:** Q2 and Q3 emitters connect to (+) VDD rail, NOT (−) GND.
> This is the opposite of Q1 (NPN). The PNP high-side topology ensures the
> twinkle LEDs are completely OFF when DARK = LOW (daytime).

---

## Zone E: LED Banks (rows 55–63)

![LED wiring — Steady bank vs Twinkle bank topology and polarity](assets/diamond-mine-led-wiring.png)

### Steady Bank (NPN Q1: VDD → resistor → LED → Q1 collector)

Each LED: anode via resistor to (+) rail, cathode to Q1 collector.

```
Row 55:  1.5k from (+) rail → LED anode, LED cathode → wire to Row 40 col D
Row 56:  1.5k from (+) rail → LED anode, LED cathode → wire to Row 40 col D
Row 57:  1.5k from (+) rail → LED anode, LED cathode → wire to Row 40 col D
```

### Twinkle Bank 1 (PNP Q2: Q2 collector → LED → resistor → GND)

Each LED: anode from Q2 collector, cathode via resistor to (−) rail.

```
Row 58:  wire from Row 45 col D → LED anode, LED cathode → 2.2k → (−) rail
Row 59:  wire from Row 45 col D → LED anode, LED cathode → 2.2k → (−) rail
Row 60:  wire from Row 45 col D → LED anode, LED cathode → 2.2k → (−) rail
```

### Twinkle Bank 2 (PNP Q3: Q3 collector → LED → resistor → GND)

Each LED: anode from Q3 collector, cathode via resistor to (−) rail.

```
Row 61:  wire from Row 50 col D → LED anode, LED cathode → 2.2k → (−) rail
Row 62:  wire from Row 50 col D → LED anode, LED cathode → 2.2k → (−) rail
Row 63:  wire from Row 50 col D → LED anode, LED cathode → 2.2k → (−) rail
```

> **Topology difference:** Steady bank LEDs connect VDD-side resistor → LED → Q1
> collector. Twinkle bank LEDs connect Q2/Q3 collector → LED → GND-side resistor.
> This reversal is required for the PNP high-side switch topology.

---

## Wire Color Guide

```mermaid
graph LR
    RED["RED<br/>VDD power"] ~~~ BLACK["BLACK<br/>GND ground"]
    YELLOW["YELLOW<br/>DARK signal<br/>(Pin 3 → Pin 5, Pin 8, 470k)"] ~~~ ORANGE["ORANGE<br/>FADE node<br/>(100uF → 10k → Q1)"]
    GREEN["GREEN<br/>OSC1 output<br/>(Pin 4 → 100k → Q2)"] ~~~ BLUE["BLUE<br/>OSC2 output<br/>(Pin 10 → 100k → Q3)"]
    WHITE["WHITE<br/>LDR SENSE node<br/>(LDR → Pin 1/2)"]

    style RED fill:#cc0000,color:#fff
    style BLACK fill:#222222,color:#fff
    style YELLOW fill:#ffcc00,color:#000
    style ORANGE fill:#ff8800,color:#000
    style GREEN fill:#22aa22,color:#fff
    style BLUE fill:#2266cc,color:#fff
    style WHITE fill:#eeeeee,color:#000
```

| Color | Signal | From → To |
|-------|--------|-----------|
| Red | VDD | (+) rail → Pin 14, Pin 12, Pin 13, LDR, Steady LED resistors, Q2/Q3 emitters |
| Black | GND | (−) rail → Pin 7, Q1 emitter, caps, trimpot ends, Twinkle LED resistors |
| Yellow | DARK | Pin 3 → Pin 5, Pin 8, 470k fade resistor |
| Orange | FADE | 470k/100uF junction → 10k → Q1 base |
| Green | OSC1 | Pin 4 → 1M (feedback) and 100k → Q2 base |
| Blue | OSC2 | Pin 10 → 1M (feedback) and 100k → Q3 base |
| White | SENSE | LDR → Pin 1, Pin 2, 470k divider top |

---

## Layout Tips

1. **Keep bypass cap close to IC** — The 0.1uF ceramic should be within 1–2 rows of pins 7 and 14.
2. **Electrolytic polarity** — The 100uF fade cap has a stripe marking the negative leg. Negative to (−) rail.
3. **Trimpot orientation** — Mount trimpots with adjustment screw facing outward for easy tuning.
4. **LED polarity** — Longer leg = anode. Flat edge on lens = cathode.
5. **NPN (Q1) vs PNP (Q2, Q3)** — Q1 emitter to GND. Q2/Q3 emitters to VDD. All three: flat side facing you, E-B-C left to right.
6. **Film vs electrolytic** — Use film caps (0.47uF) for oscillators (non-polarized). Use electrolytic (100uF) only for the fade ramp (polarized, observe +/−).
7. **R_charge heat** — The 10 ohm resistor may get warm in full sun. Use 1/2W rating and leave airspace around it.
