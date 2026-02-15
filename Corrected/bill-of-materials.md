# Bill of Materials — Diamond Mine Shimmer (Corrected)

## Active Components

| Qty | Part | Package | Notes |
|-----|------|---------|-------|
| 1 | CD4093BE | DIP-14 | Quad Schmitt-trigger NAND gate. TI or ON Semi. |
| 3 | 2N3904 | TO-92 | NPN general-purpose transistor (Q1, Q2, Q3). |
| 1 | 1N5819 | DO-41 | Schottky diode, solar charge blocking. Vf ~0.3V. |
| 1 | LDR (GL5528) | 5mm | Light-dependent resistor, ~5k bright / ~500k dark. |

## Capacitors

| Qty | Value | Type | Purpose |
|-----|-------|------|---------|
| 1 | 0.1uF | Ceramic (104) | IC bypass decoupling across VDD/GND |
| 2 | 0.47uF | Film (474) | Oscillator timing caps (C1, C2) |
| 1 | 100uF / 10V+ | Electrolytic | Fade-in ramp. **Observe polarity.** |

## Fixed Resistors (1/4W, 5% tolerance)

| Qty | Value | Color Bands | Purpose |
|-----|-------|-------------|---------|
| 1 | 470k | Yellow-Violet-Yellow | Dusk threshold (fixed portion of divider) |
| 1 | 47k | Yellow-Violet-Orange | Dusk threshold (parallel pulldown) |
| 1 | 470k | Yellow-Violet-Yellow | Fade-in ramp charging resistor |
| 2 | 1M | Brown-Black-Green | Oscillator timing (fixed portion, one per osc) |
| 2 | 220k | Red-Red-Yellow | Oscillator output → transistor base drive |
| 1 | 10k | Brown-Black-Orange | Fade node → Q1 base drive |
| 3 | 1.5k | Brown-Green-Red | Steady bank LED current limit (~1.1 mA each) |
| 6 | 2.2k | Red-Red-Red | Twinkle bank LED current limit (~0.7 mA each) |

**Total fixed resistors: 17**

## Trimpots (Adjustable)

| Qty | Value | Type | Purpose |
|-----|-------|------|---------|
| 1 | 100k | 3-pin cermet or carbon | Dusk sensitivity — sets LDR trigger point |
| 2 | 100k | 3-pin cermet or carbon | Twinkle speed 1 & 2 — adjusts oscillator frequency |

## LEDs

| Qty | Color | Purpose | Current |
|-----|-------|---------|---------|
| 3 | Red, Amber, or Yellow | Steady bank (base glow) | ~1.1 mA each |
| 3 | Red, Amber, or Yellow | Twinkle bank 1 | ~0.7 mA each |
| 3 | Red, Amber, or Yellow | Twinkle bank 2 | ~0.7 mA each |

**Total LEDs: 9** (scale up or down as desired)

> **LED color note:** Red/amber/yellow LEDs (Vf ~1.8–2.1V) work best with a 3.6V supply.
> White or blue LEDs (Vf ~3.0–3.2V) will be very dim at these resistor values. If white is
> desired, reduce LED resistors to 470 ohm and expect higher current draw.

## Power

| Qty | Part | Notes |
|-----|------|-------|
| 3 | AA NiMH rechargeable | 1.2V nominal, 2000 mAh. Eneloop or similar. |
| 1 | 3xAA battery holder | With wire leads. |
| 2–4 | Small solar panels | ~2V, 50–100 mA each. Wired in parallel. Indoor-rated. |

## Mechanical

| Qty | Part | Notes |
|-----|------|-------|
| 1 | 830-point breadboard | Standard solderless. One board is sufficient. |
| 1 | Jumper wire kit | 22 AWG solid core, assorted colors. |
| 1 | DIP-14 socket (optional) | Protects IC from soldering heat if transferring to perfboard. |

---

## LED Current Calculations

### Steady Bank (1.5k resistors)

```
I = (VDD - Vf_LED - Vce_sat) / R
I = (3.6 - 2.0 - 0.2) / 1500
I = 1.4 / 1500
I = 0.93 mA per LED
```

### Twinkle Banks (2.2k resistors)

```
I = (3.6 - 2.0 - 0.2) / 2200
I = 1.4 / 2200
I = 0.64 mA per LED
```

### Transistor Base Drive

```
Steady (Q1):   Ib = (FADE - 0.7) / 10k  ≈ 0.2 mA max    → Ic_max = hFE × Ib = 20 mA (plenty)
Twinkle (Q2,3): Ib = (3.6 - 0.7) / 220k ≈ 13 uA          → Ic_max = hFE × Ib = 1.3 mA (sufficient for 3 LEDs)
```

---

## Cost Estimate (approximate, 2026 USD)

| Category | Estimated Cost |
|----------|---------------|
| CD4093 + socket | $1.50 |
| 3x 2N3904 | $1.00 |
| 1N5819 | $0.50 |
| LDR | $0.50 |
| Resistor assortment (if needed) | $5.00 |
| 3x trimpots | $2.00 |
| Capacitors | $1.50 |
| 9x LEDs | $2.00 |
| 3x AA NiMH batteries | $8.00 |
| Battery holder | $1.50 |
| 2x small solar panels | $6.00 |
| Breadboard + jumper wires | $6.00 |
| **Total** | **~$35** |
