%%  Initialization script for the Duffing continuous system simulation

%% Setup workspace

clear
clc

% add files to path
filepath = fileparts(mfilename('fullpath'));
addpath(genpath(filepath));

%% Duffing system parameters
% Reusing the nomenclature from: http://mathworld.wolfram.com/DuffingDifferentialEquation.html

% duffing system
delta = 0;
beta = 1;
omega2 = -1;

% forcing term
gamma = 0;
omega = .01;
phi = 0;

%% Simulation parameters

% main sim parameters
dt = 1e-2;
x0 = [0; .5];
t_end = 10;

% auxiliary parameters
K = zeros(1,2); % no feedback
yMask = [1, 0]; % only output position

%% Load and setup model

% define model
model = 'model_openloop';

% terminate model if started
try
    feval(model, [],[],[],'term');
catch
end

% open model and dependencies
refMdls = find_mdlrefs(model);
for i=1:size(refMdls)
    load_system(refMdls{i})  
end

% model settings
% https://www.mathworks.com/help/simulink/slref/set_param.html
set_param(model, 'LoadExternalInput', 'off') % remove operating points
set_param(model, 'LoadInitialState', 'off')
set_param(model, 'Solver', 'FixedStepAuto', 'FixedStep', 'dt' )

% reference models settings
for i=1:size(refMdls)
    set_param(refMdls{i},'SaveFormat','Dataset');   
end

%% Simulate Model

% simulate
simOut0 = sim(model);

% Plot trajectory in phase portrait
xSim0 = simOut0.xout{1}.Values.Data';
f1 = figure(1);
clf reset
f1.Name=  'Model Sim';
f1.NumberTitle = 'off';
axis equal
hold on
plot(xSim0(1,:), xSim0(2,:))
title('Duffing System Phase Portrait')
xlabel('$x$','interpreter','latex')
ylabel('$\dot{x}$','interpreter','latex')
f1Legend{1} = 'open loop from X0';
legend(f1Legend);