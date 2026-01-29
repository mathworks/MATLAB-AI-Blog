function maxVorticity = lidDrivenCavityObjective(x)
%LIDDRIVENCAVITYOBJECTIVE Objective function for lid-driven cavity optimization
%   Runs CFD simulation and returns maximum vorticity in secondary corner vortex
%
%   Input:
%       x(1) - Reynolds number (100-1000)
%       x(2) - Lid velocity (0.5-2.0 m/s)
%
%   Output:
%       maxVorticity - Maximum vorticity magnitude in bottom corner regions

    Re = x(1);
    Ulid = x(2);

    % Grid setup (moderate resolution for reasonable computation time)
    Nx = 64; Ny = 64;
    Lx = 1; Ly = 1;
    dx = Lx/Nx;
    dy = Ly/Ny;

    % Time stepping parameters
    % Smaller dt for stability at higher Re
    dt = min(0.005, 0.5 * dx^2 * Re);  % CFL-like condition
    dt = max(dt, 0.001);  % Don't go too small

    % More iterations for higher Re to reach steady state
    nt = round(1000 + Re * 1.5);

    % Initialize velocity fields
    u = zeros(Nx+1, Ny+2);
    v = zeros(Nx+2, Ny+1);

    % Run simulation using RK3 method (more stable)
    for ii = 1:nt
        [u, v] = updateVelocityField_RK3_bctop(u, v, Nx, Ny, dx, dy, Re, dt, Ulid, 'dct');
    end

    % Calculate vorticity: omega = dv/dx - du/dy
    vorticity = (v(2:end,:) - v(1:end-1,:))/dx - (u(:,2:end) - u(:,1:end-1))/dy;

    % Define corner regions for secondary vortices (bottom 25% of domain)
    corner_fraction = 0.25;
    nx_corner = round(Nx * corner_fraction);
    ny_corner = round(Ny * corner_fraction);

    % Bottom-left corner vorticity
    vort_BL = vorticity(1:nx_corner, 1:ny_corner);

    % Bottom-right corner vorticity
    vort_BR = vorticity(end-nx_corner+1:end, 1:ny_corner);

    % Maximum vorticity magnitude in secondary vortices
    maxVorticity = max(abs([vort_BL(:); vort_BR(:)]));
end
