%%  Initialization script for the Duffing continuous/discrete simulation

%% Setup workspace

clear
clc

%% Run init script

% define parameters for the duffing system and run an open loop sim
duffing_init;

%% Trim
% this method is contained in Simulink Control Design. It much more
% flexible than the classical trim function and can work with reference
% model

% operating point can be generated using the steady-state manager and exported here
% and then trimmed in batches for example.

% get an operating point from the current state
op0 = operspec(model);

% find operating point
opTrim = findop(model,op0);

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
ioOL(2) = linio('duffing/duffingSystem', 1, 'output');
setlinio('duffing',ioOL)

% linearize
lsysOL = linearize('duffing', ioOL);

%% Design control

% some info on the selected equilibrium point
pOL = pole(lsysOL);

% add a min input lqr control in continuous time
[K, ~, pCL] = lqr(lsysOL, zeros(size(lsysOL.a)), ones(size(lsysOL.b,2)) );
Ts = 10*dt;

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
linoptions = linearizeOptions( 'SampleTime', Ts);
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
derivs = duffing(0, xEq, [],'derivs'); % get the states derivatives
duffing([],[],[],'term');

% A more human readable version of the states
% get info on the system on the sizes
% (it also allows for other call conventions!)
sldiagnostics('duffing','Sizes');

