# Stellar Contamination as a Source of False-Positive Biosignatures

## What this is

Research into how stellar contamination effects (starspots, faculae) imprint on exoplanet transmission spectra and can produce false-positive biosignature detections.

## Method

- Built a Monte Carlo retrieval and ML classification pipeline modeling the transit light source effect, anchored to TRAPPIST-1 stellar parameters.
- Applied a degree-6 polynomial continuum correction to isolate genuine spectral signal from contamination-driven curvature.

## Key results

- Resolved 167 ppm of unmodeled spectral curvature via the continuum correction, isolating a 15 ppm O₂ signal.
- Found that masking dominates over false-positive generation across realistic parameter configurations.

## Contents

- `Stellar_Contamination_False_Biosignatures.docx` — full writeup: literature context, methodology, results, and discussion.

## Note on code

The retrieval/classification pipeline is documented and described within the report; there is no separate code repository for this project in this folder.
