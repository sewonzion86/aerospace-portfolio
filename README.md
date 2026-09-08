# Sewon Zion S — Propulsion & Robotics Research Portfolio

B.E. Aeronautical Engineering, Nehru Institute of Engineering and Technology (Anna University).
Aspiring rocket & space propulsion engineer.

This repo collects the independent research, reassessments, and reproductions done outside coursework. Each folder is self-contained with its own writeup.

## Contents

### [`propulsion-research/`](./propulsion-research)
Two independent reassessments of published nozzle design margins against the Space Shuttle Main Engine (RS-25), each identifying a gap in the original design methodology and proposing a corrected approach.

- **`regenerative-cooling-chf-margin/`** — reassesses the critical-heat-flux margin used in regenerative cooling channel design, with full supporting calculations.
- **`cryogenic-contour-shrinkage/`** — reassesses contour shrinkage and GD&T tolerancing under cryogenic thermal contraction, a factor absent from the original design's tolerance stack.

### [`gwml-adversarial-validation/`](./gwml-adversarial-validation)
An independent, from-scratch re-implementation of a published adversarial-validation study for gravitational-wave-like signal detectors. Rebuilds the full pipeline (toy-chirp generator, colored-noise model, three classifiers, seven-condition stress suite) with no code copied from the original, then goes further — closing every limitation the original study flagged (SNR sweep, architecture robustness check, disjoint waveform-family test, densified matched filter) and reporting results candidly where they diverge from the source paper.

### [`drone-6dof-simulation/`](./drone-6dof-simulation)
Quad/hexacopter 6-DOF Newton-Euler simulation and control work in Simulink.

### [`stellar-contamination-biosignatures/`](./stellar-contamination-biosignatures)
Research into stellar contamination as a source of false-positive biosignature detections in exoplanet atmospheres.

## Status

Working documents for now — CAD, code, and datasets for each project will be added as they're finalized. Next planned addition: turbopump sizing work (LOX/LH2 feed system) as a direct continuation of the propulsion-research folder.
