# Interactive Validator — GW-ML Adversarial Testing Tool

## What is this?

An **in-browser, interactive React component** that implements the core signal-detection pipeline from the [Independent Reproduction](./Adversarial_GWML_Independent_Reproduction.pdf) study. Unlike the PDF (which contains static results and theory), this tool lets you **explore, interact with, and visualize** the adversarial validation test in real time.

## What does it do?

The validator reproduces the paper's key question: **Does a matched-filter detector trained on Gaussian-only negatives fail against realistic detector glitches?**

### The Test Pipeline

1. **Inject a synthetic BBH-like chirp** at a specified SNR (adjustable 4–20 dB)
2. **Add background noise** from three conditions:
   - **True chirp** — synthetic GW signal (positive case)
   - **Naive negative** — Gaussian-only noise
   - **Hard negative** — realistic detector glitch (Blip, Scattered Light, or Koi Fish)
3. **Whiten** the data using local-RMS filtering
4. **Matched filter** against the chirp template
5. **Compute detection rate** at your chosen threshold (ρ* = 2–9)
6. **Bootstrap CI** — resample 1000 times to measure confidence in each rate

### The Adversarial Insight

The validator highlights a **critical mismatch**: when testing only against Gaussian noise (FAR_naive), a detector may appear safe. But when tested against real glitches (FAR_hard), it often **fails dramatically**. This hidden vulnerability is the paper's core finding, and this tool makes it interactive and visible.

## Controls

| Control | Range | Purpose |
|---------|-------|---------|
| **Injected SNR** | 4–20 dB | Signal strength: 4 dB = weak, 20 dB = strong |
| **Detection threshold ρ*** | 2–9 | Matched-filter score cutoff for detection |
| **Trials per condition** | 20–250 | Replicates per test condition (more = smoother curves) |
| **Hard-negative glitch class** | Blip / Scattered / Koi | Which realistic glitch morphology to test against |

## Interpreting Results

After running validation, you'll see three detection rates:

- **TPR — true chirp** (green): Should be high (~60–100% depending on SNR)
- **FAR — Gaussian only** (blue): False-alarm rate on synthetic Gaussian negatives
- **FAR — hard glitch** (orange): False-alarm rate on realistic glitches

### The Red Flag

If the **orange bar** is significantly higher than the **blue bar** (gap > 8 percentage points), a warning appears:

```
⚠ gap of Xpp — Gaussian-only testing hides this glitch class
```

This is your adversarial signal. The detector is overconfident in Gaussian-only validation.

## Visualization Panels

### 1. TEMPLATE — synthetic BBH-like chirp
Shows the matched-filter template: an idealized binary black-hole merger waveform with inspiral, merger, and ringdown phases.

### 2. EXAMPLE TRIAL — chirp + noise (whitened)
A single trial from the true-chirp condition:
- **Raw trace** (dark grey): noisy waveform
- **Whitened trace** (cyan): after local-RMS whitening, the chirp becomes more prominent

### 3. EXAMPLE TRIAL — glitch (hard negative)
A single trial from the hard-negative condition, showing how the selected glitch morphology corrupts the data differently than Gaussian noise.

### 4. BOOTSTRAP DISTRIBUTION
Histogram of resampled false-alarm rates (1000 bootstrap replicates):
- **Bar colors**: orange where the FAR is within the 95% CI, faint where outside
- **Dashed line**: Gaussian-only FAR, for comparison

## Technical Notes

### Simplifications (vs. real LIGO pipeline)

- **Local-RMS whitening** (24-sample window) stands in for full power-spectral-density whitening
- **Single template** (instead of template bank) — the matched filter searches a sliding window of fixed size
- **Synthetic data** — all noise is simulated Gaussian or engineered glitches, not real detector strain

These choices keep computation in-browser and avoid external dependencies, but they preserve the paper's core insight: **adversarial negatives reveal detector fragility that Gaussian testing alone would hide.**

### Signal Model

- **Sampling rate**: 256 Hz
- **Buffer duration**: 1.5 s (384 samples)
- **Chirp duration**: 0.75 s (192 samples)
- **Chirp frequency sweep**: 35 Hz → 250 Hz (cubic in time)
- **SNR definition**: `SNR_dB = 20 * log10(amp_linear)` where `amp_linear = 10^(SNR_dB/20) × 0.35`

### Glitch Morphologies

1. **Blip** — short, high-Q narrowband impulse (~180 Hz center)
2. **Scattered Light** — complex multi-tone structure, simulates optical scatter artifacts
3. **Koi Fish** — broadband chirp-like artifact (named after Gravity-Spy volunteer category)

All three are energy-normalized unit-length and envelope-tapered to avoid edge artifacts.

## Running Locally

### Prerequisites

```json
{
  "react": "^18.0.0",
  "recharts": "^2.8.0",
  "lucide-react": "^0.263.0"
}
```

### Setup

1. Copy `gwml_adversarial_validator.jsx` into your React app's component tree
2. Ensure Recharts and Lucide are installed
3. Import and render:

```jsx
import App from './gwml_adversarial_validator';
export default App;
```

4. Run your dev server (e.g., `npm start`)

### Styling

All styling is inline; no external CSS is required. The color palette mimics LIGO's control-room aesthetic (dark background, cyan/orange accents for signal/glitch distinction).

## Key Takeaways

- **Gaussian-only testing is insufficient** — it can hide adversarial vulnerabilities
- **Realistic negatives matter** — detector glitches are structurally different from noise
- **Interactive exploration builds intuition** — adjust SNR and threshold to understand detector trade-offs
- **Bootstrap CIs quantify uncertainty** — detection rate point estimates alone are misleading

## Reference

For the full methodology, validation, and statistical framework, see:
- [Adversarial_GWML_Independent_Reproduction.pdf](./Adversarial_GWML_Independent_Reproduction.pdf)

## License & Attribution

This tool reproduces the methodology from an independent study of adversarial machine-learning validation in gravitational-wave signal detection. All code is original; the conceptual framework and adversarial testing paradigm are attributed to the peer-reviewed paper cited above.
