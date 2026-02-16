# Bill of Materials — Diamond Mine Shimmer

## Active Components

| Qty | Part | Package | Notes |
|-----|------|---------|-------|
| 1 | CD4093BE | DIP-14 | Quad Schmitt-trigger NAND gate. TI or ON Semi. |
| 1 | 2N3904 | TO-92 | NPN general-purpose transistor (Q1 — steady bank). |
| 2 | 2N3906 | TO-92 | PNP general-purpose transistor (Q2, Q3 — twinkle banks). |
| 1 | 1N5819 | DO-41 | Schottky diode, solar charge blocking. Vf ~0.3V. |
| 1 | LDR (GL5528) | 5mm | Light-dependent resistor, ~5k bright / ~500k dark. |

## Capacitors

| Qty | Value | Type | Purpose |
|-----|-------|------|---------|
| 1 | 0.1uF | Ceramic (104) | IC bypass decoupling across VDD/GND |
| 2 | 0.47uF | Film (474) | Oscillator timing caps (C1, C2) |
| 1 | 100uF / 10V+ | Electrolytic | Fade-in ramp. **Observe polarity.** |

## Fixed Resistors

| Qty | Value | Rating | Purpose |
|-----|-------|--------|---------|
| 1 | 10 ohm | **1/2W** | Solar charge current limiter (R_charge) |
| 1 | 470k | 1/4W 5% | Dusk threshold (fixed portion of divider) |
| 1 | 47k | 1/4W 5% | Dusk threshold (parallel pulldown) |
| 1 | 470k | 1/4W 5% | Fade-in ramp charging resistor |
| 2 | 1M | 1/4W 5% | Oscillator timing (fixed portion, one per osc) |
| 2 | 220k | 1/4W 5% | Oscillator output to PNP base drive (Q2, Q3) |
| 1 | 10k | 1/4W 5% | Fade node to Q1 base drive |
| 3 | 1.5k | 1/4W 5% | Steady bank LED current limit (~0.9 mA each) |
| 6 | 2.2k | 1/4W 5% | Twinkle bank LED current limit (~0.6 mA each) |

**Total fixed resistors: 18**

## Trimpots (Adjustable)

| Qty | Value | Type | Purpose |
|-----|-------|------|---------|
| 1 | 100k | 3-pin cermet or carbon | Dusk sensitivity — sets LDR trigger point |
| 2 | 100k | 3-pin cermet or carbon | Twinkle speed 1 and 2 — adjusts oscillator frequency |

## LEDs

| Qty | Color | Purpose | Current |
|-----|-------|---------|---------|
| 3 | Red, Amber, or Yellow | Steady bank (base glow) | ~0.9 mA each |
| 3 | Red, Amber, or Yellow | Twinkle bank 1 | ~0.6 mA each |
| 3 | Red, Amber, or Yellow | Twinkle bank 2 | ~0.6 mA each |

**Total LEDs: 9** (scale up or down as desired)

> **LED color note:** Red/amber/yellow LEDs (Vf ~1.8–2.1V) work best with a 3.6V
> supply. White or blue LEDs (Vf ~3.0–3.2V) will be very dim at these resistor
> values. If white is desired, reduce LED resistors to 470 ohm and expect higher
> current draw.

## Power

| Qty | Part | Notes |
|-----|------|-------|
| 3 | AA NiMH rechargeable | 1.2V nominal, 2000 mAh. Eneloop recommended. |
| 1 | 3xAA battery holder | With wire leads. |
| 2–3 | Solar panels (5.5V) | 5–6V, 80–100 mA each. Wired in parallel. Indoor-rated. |

## Mechanical

| Qty | Part | Notes |
|-----|------|-------|
| 1 | 830-point breadboard | Standard solderless. One board is sufficient. |
| 1 | Jumper wire kit | 22 AWG solid core, assorted colors. |
| 1 | DIP-14 socket (optional) | Protects IC during soldering if transferring to perfboard. |

---

## LED Current Calculations

### Steady Bank (1.5k resistors, NPN low-side Q1)

```
I = (VDD - Vf_LED - Vce_sat) / R
I = (3.6 - 2.0 - 0.2) / 1500
I = 1.4 / 1500
I = 0.93 mA per LED
```

### Twinkle Banks (2.2k resistors, PNP high-side Q2/Q3)

```
I = (VDD - Vce_sat - Vf_LED) / R
I = (3.6 - 0.2 - 2.0) / 2200
I = 1.4 / 2200
I = 0.64 mA per LED
```

### Transistor Base Drive

```
Q1 (NPN, steady):
  Ib = (V_FADE - Vbe) / 10k
  Ib_max = (3.6 - 0.7) / 10k = 0.29 mA
  Ic_max = hFE x Ib = 100 x 0.29 mA = 29 mA  (plenty for 3 LEDs at 0.93 mA)

Q2/Q3 (PNP, twinkle):
  Ib = (VDD - Vbe - V_base) / 220k
  When output LOW:  Ib = (3.6 - 0.7 - 0) / 220k = 13 uA
  When output HIGH: Ib = (3.6 - 0.7 - 3.6) / 220k < 0  → OFF
  Ic_max = hFE x Ib = 100 x 13 uA = 1.3 mA  (sufficient for 3 LEDs at 0.64 mA)
```

### Solar Charge Current

```
R_charge = 10 ohm (1/2W)

At minimum battery (3.0V, deeply discharged):
  I = (5.5 - 0.3 - 3.0) / 10 = 220 mA  (C/9, acceptable for NiMH)

At nominal battery (3.6V):
  I = (5.5 - 0.3 - 3.6) / 10 = 160 mA  (C/12.5, safe)

At maximum battery (4.35V, fully charged):
  I = (5.5 - 0.3 - 4.35) / 10 = 85 mA   (C/24, indefinite trickle safe)

Power in R_charge: P_max = 0.22^2 x 10 = 0.48W → use 1/2W resistor
```

---

## Cost Estimate (approximate, 2026 USD)

| Category | Estimated Cost |
|----------|---------------|
| CD4093 + socket | $1.50 |
| 1x 2N3904 + 2x 2N3906 | $1.50 |
| 1N5819 | $0.50 |
| LDR | $0.50 |
| Resistor assortment (if needed) | $5.00 |
| 3x trimpots | $2.00 |
| Capacitors | $1.50 |
| 9x LEDs | $2.00 |
| 3x AA NiMH batteries (Eneloop) | $10.00 |
| Battery holder | $1.50 |
| 2x solar panels (5.5V) | $8.00 |
| Breadboard + jumper wires | $6.00 |
| **Total** | **~$40** |
