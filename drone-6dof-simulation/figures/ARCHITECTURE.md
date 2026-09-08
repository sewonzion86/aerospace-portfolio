# System Architecture

## Drone 6DOF Simulation Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SIMULATION ARCHITECTURE                       │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │  REFERENCE INPUT    │
                    │  - Position (x,y,z) │
                    │  - Attitude (φ,θ,ψ) │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ POSITION CONTROLLER │
                    │   (Outer Loop)      │
                    │   Cascaded PID      │
                    └──────────┬──────────┘
                               │ (Attitude Command)
                    ┌──────────▼──────────┐
                    │ ATTITUDE CONTROLLER │
                    │   (Inner Loop)      │
                    │   Cascaded PID      │
                    └──────────┬──────────┘
                               │ (Moment/Force Command)
                    ┌──────────▼──────────┐
                    │ THRUST ALLOCATOR    │
                    │ [Fz, τx, τy, τz]   │
                    │    → [ω1, ω2, ω3] │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   MOTOR DYNAMICS    │
                    │  (First-order lag)  │
                    │   τ_m = 0.01s       │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
    ┌───▼──┐             ┌───▼──┐             ┌───▼──┐
    │Motor1│             │Motor2│             │Motor3│
    │  ω₁  │             │  ω₂  │             │  ω₃  │
    └───┬──┘             └───┬──┘             └───┬──┘
        │ T₁=Ct*ω₁²         │ T₂=Ct*ω₂²         │ T₃=Ct*ω₃²
        │ Q₁=Cq*ω₁²         │ Q₂=Cq*ω₂²         │ Q₃=Cq*ω₃²
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌───────▼────────┐
                    │  ROTOR CONFIG  │
                    │  (Allocation)  │
                    │ Compute Forces │
                    │  & Torques     │
                    └───────┬────────┘
                            │
        ┌───────────────────┼──────────────────┐
        │                   │                  │
    ┌───▼────┐     ┌────────▼────┐    ┌───────▼──┐
    │ Gravity │    │  Aerodynamic│    │ Inertial │
    │   Mg    │    │   Drag      │    │  Frame   │
    └───┬────┘    └────────┬────┘    └───────┬──┘
        │                   │                  │
        └───────────────────┼──────────────────┘
                            │
                    ┌───────▼────────┐
                    │  6DOF DYNAMICS │
                    │   EQUATIONS    │
                    │                │
                    │ Ṙ = V          │
                    │ V̇ = Forces/m   │
                    │ Ω̇ = τ/I        │
                    │ Euler Kinematic│
                    └───────┬────────┘
                            │
        ┌───────────────────┼──────────────────┐
        │                   │                  │
    ┌───▼────┐     ┌────────▼────┐    ┌───────▼──┐
    │Position │    │  Attitude   │    │Velocities│
    │ X Y Z   │    │  φ θ ψ      │    │Vx Vy Vz │
    └───┬────┘    └────────┬────┘    └───────┬──┘
        │                   │                  │
        └───────────────────┼──────────────────┘
                            │
                    ┌───────▼────────┐
                    │  STATE VECTOR  │
                    │   12 States    │
                    │                │
                    │ Feedback to    │
                    │ Controllers    │
                    └────────────────┘
```

## Control Loop Architecture

### Outer Loop: Position Control
```
Reference Position → Error → PID → Attitude Command
                     ↓ (Feedback)
              Current Position
```

**Output**: Desired roll (φ_des), pitch (θ_des), yaw rate (ψ̇_des)

### Inner Loop: Attitude Control
```
Attitude Command → Error → PID → Motor Commands
                   ↓ (Feedback)
              Current Attitude
```

**Output**: Motor speed commands [ω₁, ω₂, ω₃, ω₄]

## Signal Flow

1. **Reference Input** (Position & Attitude)
2. **Position Error Computation** (x_error = x_ref - x_actual)
3. **Position Controller** generates attitude commands
4. **Attitude Error Computation** (attitude_error = attitude_ref - attitude_actual)
5. **Attitude Controller** generates force/torque commands
6. **Thrust Allocator** converts [Fz, τx, τy, τz] to [ω₁, ω₂, ω₃, ω₄]
7. **Motor Model** applies first-order lag to motor speeds
8. **Force/Torque Generation** from rotor speeds
9. **6DOF Dynamics Integration** using Euler angles & rates
10. **State Output** for feedback and logging

## Key Parameters

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Mass | m | 1.2 | kg |
| Arm Length | L | 0.225 | m |
| Thrust Coefficient | Ct | 1.0966e-4 | N·s²/rad² |
| Torque Coefficient | Cq | 2.5e-6 | N·m·s²/rad² |
| Motor Time Constant | τm | 0.01 | s |
| Ixx | Ixx | 0.0065 | kg·m² |
| Iyy | Iyy | 0.0065 | kg·m² |
| Izz | Izz | 0.012 | kg·m² |

## Files Associated with Architecture

- **Model Implementation**: `../model/quadcopter_6dof.slx`
- **Parameters**: `../scripts/parameters.m`
- **Initialization**: `../scripts/initialize_simulation.m`
- **Documentation**: `../documentation/Quad_Hexacopter_6DOF_Report.pdf`

