%%  Initialization script for the Duffing continuous/discrete simulation

%% Setup workspace

clear
clc

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

x0 = [0; 1];
t_end = 100;

%% Simulate Open Loop

% no feedback
K = zeros(1,2);

% simulate model
simOut = sim('duffing');

% Postprocess
x = simOut.yout{1}.Values.Data';

figure(1)
clf reset
plot(x(1,:), x(2,:))
axis equal
title('Duffing System Phase Portrait')
xlabel('x')
ylabel('xDot')

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

% 1. linearize the whole system
% linearize
linStruct = linmod('duffing', xEq, uEq);

% create state space model and cleanup
lsys = ss(linStruct.a, linStruct.b, linStruct.c, linStruct.d);
lsys.StateName = linStruct.StateName;
lsys.InputName = linStruct.InputName;
lsys.OutputName = linStruct.OutputName;

% 2. linearize desired parts
% define linearization points
io(1) = linio('duffing/controller', 1,'openinput');
io(2) = linio('duffing/DuffingSystem', 1, 'output');
setlinio('duffing',io)

% linearize
lsysOL = linearize('duffing', io);


%% Design control

% some info on the selected equilibrium point
pOL = pole(lsysOL);

% add a min input lqr control
[K, ~, pCL] = lqr(lsysOL, zeros(size(lsysOL.a)), ones(size(lsysOL.b,2)) );

% display new poles
figure(2)
clf reset
hold on
scatter(real(pOL), imag(pOL), 'x')
scatter(real(pCL), imag(pCL), '*')
legend('OL poles', 'CL poles')
title('Poles in the s-domain')

% simulate CL
simOutCL = sim('duffing');
xCL = simOutCL.yout{1}.Values.Data';

figure(3)
clf reset
hold on
plot(x(1,:), x(2,:))
plot(xCL(1,:), xCL(2,:))
axis equal
legend('Open Loop', 'Close Loop')
title('Duffing System Phase Portrait')
xlabel('x')
ylabel('xDot')

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

