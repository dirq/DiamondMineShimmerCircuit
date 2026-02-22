# Diamond Mine Shimmer Circuit Design Documentation

This document is the canonical text export of the circuit design.

## Functional Overview

- Power: `3x AA NiMH` battery, trickle charged by `2-3` indoor solar panels through `1N5819`.
- Dusk detect: `LDR + 500k` divider into `CD4093` Schmitt inverter.
- Enable signal: `DARK` goes high in low light.
- Fade: `470k + 100uF` RC produces a slow rise at `FADE`.
- Twinkle: two independent `CD4093` RC oscillators (`1M + 100k trim + 0.47uF` each).
- Drivers: three `2N3904` low-side stages:
  - `Q1` base from `FADE` for steady bloom
  - `Q2` base from `TW1`
  - `Q3` base from `TW2`
- Daylight lockout: `1N4148` clamp from each twinkle base to `DARK` (`anode=base`, `cathode=DARK`).

## Nominal Component Values

- `R_fade = 470k`, `C_fade = 100uF`
- `R_osc1 = R_osc2 = 1M`, `RV2 = RV3 = 100k`, `C_osc1 = C_osc2 = 0.47uF`
- `R_b1 = R_b2 = R_b3 = 47k`
- Steady LED resistors: `1.5k` each
- Twinkle LED resistors: `2.2k` each
- Decoupling: `0.1uF` at CD4093 power pins

## Expected Behavior

- Daylight: `DARK=LOW`, all LEDs off.
- Dusk: `DARK` transitions high.
- First ~2-3 minutes: steady LEDs fade in.
- Night: twinkle banks run continuously at slightly different rates and drift in/out of phase.

## Exported Artifacts

- SPICE: `diamond-mine-shimmer.cir`, `diamond-mine-shimmer.sp`, `diamond-mine-shimmer.spice`
- Digital HDL: `diamond-mine-shimmer.v`, `diamond-mine-shimmer.vhd`
- BOM CSV: `BOM.csv`
- PCB layout container: `diamond-mine-shimmer.kicad_pcb`
