%%  Initialization script for the Duffing continuous/discrete simulation

%% Setup workspace

clear
clc

%% Duffing system parameters
% Reusing the nomenclature from: http://mathworld.wolfram.com/DuffingDifferentialEquation.html

delta = 0;
beta = 1;
omega2 = -1;

%% Simulation parameters

x0 = [0; .1];
t_end = 20;

%% Simulate Open Loop

% simulate model
simOut = sim('duffing');

% Postprocess
x = simOut.yout{1}.Values.Data';

figure(1)
clf reset
plot(x(1,:), x(2,:))
axis equal

%% Trim

% trim model
% x: internal state
% u: inputs
% y: outputs

% find an equilibrium
[xEq, uEq, yEq, xDotEq] = trim('duffing',x0, [], []);

% find a complex equilibrium
% [x,u,y,dx,options] = trim('sys',x0,u0,y0,ix,iu,iy,dx0,idx,options)

%% Linearize model

linStruct = linmod('duffing', xEq, uEq);

%% Interesting facts

% the different methods of the model can be called for different purposes
% https://www.mathworks.com/help/simulink/slref/model_cmd.html

% get the states
[sizes, x0Alt, xStr, ts] = duffing([],[],[],'sizes');

% we can compile the system and access it programatically
[sizes, x0Alt, xStr, ts] = duffing([],[],[],'compile');
derivs = duffing(0, x0, [],'derivs'); % get the states derivatives
duffing([],[],[],'term');

% A more human readable version of the states
% get info on the system on the sizes
% (it also allows for other call conventions!)
sldiagnostics('duffing','Sizes');

