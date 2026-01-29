%% Cantilever Beam Optimization
% Minimize cross-sectional area subject to deflection and stress constraints
%
% Problem setup:
%   - Rectangular cross-section beam with width (b) and height (h)
%   - Fixed at one end, tip load P at free end
%   - Minimize area A = b*h
%   - Subject to: tip deflection <= 10mm, max stress <= yield stress

clear; clc;

%% Problem Parameters
L = 5;              % Beam length [m]
P = 10e3;           % Tip load [N] (10 kN)
E = 200e9;          % Young's modulus [Pa] (200 GPa)
sigma_y = 250e6;    % Yield stress [Pa] (250 MPa)
delta_max = 0.01;   % Max allowable deflection [m] (10 mm)

% Store parameters in a structure for passing to functions
params.L = L;
params.P = P;
params.E = E;
params.sigma_y = sigma_y;
params.delta_max = delta_max;

%% Design Variable Bounds
% x(1) = b (width),  x(2) = h (height)
lb = [0.05, 0.10];   % Lower bounds [m]: b >= 50mm, h >= 100mm
ub = [0.20, 0.50];   % Upper bounds [m]: b <= 200mm, h <= 500mm

%% Initial Guess (middle of bounds)
x0 = [0.125, 0.30];  % Starting point: b=125mm, h=300mm

%% Optimization Setup
% Objective: minimize area A = b * h
objective = @(x) x(1) * x(2);

% Nonlinear constraints
nonlcon = @(x) beam_constraints(x, params);

%% Solver Options
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'Algorithm', 'sqp', ...
    'MaxFunctionEvaluations', 1000, ...
    'OptimalityTolerance', 1e-8, ...
    'StepTolerance', 1e-10);

%% Solve the Optimization Problem
fprintf('=== Cantilever Beam Optimization ===\n\n');
fprintf('Parameters:\n');
fprintf('  Length L = %.1f m\n', L);
fprintf('  Tip Load P = %.1f kN\n', P/1e3);
fprintf('  Young''s Modulus E = %.0f GPa\n', E/1e9);
fprintf('  Yield Stress = %.0f MPa\n', sigma_y/1e6);
fprintf('  Max Deflection = %.0f mm\n\n', delta_max*1e3);

fprintf('Design Variable Bounds:\n');
fprintf('  Width b:  [%.0f, %.0f] mm\n', lb(1)*1e3, ub(1)*1e3);
fprintf('  Height h: [%.0f, %.0f] mm\n\n', lb(2)*1e3, ub(2)*1e3);

fprintf('Starting optimization...\n\n');

[x_opt, fval, exitflag, output] = fmincon(objective, x0, [], [], [], [], lb, ub, nonlcon, options);

%% Extract and Display Results
b_opt = x_opt(1);
h_opt = x_opt(2);
A_opt = fval;

% Calculate final constraint values
I_opt = (b_opt * h_opt^3) / 12;
delta_opt = (P * L^3) / (3 * E * I_opt);
sigma_opt = (6 * P * L) / (b_opt * h_opt^2);

fprintf('\n=== OPTIMIZATION RESULTS ===\n\n');
fprintf('Exit Flag: %d (%s)\n', exitflag, get_exit_message(exitflag));
fprintf('Iterations: %d\n', output.iterations);
fprintf('Function Evaluations: %d\n\n', output.funcCount);

fprintf('Optimal Design:\n');
fprintf('  Width b  = %.2f mm\n', b_opt*1e3);
fprintf('  Height h = %.2f mm\n', h_opt*1e3);
fprintf('  Area A   = %.2f mm² = %.4f m²\n\n', A_opt*1e6, A_opt);

fprintf('Constraint Satisfaction:\n');
fprintf('  Tip Deflection: %.4f mm (limit: %.1f mm) - %s\n', ...
    delta_opt*1e3, delta_max*1e3, check_constraint(delta_opt, delta_max));
fprintf('  Max Stress:     %.2f MPa (limit: %.0f MPa) - %s\n', ...
    sigma_opt/1e6, sigma_y/1e6, check_constraint(sigma_opt, sigma_y));

fprintf('\nSafety Factors:\n');
fprintf('  Deflection: %.2f\n', delta_max/delta_opt);
fprintf('  Stress:     %.2f\n', sigma_y/sigma_opt);

%% Visualization
figure('Name', 'Cantilever Beam Optimization', 'Position', [100, 100, 1000, 400]);

% Plot 1: Cross-section
subplot(1, 3, 1);
rectangle('Position', [-b_opt/2*1e3, -h_opt/2*1e3, b_opt*1e3, h_opt*1e3], ...
    'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'k', 'LineWidth', 2);
axis equal;
xlim([-150, 150]);
ylim([-300, 300]);
xlabel('Width [mm]');
ylabel('Height [mm]');
title(sprintf('Optimal Cross-Section\nb = %.1f mm, h = %.1f mm', b_opt*1e3, h_opt*1e3));
grid on;

% Plot 2: Beam deflection shape
subplot(1, 3, 2);
x_beam = linspace(0, L, 100);
% Deflection curve for cantilever with tip load: delta(x) = Px²(3L-x)/(6EI)
delta_curve = (P * x_beam.^2 .* (3*L - x_beam)) / (6 * E * I_opt);
plot(x_beam, delta_curve*1e3, 'b-', 'LineWidth', 2);
hold on;
plot([0, L], [0, 0], 'k--', 'LineWidth', 1);
plot(L, delta_opt*1e3, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
yline(delta_max*1e3, 'r--', 'LineWidth', 1.5);
xlabel('Position along beam [m]');
ylabel('Deflection [mm]');
title('Beam Deflection Shape');
legend('Deflection', 'Undeformed', 'Tip deflection', 'Max allowed', 'Location', 'northwest');
grid on;

% Plot 3: Constraint space visualization
subplot(1, 3, 3);
[B, H] = meshgrid(linspace(lb(1), ub(1), 100), linspace(lb(2), ub(2), 100));
Area = B .* H;

% Calculate constraints over the grid
Delta = (P * L^3) ./ (3 * E * (B .* H.^3 / 12));
Sigma = (6 * P * L) ./ (B .* H.^2);

% Feasible region
feasible = (Delta <= delta_max) & (Sigma <= sigma_y);
Area_plot = Area * 1e6;  % Convert to mm²
Area_plot(~feasible) = NaN;

contourf(B*1e3, H*1e3, Area_plot, 20);
colorbar;
hold on;
% Deflection constraint boundary
contour(B*1e3, H*1e3, Delta*1e3, [delta_max*1e3, delta_max*1e3], 'r-', 'LineWidth', 2);
% Stress constraint boundary
contour(B*1e3, H*1e3, Sigma/1e6, [sigma_y/1e6, sigma_y/1e6], 'm-', 'LineWidth', 2);
% Optimal point
plot(b_opt*1e3, h_opt*1e3, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2);
xlabel('Width b [mm]');
ylabel('Height h [mm]');
title('Feasible Design Space (Area in mm²)');
legend('', 'Deflection limit', 'Stress limit', 'Optimum', 'Location', 'northwest');

sgtitle('Cantilever Beam Optimization Results', 'FontSize', 14, 'FontWeight', 'bold');

%% Local Functions
function [c, ceq] = beam_constraints(x, params)
    % Nonlinear inequality constraints: c(x) <= 0
    % Nonlinear equality constraints: ceq(x) = 0

    b = x(1);  % width
    h = x(2);  % height

    % Moment of inertia for rectangular section
    I = (b * h^3) / 12;

    % Tip deflection constraint: delta <= delta_max
    % delta = PL³/(3EI) for cantilever with tip load
    delta = (params.P * params.L^3) / (3 * params.E * I);
    c1 = delta - params.delta_max;  % Must be <= 0

    % Stress constraint: sigma <= sigma_y
    % sigma = Mc/I = (PL)(h/2) / I = 6PL/(bh²) for rectangular section
    sigma = (6 * params.P * params.L) / (b * h^2);
    c2 = sigma - params.sigma_y;  % Must be <= 0

    c = [c1; c2];
    ceq = [];
end

function msg = get_exit_message(flag)
    switch flag
        case 1
            msg = 'First-order optimality satisfied';
        case 0
            msg = 'Maximum iterations reached';
        case -1
            msg = 'Stopped by output function';
        case -2
            msg = 'No feasible point found';
        otherwise
            msg = 'See documentation';
    end
end

function status = check_constraint(value, limit)
    if value <= limit
        status = 'SATISFIED';
    else
        status = 'VIOLATED';
    end
end
