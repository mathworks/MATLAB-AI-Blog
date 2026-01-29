# MATLAB Problem-Based Optimization Skill

## Overview

This skill guides you through solving optimization problems in MATLAB using the **problem-based workflow** from the Optimization Toolbox. This approach uses symbolic variable definitions and expressions for intuitive problem formulation.

## When to Use This Skill

Use the problem-based approach when:
- Solving linear, quadratic, or nonlinear optimization problems
- The user describes an optimization problem with objectives and constraints
- You need to minimize/maximize a quantity subject to bounds and constraints
- Engineering design optimization (beam sizing, resource allocation, etc.)

## Problem-Based Workflow Steps

### Step 1: Create an Optimization Problem Object

```matlab
% For minimization (default)
prob = optimproblem;

% For maximization
prob = optimproblem('ObjectiveSense', 'maximize');
```

### Step 2: Define Optimization Variables

Use `optimvar` to create named symbolic variables with bounds and types:

```matlab
% Continuous variable with bounds
x = optimvar('x', 'LowerBound', 0, 'UpperBound', 10);

% Vector of variables
y = optimvar('y', 5, 'LowerBound', 0);

% Matrix of variables
z = optimvar('z', 3, 4, 'LowerBound', -1, 'UpperBound', 1);

% Integer variables
n = optimvar('n', 'Type', 'integer', 'LowerBound', 0);

% Binary variables
b = optimvar('b', 10, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
```

### Step 3: Define the Objective Function

Express the objective as a mathematical expression using the variables:

```matlab
% Simple objective
prob.Objective = 2*x + 3*y;

% Quadratic objective
prob.Objective = x^2 + y^2;

% Sum over arrays
prob.Objective = sum(cost .* quantities);

% For complex nonlinear functions, use fcn2optimexpr
prob.Objective = fcn2optimexpr(@myFunction, x, y);
```

### Step 4: Add Constraints

Specify constraints using comparison operators:

```matlab
% Equality constraint
prob.Constraints.equality = x + y == 10;

% Inequality constraints (<=, >=)
prob.Constraints.upper = x + 2*y <= 20;
prob.Constraints.lower = x - y >= 0;

% Multiple constraints at once
prob.Constraints.bounds = [x >= 0; y >= 0; x + y <= 100];

% Named constraint arrays
prob.Constraints.demand = supply >= demand;
```

### Step 5: Set Initial Point (for Nonlinear Problems)

Nonlinear problems require an initial guess:

```matlab
% Create initial point structure matching variable names
x0.x = 5;
x0.y = 3;

% For array variables
x0.z = zeros(3, 4);
```

### Step 6: Solve the Problem

```matlab
% Linear/quadratic problems (no initial point needed)
[sol, fval, exitflag, output] = solve(prob);

% Nonlinear problems (initial point required)
[sol, fval, exitflag, output] = solve(prob, x0);

% With custom options
options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');
[sol, fval] = solve(prob, x0, 'Options', options);
```

### Step 7: Extract and Display Results

```matlab
% Access solution values
optimal_x = sol.x;
optimal_y = sol.y;

% Display results
fprintf('Optimal x: %.4f\n', sol.x);
fprintf('Optimal objective: %.4f\n', fval);
fprintf('Exit flag: %d\n', exitflag);
```

## Complete Example: Cantilever Beam Optimization

```matlab
%% Problem Parameters
L = 5;              % Length [m]
P = 10e3;           % Load [N]
E = 200e9;          % Young's modulus [Pa]
sigma_y = 250e6;    % Yield stress [Pa]
delta_max = 0.01;   % Max deflection [m]

%% Step 1: Create optimization problem
prob = optimproblem('ObjectiveSense', 'minimize');

%% Step 2: Define design variables
b = optimvar('b', 'LowerBound', 0.05, 'UpperBound', 0.20);  % Width [m]
h = optimvar('h', 'LowerBound', 0.10, 'UpperBound', 0.50);  % Height [m]

%% Step 3: Define objective (minimize cross-sectional area)
prob.Objective = b * h;

%% Step 4: Add constraints
% Moment of inertia: I = b*h^3/12
% Deflection: delta = P*L^3/(3*E*I) <= delta_max
% Stress: sigma = 6*P*L/(b*h^2) <= sigma_y

% Use fcn2optimexpr for nonlinear constraints
deflection_expr = fcn2optimexpr(@(b,h) P*L^3/(3*E*(b*h^3/12)), b, h);
stress_expr = fcn2optimexpr(@(b,h) 6*P*L/(b*h^2), b, h);

prob.Constraints.deflection = deflection_expr <= delta_max;
prob.Constraints.stress = stress_expr <= sigma_y;

%% Step 5: Set initial point
x0.b = 0.10;
x0.h = 0.25;

%% Step 6: Solve
[sol, fval, exitflag] = solve(prob, x0);

%% Step 7: Display results
fprintf('Optimal width:  %.2f mm\n', sol.b * 1000);
fprintf('Optimal height: %.2f mm\n', sol.h * 1000);
fprintf('Optimal area:   %.2f mm²\n', fval * 1e6);
```

## Useful Functions

| Function | Purpose |
|----------|---------|
| `optimproblem` | Create optimization problem container |
| `optimvar` | Define optimization variables |
| `optimexpr` | Create optimization expressions |
| `fcn2optimexpr` | Convert functions to optimization expressions |
| `solve` | Solve the optimization problem |
| `show(prob)` | Display problem formulation |
| `write(prob)` | Write problem to file |
| `evaluate` | Evaluate expressions at a point |
| `infeasibility` | Check constraint violations |

## Tips and Best Practices

1. **Use descriptive variable names**: `width`, `height` instead of `x1`, `x2`

2. **Check problem formulation**: Use `show(prob)` before solving

3. **Verify feasibility**: Use `infeasibility(prob.Constraints, sol)` after solving

4. **Handle nonlinear functions**: Always use `fcn2optimexpr` for functions not directly supported

5. **Provide good initial points**: For nonlinear problems, initial guess affects convergence

6. **Scale variables**: Keep variable magnitudes similar (use mm instead of m if needed)

7. **Check exit flags**:
   - `1` = converged successfully
   - `0` = max iterations reached
   - Negative = problem (infeasible, unbounded, etc.)

## Common Patterns

### Multi-objective (Weighted Sum)
```matlab
prob.Objective = w1*objective1 + w2*objective2;
```

### Parameter Sweeps
```matlab
for param = param_values
    prob.Constraints.limit = expr <= param;
    sol = solve(prob, x0);
    results(end+1) = sol;
end
```

### Discrete Choices
```matlab
choice = optimvar('choice', n, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
prob.Constraints.one_choice = sum(choice) == 1;
```

## References

- [Problem-Based Optimization Workflow](https://www.mathworks.com/help/optim/ug/problem-based-workflow.html)
- [Optimization Toolbox Documentation](https://www.mathworks.com/help/optim/)
