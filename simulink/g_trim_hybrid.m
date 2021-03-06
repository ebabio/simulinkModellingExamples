%% Trim model for the Duffing system with a discrete controller

%% Setup workspace
clear
clc

%% Initialize system

% define the duffing system
f_init_hybrid;

%% Trim using Operating Point
% following the same method as in "c_trim_model.m"

% operating point can be generated using the steady-state manager and exported here
% and then trimmed in batches for example.

% get an operating point from the current state
op0 = operspec(modelCL);

% edit operating point
% it can be done graphically on 'Steady State Manager' Simulink App (SSM), 
% function code has been generated by SSM.
opspec = trim_constraints(op0);

% find operating point
opTrim = findop(modelCL, opspec, trimopts);
% there is a big difference between the reference command and the state due
% to the instability of the system and the gain values. Increasing the
% error state on the LQR reduces this error.

%% Trim condition
% autogenerated from Steady State Manager

% should trim using the input to cancel derivative

function opspec = trim_constraints(opspec)
% Set the constraints on the states in the model.
% - The defaults for all states are Known = false, SteadyState = true,
%   Min = -Inf, Max = Inf, dxMin = -Inf, and dxMax = Inf.

% State (1) - model_closedloop/adc
% - Default model initial conditions are used to initialize optimization.

% State (2) - model_closedloop/duffing/duffingSystem/integrator/xDotIntegrator
% - Default model initial conditions are used to initialize optimization.
paren = @(x, varargin) x(varargin{:}); % anonymous function to index an array through a function
index = paren(getStateIndex_hotfix(opspec,'x'), 1);
opspec.States(index).Min = [0.1;-Inf];
opspec.States(index).Max = [0.5;Inf];

% Set the constraints on the inputs in the model.
% - The defaults for all inputs are Known = false, Min = -Inf, and
% Max = Inf.

% Input (1) - model_closedloop/r
% - Default model initial conditions are used to initialize optimization.

% Set the constraints on the outputs in the model.
% - The defaults for all outputs are Known = false, Min = -Inf, and
% Max = Inf.

% Output (1) - model_closedloop/x
% - Default model initial conditions are used to initialize optimization.

end