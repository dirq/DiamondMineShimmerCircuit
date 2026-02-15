# Solar-Powered Dual Oscillator "Diamond Mine" LED System

## Corrected Design — February 2026

A solar-charged, dusk-activated LED shimmer circuit using only analog CMOS logic and
transistors. No microcontroller. Extremely low power. Suitable for indoor solar use.

## Documents

| File | Contents |
|------|----------|
| [circuit-evaluation.md](circuit-evaluation.md) | Full accuracy review with issues and fixes |
| [schematic.md](schematic.md) | Corrected wiring schematic with all gate assignments |
| [breadboard-layout.md](breadboard-layout.md) | Clean physical layout with wire color guide |
| [bill-of-materials.md](bill-of-materials.md) | Complete parts list with values and notes |

## System Overview

```mermaid
graph TD
    subgraph Power
        SOLAR["Solar Panels<br/>(parallel)"]
        D1["1N5819<br/>Schottky Diode"]
        BAT["3x AA NiMH<br/>3.6V"]
        SOLAR -->|"charge"| D1 --> BAT
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
        Q1["Q1 — Steady Bank<br/>3x LED @ 1.5k"]
        Q2["Q2 — Twinkle Bank 1<br/>3x LED @ 2.2k"]
        Q3["Q3 — Twinkle Bank 2<br/>3x LED @ 2.2k"]
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
    G1->>Osc: DARK enables Gate 2 & Gate 3
    Fade->>LEDs: Steady bank glows (10s to start, 40s full)
    Osc->>LEDs: Twinkle banks shimmer at ~2.4–2.6 Hz
    Note over LEDs: Beat frequency ~0.2 Hz creates<br/>drifting 5-second visual pattern
```

## Design Achievements

- Solar self-sufficiency (indoor panels)
- Smooth dusk activation with Schmitt hysteresis
- Gentle 40-second fade-in bloom
- Multi-layer organic shimmer from dual oscillator beats
- ~10 mA active draw / <5 uA standby
- No microcontroller, no regulator, no firmware
