%% Lid-Driven Cavity Optimization using Surrogate Optimization
% Minimize maximum vorticity in secondary corner vortex
%
% Design Variables:
%   x(1) - Reynolds number: [100, 1000]
%   x(2) - Lid velocity: [0.5, 2.0] m/s
%
% Objective: Minimize max vorticity in bottom corner vortices

clear; clc; close all;

%% Add CFD solver to path
addpath('2D-Lid-Driven-Cavity-Flow-Incompressible-Navier-Stokes-Solver/functions/');

%% Define optimization problem bounds
lb = [100, 0.5];   % Lower bounds: Re_min, Ulid_min
ub = [1000, 2.0];  % Upper bounds: Re_max, Ulid_max

%% Surrogate Optimization Options
options = optimoptions('surrogateopt', ...
    'MaxFunctionEvaluations', 30, ...     % Limit evaluations (each ~15-20 sec)
    'PlotFcn', 'surrogateoptplot', ...    % Show progress plot
    'Display', 'iter', ...
    'UseParallel', false, ...             % Set true if Parallel Computing Toolbox available
    'MinSurrogatePoints', 10, ...         % Initial sampling points
    'InitialPoints', [400, 1.0; 200, 0.75; 800, 1.5]);  % Start with some known points

%% Run Surrogate Optimization
fprintf('=== Lid-Driven Cavity Surrogate Optimization ===\n');
fprintf('Design Variables:\n');
fprintf('  Reynolds number: [%.0f, %.0f]\n', lb(1), ub(1));
fprintf('  Lid velocity:    [%.2f, %.2f] m/s\n', lb(2), ub(2));
fprintf('  Max evaluations: %d\n', options.MaxFunctionEvaluations);
fprintf('\nStarting optimization (each CFD simulation ~15-20 seconds)...\n\n');

tic;
[x_opt, fval, exitflag, output] = surrogateopt(@lidDrivenCavityObjective, lb, ub, options);
totalTime = toc;

%% Display Results
fprintf('\n=== OPTIMIZATION RESULTS ===\n');
fprintf('Optimal Reynolds number: %.1f\n', x_opt(1));
fprintf('Optimal Lid velocity:    %.3f m/s\n', x_opt(2));
fprintf('Minimum corner vorticity: %.4f\n', fval);
fprintf('\nTotal optimization time: %.1f seconds (%.1f minutes)\n', totalTime, totalTime/60);
fprintf('Function evaluations: %d\n', output.funccount);

%% Visualize optimal solution
fprintf('\nRunning simulation at optimal point for visualization...\n');
visualizeCavitySolution(x_opt(1), x_opt(2));

%% Function to visualize the cavity solution
function visualizeCavitySolution(Re, Ulid)
    % Grid setup
    Nx = 64; Ny = 64;
    Lx = 1; Ly = 1;
    dx = Lx/Nx; dy = Ly/Ny;

    dt = min(0.005, 0.5 * dx^2 * Re);
    dt = max(dt, 0.001);
    nt = round(1000 + Re * 1.5);

    % Initialize and run
    u = zeros(Nx+1, Ny+2);
    v = zeros(Nx+2, Ny+1);

    for ii = 1:nt
        [u, v] = updateVelocityField_RK3_bctop(u, v, Nx, Ny, dx, dy, Re, dt, Ulid, 'dct');
    end

    % Calculate vorticity
    vorticity = (v(2:end,:) - v(1:end-1,:))/dx - (u(:,2:end) - u(:,1:end-1))/dy;

    % Velocity at cell centers
    uce = (u(1:end-1,2:end-1) + u(2:end,2:end-1))/2;
    vce = (v(2:end-1,1:end-1) + v(2:end-1,2:end))/2;
    speed = sqrt(uce.^2 + vce.^2);

    % Calculate max corner vorticity
    corner_fraction = 0.25;
    nx_corner = round(Nx * corner_fraction);
    ny_corner = round(Ny * corner_fraction);
    vort_BL = vorticity(1:nx_corner, 1:ny_corner);
    vort_BR = vorticity(end-nx_corner+1:end, 1:ny_corner);
    maxVort = max(abs([vort_BL(:); vort_BR(:)]));

    % Create grids
    xv = linspace(0, Lx, size(vorticity,1));
    yv = linspace(0, Ly, size(vorticity,2));
    [Xv, Yv] = ndgrid(xv, yv);

    xc = linspace(dx/2, Lx-dx/2, Nx);
    yc = linspace(dy/2, Ly-dy/2, Ny);
    [Xc, Yc] = ndgrid(xc, yc);

    % Plot
    figure('Position', [100 100 1200 450], 'Name', 'Optimal Lid-Driven Cavity Solution');

    subplot(1,3,1);
    contourf(Xv, Yv, vorticity, 50, 'LineStyle', 'none');
    colorbar;
    hold on;
    rectangle('Position', [0, 0, Lx*corner_fraction, Ly*corner_fraction], ...
        'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle', '--');
    rectangle('Position', [Lx*(1-corner_fraction), 0, Lx*corner_fraction, Ly*corner_fraction], ...
        'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle', '--');
    title('Vorticity Field');
    xlabel('x'); ylabel('y');
    colormap(gca, 'jet');
    axis equal tight;

    subplot(1,3,2);
    contourf(Xc, Yc, speed, 30, 'LineStyle', 'none');
    colorbar;
    hold on;
    skip = 4;
    quiver(Xc(1:skip:end,1:skip:end), Yc(1:skip:end,1:skip:end), ...
           uce(1:skip:end,1:skip:end), vce(1:skip:end,1:skip:end), 1.5, 'k');
    title('Velocity Magnitude');
    xlabel('x'); ylabel('y');
    axis equal tight;

    subplot(1,3,3);
    % Streamlines
    [startX, startY] = meshgrid(linspace(0.1,0.9,8), linspace(0.1,0.9,8));
    streamline(Xc', Yc', uce', vce', startX, startY);
    title('Streamlines');
    xlabel('x'); ylabel('y');
    axis equal tight;
    xlim([0 1]); ylim([0 1]);

    sgtitle(sprintf('Optimal Solution: Re=%.0f, U_{lid}=%.2f m/s, Max Corner Vorticity=%.4f', ...
        Re, Ulid, maxVort), 'FontWeight', 'bold', 'FontSize', 12);
end
