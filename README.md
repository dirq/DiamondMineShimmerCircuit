# Diamond Mine Shimmer Circuit — Final Design

A solar-charged, dusk-activated LED shimmer circuit. No microcontroller, no firmware —
pure analog CMOS logic and transistor drivers produce an organic, non-repeating sparkle
field that charges by day and shimmers by night.

## Documents

| File | Contents |
|------|----------|
| [BUILD-GUIDE.md](BUILD-GUIDE.md) | Step-by-step breadboard assembly and testing |
| [schematic.md](schematic.md) | Complete wiring schematic with gate assignments and net list |
| [bill-of-materials.md](bill-of-materials.md) | Full parts list with values, calculations, and cost |
| [breadboard-layout.md](breadboard-layout.md) | Physical layout with zone map and wire color guide |
| [circuit-evaluation.md](circuit-evaluation.md) | Performance characteristics and power budget |
| [circuit-evaluation-deep-dive.md](circuit-evaluation-deep-dive.md) | Extended design review with longevity analysis |
| [design-documentation.md](design-documentation.md) | Theory of operation, timing math, tuning guide |
| [bom.csv](bom.csv) | Machine-readable BOM for ordering |
| [diamond-mine-shimmer.cir](diamond-mine-shimmer.cir) | SPICE netlist for circuit simulation |
| [diamond-mine-shimmer.v](diamond-mine-shimmer.v) | Verilog behavioral model |
| [diamond-mine-shimmer.kicad_sch](diamond-mine-shimmer.kicad_sch) | KiCad schematic for PCB workflow |

## System Overview

```mermaid
graph TD
    subgraph Power
        SOLAR["Solar Panels<br/>5.5V, parallel"]
        RC["R_charge<br/>10 ohm"]
        D1["1N5819<br/>Schottky Diode"]
        BAT["3x AA NiMH<br/>3.6V nominal"]
        SOLAR -->|"charge"| RC --> D1 --> BAT
    end

    subgraph "CD4093 — Single IC, 4 Gates"
        G1["Gate 1<br/>Dusk Detector<br/>(pins 1,2 → 3)"]
        G2["Gate 2<br/>Oscillator 1 — Gated<br/>(pins 5,6 → 4)"]
        G3["Gate 3<br/>Oscillator 2 — Gated<br/>(pins 8,9 → 10)"]
        G4["Gate 4<br/>Unused — tied to VDD<br/>(pins 12,13 → 11)"]
    end

    subgraph Sensing
        LDR["LDR + Resistor<br/>Voltage Divider"]
        FADE["Fade-In Ramp<br/>470k + 100uF<br/>τ = 47s"]
    end

    subgraph "LED Outputs"
        Q1["Q1 (NPN 2N3904)<br/>Steady Bank<br/>3x LED @ 1.5k"]
        Q2["Q2 (PNP 2N3906)<br/>Twinkle Bank 1<br/>3x LED @ 2.2k"]
        Q3["Q3 (PNP 2N3906)<br/>Twinkle Bank 2<br/>3x LED @ 2.2k"]
    end

    BAT -->|"VDD"| G1
    BAT -->|"VDD"| G2
    BAT -->|"VDD"| G3
    LDR -->|"SENSE"| G1
    G1 -->|"DARK signal"| FADE
    G1 -->|"DARK gates pin 5"| G2
    G1 -->|"DARK gates pin 8"| G3
    FADE -->|"ramp voltage"| Q1
    G2 -->|"~2.6 Hz square wave"| Q2
    G3 -->|"~2.4 Hz square wave"| Q3
```

## Signal Flow at Dusk

```mermaid
sequenceDiagram
    participant Light as Ambient Light
    participant LDR as LDR Sensor
    participant G1 as Gate 1 (Dusk)
    participant Fade as Fade Ramp
    participant Osc as Oscillators
    participant LEDs as LED Field

    Light->>LDR: Light level drops
    LDR->>G1: SENSE voltage falls below VT-
    G1->>G1: Schmitt hysteresis prevents flicker
    G1->>Fade: DARK goes HIGH
    G1->>Osc: DARK enables Gate 2 and Gate 3
    Fade->>LEDs: Steady bank glows (10s to start, 40s full)
    Osc->>LEDs: Twinkle banks shimmer at ~2.4–2.6 Hz
    Note over LEDs: Beat frequency ~0.2 Hz creates<br/>drifting 5-second visual pattern
```

## Design Highlights

- **Solar self-sufficiency** — 5.5V panels with current-limited trickle charge
- **Smooth dusk activation** — Schmitt hysteresis prevents twilight flicker
- **Gentle 40-second fade-in** — RC ramp creates organic bloom
- **Multi-layer shimmer** — dual oscillator beats produce non-repeating patterns
- **Correct day/night gating** — PNP high-side switches ensure zero LED current in daylight
- **~5 mA active / ~7 uA standby** — months of battery life, easily solar-sustained
- **No microcontroller, no regulator, no firmware**
