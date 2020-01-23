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

dt = 1e-2;
x0 = [0; 1];
t_end = 10;

%% Simulate Open Loop

% no feedback
K = zeros(1,2);
Ts = 100*dt;

% simulate model
simOut = sim('duffing');

% Postprocess
x = simOut.yout{1}.Values.Data';

f1 = figure(1);
clf reset
f1.Name=  'Open Loop Sim';
f1.NumberTitle = 'off';
plot(x(1,:), x(2,:))
axis equal
title('Duffing System Phase Portrait')
xlabel('x')
ylabel('xDot')
f1Legend{1} = 'Open Loop';
legend(f1Legend);

%% Trim

% trim model
% x: internal state
% u: inputs
% y: outputs

% find an equilibrium
% [xEq, uEq, yEq, xDotEq] = trim('duffing',x0, [], []);

xEq = zeros(2,1);
uEq = [];

% find a complex equilibrium
% [x,u,y,dx,options] = trim('sys',x0,u0,y0,ix,iu,iy,dx0,idx,options)

%% Linearize model

% 1. linearize the whole system
% linearize
linStruct = linmod('duffing', xEq, uEq);

% create state space model and cleanup
lsysCT = ss(linStruct.a, linStruct.b, linStruct.c, linStruct.d);
lsysCT.StateName = linStruct.StateName;
lsysCT.InputName = linStruct.InputName;
lsysCT.OutputName = linStruct.OutputName;

% 2. linearize desired parts
% define linearization points
setlinio('duffing', []);
ioOL(1) = linio('duffing/controller', 1,'openinput');
ioOL(2) = linio('duffing/DuffingSystem', 1, 'output');
setlinio('duffing',ioOL)

% linearize
lsysOL = linearize('duffing', ioOL);

%% Design control

% some info on the selected equilibrium point
pOL = pole(lsysOL);

% add a min input lqr control in continuous time
[K, ~, pCL] = lqr(lsysOL, zeros(size(lsysOL.a)), ones(size(lsysOL.b,2)) );
Ts = 50*dt;

% display new poles
f2 = figure(2);
clf reset
f2.Name=  'Pole Location';
f2.NumberTitle = 'off';
hold on
scatter(real(pOL), imag(pOL), 'x')
scatter(real(pCL), imag(pCL), '*')
legend('OL poles', 'CL poles')
title('Poles in the s-domain')

% simulate CL
simOutCL = sim('duffing');
xCL = simOutCL.yout{1}.Values.Data';

figure(f1)
hold on
plot(xCL(1,:), xCL(2,:))
f1Legend{2} = 'Close Loop';
legend(f1Legend);

%% Analyze discrete control on continous time

% 1. continuous time equivalent ideal
lsysCT
polesCT = pole(lsysCT)

% 2. full discretized
linStructDT = dlinmod('duffing', Ts, xEq, uEq);
lsysDT = ss(linStructDT.a, linStructDT.b, linStructDT.c, linStructDT.d);
lsysDT.StateName = linStructDT.StateName;
lsysDT.InputName = linStructDT.InputName;
lsysDT.OutputName = linStructDT.OutputName;

% 3. d2c equivalent?
% linearize model in discrete time
setlinio('duffing', []);
ioK(2) = linio('duffing/DuffingSystem', 1, 'openinput');
ioK(1) = linio('duffing/controller', 1,'output');
setlinio('duffing',ioK)
linoptions = linearizeOptions( 'SampleTime', Ts); %, 'UseExactDelayModel' , 'on');
[lsysFBDT, ~, infoFBDT] = linearize('duffing', ioK, linoptions);
lsysFB = d2c(lsysFBDT,'tustin');

lsysCL = feedback(lsysOL, lsysFB, +1); %positive feedback

% display info

lsysCL
polesCL = pole(lsysCL)

%% Interesting facts

% the different methods of the model can be called for different purposes
% https://www.mathworks.com/help/simulink/slref/model_cmd.html

% get the states
[sizes, x0Alt, xStr] = duffing([],[],[],'sizes');

% we can compile the system and access it programatically
[sizes, x0Alt, xStr] = duffing([],[],[],'compile');
derivs = duffing(0, x0, [],'derivs'); % get the states derivatives
duffing([],[],[],'term');

% A more human readable version of the states
% get info on the system on the sizes
% (it also allows for other call conventions!)
sldiagnostics('duffing','Sizes');

