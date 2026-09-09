# Cryogenic Contour Shrinkage & CAD Oversizing Allowance — RS-25 Reference

## What this is

An independent reassessment of nozzle contour shrinkage under cryogenic pre-chill, and the CAD oversizing allowance needed to compensate for it — benchmarked against RS-25 flight geometry.

## Method

- Recalculated cryogenic pre-chill contour shrinkage against RS-25 flight geometry, correcting room-temperature CAD oversizing assumptions.
- Corroborated the hand-calculated radial contraction independently, using a one-way thermal-structural FSI pipeline: a steady-state ANSYS Fluent thermal field feeding into an ANSYS Mechanical structural solve.

## Key results

- Corrected room-temperature CAD oversizing to **+0.611 mm** at the throat and **+5.379 mm** at the exit.
- The FSI cross-check confirmed the hand-calculated radial contraction to within **~8%**, with the closed-loop check matching the corrected geometry to within **0.03%** of nominal throat and exit radii.

## Contents

- `Cryogenic_Contour_Shrinkage_RS25_FINAL.docx` — final report with theory, FSI methodology, and results.

## Note on code/tools

The FSI cross-check was run directly in ANSYS Fluent/Mechanical; there is no separate script repository for this project — the workflow and settings are documented in the report itself.
