%% Post-Process Simulation Results
% Generates plots and analysis from 6DOF quadcopter simulation
% Output files saved to results/ directory
%
% Requires: Simulink simulation to be completed with sim_log saved
%
% Author: Sewon Lee
% Date: 2026

clear all; close all; clc;

fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║    POST-PROCESSING 6DOF SIMULATION RESULTS             ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

%% Load Simulation Data
fprintf('[1] Loading simulation data...\n');

if isfile('simulation_workspace.mat')
    load('simulation_workspace.mat');
    fprintf('✓ Loaded simulation_workspace.mat\n');
else
    fprintf('✗ Error: simulation_workspace.mat not found\n');
    fprintf('  Run initialize_simulation.m first\n');
    return;
end

% Create results directory if it doesn't exist
if ~isfolder('results')
    mkdir('results');
end

fprintf('\n');

%% Plot 1: Position Response
fprintf('[2] Generating position response plot...\n');

figure('Name', 'Position Response', 'NumberTitle', 'off', 'Position', [100 100 1000 700]);

% Plot position components
subplot(3,1,1);
if ~isempty(sim_log.pos)
    t = sim_log.t;
    pos = sim_log.pos;
    
    plot(t, pos(:,1), 'b-', 'LineWidth', 2, 'DisplayName', 'X actual');
    hold on;
    plot(t, ref_trajectory.pos(1)*ones(size(t)), 'b--', 'LineWidth', 1.5, 'DisplayName', 'X desired');
    grid on; grid minor;
    ylabel('X Position (m)', 'FontSize', 11);
    legend('show', 'Location', 'best');
    title('Position Response - Quadcopter 6DOF Simulation', 'FontSize', 12, 'FontWeight', 'bold');
end

subplot(3,1,2);
if ~isempty(sim_log.pos)
    plot(t, pos(:,2), 'g-', 'LineWidth', 2, 'DisplayName', 'Y actual');
    hold on;
    plot(t, ref_trajectory.pos(2)*ones(size(t)), 'g--', 'LineWidth', 1.5, 'DisplayName', 'Y desired');
    grid on; grid minor;
    ylabel('Y Position (m)', 'FontSize', 11);
    legend('show', 'Location', 'best');
end

subplot(3,1,3);
if ~isempty(sim_log.pos)
    plot(t, pos(:,3), 'r-', 'LineWidth', 2, 'DisplayName', 'Z actual');
    hold on;
    plot(t, ref_trajectory.pos(3)*ones(size(t)), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Z desired');
    grid on; grid minor;
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Z Position (m)', 'FontSize', 11);
    legend('show', 'Location', 'best');
end

saveas(gcf, 'results/position_response.png');
fprintf('✓ Saved: results/position_response.png\n');

%% Plot 2: Attitude Response
fprintf('[3] Generating attitude response plot...\n');

figure('Name', 'Attitude Response', 'NumberTitle', 'off', 'Position', [100 100 1000 700]);

subplot(3,1,1);
if ~isempty(sim_log.euler)
    t = sim_log.t;
    euler = sim_log.euler;
    
    plot(t, rad2deg(euler(:,1)), 'b-', 'LineWidth', 2, 'DisplayName', 'Roll actual');
    hold on;
    plot(t, rad2deg(ref_trajectory.euler(1))*ones(size(t)), 'b--', 'LineWidth', 1.5, 'DisplayName', 'Roll desired');
    grid on; grid minor;
    ylabel('Roll (deg)', 'FontSize', 11);
    legend('show', 'Location', 'best');
    title('Attitude Response - Euler Angles', 'FontSize', 12, 'FontWeight', 'bold');
end

subplot(3,1,2);
if ~isempty(sim_log.euler)
    plot(t, rad2deg(euler(:,2)), 'g-', 'LineWidth', 2, 'DisplayName', 'Pitch actual');
    hold on;
    plot(t, rad2deg(ref_trajectory.euler(2))*ones(size(t)), 'g--', 'LineWidth', 1.5, 'DisplayName', 'Pitch desired');
    grid on; grid minor;
    ylabel('Pitch (deg)', 'FontSize', 11);
    legend('show', 'Location', 'best');
end

subplot(3,1,3);
if ~isempty(sim_log.euler)
    plot(t, rad2deg(euler(:,3)), 'r-', 'LineWidth', 2, 'DisplayName', 'Yaw actual');
    hold on;
    plot(t, rad2deg(ref_trajectory.euler(3))*ones(size(t)), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Yaw desired');
    grid on; grid minor;
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Yaw (deg)', 'FontSize', 11);
    legend('show', 'Location', 'best');
end

saveas(gcf, 'results/attitude_response.png');
fprintf('✓ Saved: results/attitude_response.png\n');

%% Plot 3: Motor Speeds
fprintf('[4] Generating motor speeds plot...\n');

figure('Name', 'Motor Speeds', 'NumberTitle', 'off', 'Position', [100 100 1000 500]);

if ~isempty(sim_log.motor_speeds)
    t = sim_log.t;
    motor_speeds = sim_log.motor_speeds;
    
    plot(t, motor_speeds(:,1), 'LineWidth', 2, 'DisplayName', 'Motor 1 (FR)');
    hold on;
    plot(t, motor_speeds(:,2), 'LineWidth', 2, 'DisplayName', 'Motor 2 (FL)');
    plot(t, motor_speeds(:,3), 'LineWidth', 2, 'DisplayName', 'Motor 3 (RL)');
    plot(t, motor_speeds(:,4), 'LineWidth', 2, 'DisplayName', 'Motor 4 (RR)');
    
    if exist('omega_hover', 'var')
        yline(omega_hover, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Hover Speed');
    end
    
    grid on; grid minor;
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Motor Speed (rad/s)', 'FontSize', 11);
    title('Motor Speed Commands vs Time', 'FontSize', 12, 'FontWeight', 'bold');
    legend('show', 'Location', 'best');
end

saveas(gcf, 'results/motor_speeds.png');
fprintf('✓ Saved: results/motor_speeds.png\n');

%% Plot 4: Control Inputs
fprintf('[5] Generating control inputs plot...\n');

figure('Name', 'Control Inputs', 'NumberTitle', 'off', 'Position', [100 100 1000 700]);

subplot(2,1,1);
if ~isempty(sim_log.thrust)
    t = sim_log.t;
    thrust = sim_log.thrust;
    
    plot(t, thrust, 'LineWidth', 2, 'Color', [1 0.5 0]);
    grid on; grid minor;
    ylabel('Thrust (N)', 'FontSize', 11);
    title('Vertical Thrust Command', 'FontSize', 12, 'FontWeight', 'bold');
    ylim([0 max(thrust)*1.1]);
end

subplot(2,1,2);
if ~isempty(sim_log.torques)
    t = sim_log.t;
    torques = sim_log.torques;
    
    plot(t, torques(:,1), 'LineWidth', 2, 'DisplayName', 'τx (Roll)');
    hold on;
    plot(t, torques(:,2), 'LineWidth', 2, 'DisplayName', 'τy (Pitch)');
    plot(t, torques(:,3), 'LineWidth', 2, 'DisplayName', 'τz (Yaw)');
    
    grid on; grid minor;
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Torque (N·m)', 'FontSize', 11);
    title('Moment Commands', 'FontSize', 12, 'FontWeight', 'bold');
    legend('show', 'Location', 'best');
end

saveas(gcf, 'results/control_inputs.png');
fprintf('✓ Saved: results/control_inputs.png\n');

%% Compute Performance Metrics
fprintf('\n[6] Computing performance metrics...\n');

if ~isempty(sim_log.pos) && ~isempty(sim_log.t)
    t = sim_log.t;
    pos = sim_log.pos;
    
    % Allow 2 second settling time
    settle_idx = find(t >= 2, 1);
    if ~isempty(settle_idx)
        settle_time = 2;
        pos_settle = pos(settle_idx:end, :);
        
        % Position error
        pos_error_x = abs(pos_settle(:,1) - ref_trajectory.pos(1));
        pos_error_y = abs(pos_settle(:,2) - ref_trajectory.pos(2));
        pos_error_z = abs(pos_settle(:,3) - ref_trajectory.pos(3));
        
        fprintf('  Position Tracking Performance (after %.1f s settling):\n', settle_time);
        fprintf('    X-axis RMS error: %.4f m (max: %.4f m)\n', sqrt(mean(pos_error_x.^2)), max(pos_error_x));
        fprintf('    Y-axis RMS error: %.4f m (max: %.4f m)\n', sqrt(mean(pos_error_y.^2)), max(pos_error_y));
        fprintf('    Z-axis RMS error: %.4f m (max: %.4f m)\n', sqrt(mean(pos_error_z.^2)), max(pos_error_z));
    end
end

if ~isempty(sim_log.motor_speeds)
    motor_speeds = sim_log.motor_speeds;
    if exist('omega_max', 'var')
        max_speed = max(max(motor_speeds));
        utilization = (max_speed / omega_max) * 100;
        fprintf('\n  Motor Performance:\n');
        fprintf('    Maximum motor speed: %.1f rad/s (%.1f%% of limit)\n', max_speed, utilization);
        fprintf('    Speed variation: %.1f rad/s (std dev among motors)\n', std(mean(motor_speeds)));
    end
end

fprintf('\n');

%% Summary
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║         POST-PROCESSING COMPLETE                      ║\n');
fprintf('╚═════════════════════════════════════════���══════════════╝\n\n');

fprintf('Generated files in results/ directory:\n');
fprintf('  • position_response.png     - Position tracking performance\n');
fprintf('  • attitude_response.png     - Euler angle responses\n');
fprintf('  • motor_speeds.png          - Motor speed profiles\n');
fprintf('  • control_inputs.png        - Thrust and torque commands\n\n');

fprintf('For detailed analysis, see: Quad_Hexacopter_6DOF_Report.docx\n\n');

end
