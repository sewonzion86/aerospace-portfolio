# Regenerative Cooling Margin Against Critical Heat Flux — RS-25 Reference

## What this is

An independent reassessment of the throat heat-transfer margin used in regenerative cooling channel design, benchmarked against RS-25 flight geometry and its known operating point (20.64 MPa chamber pressure, O/F ratio 6.03).

## Method

- Verified chamber conditions with a NASA CEA equilibrium solution.
- Resolved gas-side wall temperature via a coupled three-resistance thermal network (gas-side convection → wall conduction → coolant-side convection).
- Applied the Hess-Kunz correlation for supercritical hydrogen coolant-side heat transfer.

## Key results

- Recalculated throat heat flux came in at **~6.6×** the prior subscale-geometry estimate — exceeding the commonly cited LOX/LH2 throat flux band.
- The margin is highly sensitive to coolant channel geometry:
  - A placeholder 3.0 mm channel width gave a marginal **−2.0 K** result (i.e. essentially failing).
  - The patent-sourced channel geometry (1.09 mm width, 0.84 mm depth, N = 390 channels) gives a **+238.63 K** margin.

## Contents

- `Regenerative_Cooling_Margin_RS25_FINAL.docx` — final report with theory, method, and results.
- `CLZIRP_Gap1_Full_Calculations-6.docx` — full supporting hand calculations backing the final report.

## Note on code/tools

This is a hand-calculation and thermal-network analysis report — there is no separate code repository for this project. Where ANSYS Fluent/Mechanical or NASA CEA were used, that's documented inline in the report itself.
