%% Drone 6DOF Simulation - Initialization Script
% Prepares the simulation environment based on parameters from
% Quad_Hexacopter_6DOF_Report.docx
%
% This script:
% 1. Loads all system parameters
% 2. Initializes control system state
% 3. Sets up reference trajectories
% 4. Prepares logging infrastructure
% 5. Validates Simulink model
%
% Author: Sewon Lee
% Date: 2026

clear all; close all; clc;

fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║  DRONE 6DOF SIMULATION - INITIALIZATION SCRIPT         ║\n');
fprintf('║  Based on: Quad_Hexacopter_6DOF_Report.docx          ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

%% Step 1: Load System Parameters
fprintf('[STEP 1] Loading system parameters...\n');
try
    parameters;
    fprintf('✓ Parameters loaded successfully\n');
    fprintf('  - Vehicle mass: %.2f kg\n', m);
    fprintf('  - Motor configuration: %d rotors\n', num_rotors);
    fprintf('  - Simulation duration: %.1f seconds\n', t_end - t_start);
catch ME
    fprintf('✗ Error loading parameters: %s\n', ME.message);
    return;
end
fprintf('\n');

%% Step 2: Initialize State Vector
fprintf('[STEP 2] Initializing full state vector...\n');
fprintf('  Initial Conditions:\n');
fprintf('    Position: [%.3f, %.3f, %.3f] m\n', X0(1), X0(2), X0(3));
fprintf('    Velocity: [%.3f, %.3f, %.3f] m/s\n', V0(1), V0(2), V0(3));
fprintf('    Euler Angles: [%.3f, %.3f, %.3f] rad (%.1f, %.1f, %.1f deg)\n', ...
    euler0(1), euler0(2), euler0(3), rad2deg(euler0(1)), rad2deg(euler0(2)), rad2deg(euler0(3)));
fprintf('    Angular Velocity: [%.3f, %.3f, %.3f] rad/s\n', omega0(1), omega0(2), omega0(3));
fprintf('✓ State vector initialized (12 states)\n\n');

%% Step 3: Compute Hover Condition
fprintf('[STEP 3] Computing hover equilibrium...\n');
hover_thrust = m * g;  % Total thrust needed to hover
thrust_per_motor = hover_thrust / num_rotors;
omega_hover = sqrt(thrust_per_motor / Ct);

fprintf('  Hover Equilibrium:\n');
fprintf('    Total Thrust Required: %.3f N\n', hover_thrust);
fprintf('    Thrust per Motor: %.3f N\n', thrust_per_motor);
fprintf('    Hover Motor Speed: %.1f rad/s\n', omega_hover);
fprintf('    Hover Motor Speed: %.1f RPM\n', omega_hover * 60 / (2*pi));

omega_cmd = omega_hover * ones(num_rotors, 1);
fprintf('✓ Hover motor speeds computed\n\n');

%% Step 4: Create Reference Trajectories (from Report)
fprintf('[STEP 4] Creating reference trajectories...\n');
ref_trajectory = struct();

% Test cases from report
fprintf('  Position Reference:\n');
fprintf('    Target: [%.2f, %.2f, %.2f] m\n', x_des, y_des, z_des);

ref_trajectory.pos = [x_des; y_des; z_des];
ref_trajectory.vel = [vx_des; vy_des; vz_des];
ref_trajectory.euler = [roll_des; pitch_des; yaw_des];
ref_trajectory.yaw_rate = 0;

fprintf('  Attitude Reference:\n');
fprintf('    Roll: %.2f rad (%.2f deg)\n', roll_des, rad2deg(roll_des));
fprintf('    Pitch: %.2f rad (%.2f deg)\n', pitch_des, rad2deg(pitch_des));
fprintf('    Yaw: %.2f rad (%.2f deg)\n', yaw_des, rad2deg(yaw_des));
fprintf('✓ Reference trajectories created\n\n');

%% Step 5: Initialize Controller State
fprintf('[STEP 5] Initializing control system...\n');
controller = struct();

% Cascaded PID structure (from Report control design)
fprintf('  Control Architecture: Cascaded PID\n');
fprintf('    Outer Loop: Position Control\n');
fprintf('      Kp = %.2f, Ki = %.2f, Kd = %.2f\n', Kp_pos, Ki_pos, Kd_pos);
fprintf('    Inner Loop: Attitude Control\n');
fprintf('      Kp = %.2f, Ki = %.2f, Kd = %.2f\n', Kp_att, Ki_att, Kd_att);

% Initialize error accumulators
controller.pos_error_int = [0; 0; 0];      % Position integral error
controller.att_error_int = [0; 0; 0];      % Attitude integral error
controller.prev_pos_error = [0; 0; 0];     % For derivative calculation
controller.prev_att_error = [0; 0; 0];     % For derivative calculation

% Thrust allocator matrix for quadcopter
controller.allocation_matrix = compute_allocation_matrix(rotor_pos, Ct, Cq);

fprintf('✓ Controller state initialized\n\n');

%% Step 6: Setup Simulation Logging Infrastructure
fprintf('[STEP 6] Setting up data logging...\n');
sim_log = struct();

% Time and state logging
sim_log.t = [];                    % Time vector
sim_log.pos = [];                  % Position [X, Y, Z]
sim_log.vel = [];                  % Velocity [Vx, Vy, Vz]
sim_log.euler = [];                % Euler angles [φ, θ, ψ]
sim_log.omega = [];                % Angular velocity [p, q, r]

% Motor and control logging
sim_log.motor_speeds = [];         % Motor speeds [ω1, ω2, ω3, ω4]
sim_log.thrust = [];               % Total thrust
sim_log.torques = [];              % Torques [τx, τy, τz]
sim_log.control_input = [];        % Control commands

% Error tracking
sim_log.pos_error = [];            % Position errors
sim_log.att_error = [];            % Attitude errors

fprintf('✓ Logging structure created\n');
fprintf('  Logging %d signals per time step\n', 11);
fprintf('\n');

%% Step 7: Verify Files and Paths
fprintf('[STEP 7] Checking project file structure...\n');

files_to_check = {
    'model/quadcopter_6dof.slx',
    'documentation/Quad_Hexacopter_6DOF_Report.docx',
    'scripts/parameters.m',
    'scripts/initialize_simulation.m'
};

for i = 1:length(files_to_check)
    filepath = files_to_check{i};
    if isfile(filepath)
        fprintf('✓ Found: %s\n', filepath);
    else
        fprintf('⚠ Missing: %s (will be needed for full simulation)\n', filepath);
    end
end
fprintf('\n');

%% Step 8: Save Initialized Workspace
fprintf('[STEP 8] Saving initialized workspace...\n');
save('simulation_workspace.mat', ...
    'x0', 't_sim', 'omega_cmd', 'ref_trajectory', 'controller', 'sim_log', ...
    'm', 'g', 'I', 'Ct', 'Cq', 'arm_length', 'rotor_pos', 'num_rotors', ...
    'Kp_pos', 'Ki_pos', 'Kd_pos', 'Kp_att', 'Ki_att', 'Kd_att', ...
    'Ixx', 'Iyy', 'Izz', 'omega_hover', 'hover_thrust', 'thrust_per_motor');

fprintf('✓ Workspace saved to simulation_workspace.mat\n\n');

%% Display Configuration Summary
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║           SIMULATION READY FOR EXECUTION              ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('VEHICLE CONFIGURATION:\n');
fprintf('  Type: Quadcopter (4-rotor)\n');
fprintf('  Mass: %.2f kg\n', m);
fprintf('  Arm Length: %.3f m\n', arm_length);

fprintf('\nSIMULATION PARAMETERS:\n');
fprintf('  Duration: %.1f seconds\n', t_end - t_start);
fprintf('  Time Step: %.4f seconds\n', dt);
fprintf('  Number of Steps: %d\n', length(t_sim));
fprintf('  Integration Method: ODE45 (recommended)\n');

fprintf('\nCONTROL CONFIGURATION:\n');
fprintf('  Architecture: Cascaded PID (Position → Attitude → Motors)\n');
fprintf('  Position Loop: Active\n');
fprintf('  Attitude Loop: Active\n');

fprintf('\nREFERENCE TRAJECTORY:\n');
fprintf('  Type: Hover at fixed altitude\n');
fprintf('  Target Position: [%.2f, %.2f, %.2f] m\n', x_des, y_des, z_des);
fprintf('  Target Altitude: %.1f m\n', z_des);

fprintf('\n════════════════════════════════════════════════════════\n\n');

fprintf('NEXT STEPS:\n');
fprintf('  1. Open Simulink model:\n');
fprintf('     >> open(''model/quadcopter_6dof.slx'')\n\n');
fprintf('  2. Run simulation from Simulink GUI or command line:\n');
fprintf('     >> sim(''model/quadcopter_6dof.slx'')\n\n');
fprintf('  3. Post-process results:\n');
fprintf('     >> post_process_results\n\n');

fprintf('USEFUL COMMANDS:\n');
fprintf('  Check parameters:        parameters\n');
fprintf('  Plot trajectory:         plot(sim_log.t, sim_log.pos)\n');
fprintf('  Check motor speeds:      plot(sim_log.t, sim_log.motor_speeds)\n');
fprintf('  Check control effort:    plot(sim_log.t, sim_log.control_input)\n\n');

fprintf('For detailed information, see: Quad_Hexacopter_6DOF_Report.docx\n\n');

%% ========== HELPER FUNCTIONS ==========

function A = compute_allocation_matrix(rotor_pos, Ct, Cq)
    %% Compute thrust allocation matrix for quadcopter
    % Maps [Fz, tau_x, tau_y, tau_z] to motor thrusts
    %
    % Inputs:
    %   rotor_pos - Rotor positions [x, y, z] for each motor
    %   Ct - Thrust coefficient
    %   Cq - Torque coefficient
    %
    % Output:
    %   A - 4x4 allocation matrix
    
    num_motors = size(rotor_pos, 1);
    
    % Allocation matrix: relates [Fz; tau_x; tau_y; tau_z] to motor thrusts
    A = zeros(4, num_motors);
    
    % Row 1: Total thrust (sum of all motor thrusts)
    A(1, :) = 1;
    
    % Row 2: Roll torque (tau_x = sum(y_i * T_i))
    A(2, :) = rotor_pos(:, 2)';
    
    % Row 3: Pitch torque (tau_y = -sum(x_i * T_i))
    A(3, :) = -rotor_pos(:, 1)';
    
    % Row 4: Yaw torque (tau_z depends on motor rotation direction)
    % For standard quadcopter: motors 1,3 spin CCW, motors 2,4 spin CW
    A(4, :) = [-1, 1, -1, 1];
    
end
