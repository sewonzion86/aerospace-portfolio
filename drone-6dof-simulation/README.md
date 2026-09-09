# Quad/Hexacopter 6-DOF Flight Dynamics Simulation

## What this is

Newton-Euler 6-degree-of-freedom flight dynamics modeling and control work for quadcopter and hexacopter rotor configurations, built in Simulink/MATLAB.

## Method

- Derived full nonlinear 6DOF equations of motion (Newton-Euler) from first principles.
- Implemented a gravity-compensated motor-mixing allocation for both 4-motor (quadcopter) and 6-motor (hexacopter) configurations.
- Validated motor speeds against hand-calculated hover conditions across six independent attitude/position control loops.

## Key results

- Validated hover motor speeds: **~620 rad/s** (quadcopter), **~507 rad/s** (hexacopter), matching hand-calculated values.

## Contents

- `Quad_Hexacopter_6DOF_Report.docx` — full report covering the dynamics derivation, control approach, and simulation results.

## Note on files

This repository currently contains the written report only. The underlying Simulink model file (`.slx`) is not yet included here — it will be added if/when the project resumes from its current paused state.
