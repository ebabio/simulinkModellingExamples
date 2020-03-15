%%  Linearize the Duffing continuous simulation

%% Setup workspace

clear
clc

%% Run init script

% define parameters for the duffing system,
% run an open loop sim and trim about a non equilibrium point
a_init_model;

%% Trim
% this method is contained in Simulink Control Design. It much more
% flexible than the classical trim function and can work with reference
% model

% operating point can be generated using the steady-state manager and exported here
% and then trimmed in batches for example.

% get an operating point from the current state
op0 = operspec(model);

% find trim point
opTrim = findop(model,op0);

% get trim states
[xEq, uEq] = getxu(opTrim);
u0_struct = getinputstruct(opTrim); % this is the good way, but it doesn't work
x0_struct = getstatestruct(opTrim);

%% Linearize model

% 1. linearize the whole system
% using linmod: the classic way
linStruct = linmod(model, xEq, uEq);

% create state space model and cleanup
ol_sysCT = ss(linStruct.a, linStruct.b, linStruct.c, linStruct.d);
ol_sysCT.StateName = {'x0', 'x1'};
ol_sysCT.InputName = {'u'};
ol_sysCT.OutputName = {'x0', 'x1'};

% 2. linearize desired parts
% using linearize: in Simulink Control Design, this one is the desired one
setlinio(model, []);
ioOL(1) = linio(strjoin({model,'u'},blocksep), 1,'openinput');
ioOL(2) = linio(strjoin({model,'duffing'},blocksep), 1, 'output');
setlinio(model,ioOL);

% linearize
lsysOL = linearize(model, ioOL);
lsysOL.StateName = ol_sysCT.StateName;
lsysOL.InputName = ol_sysCT.InputName;
lsysOL.OutputName = ol_sysCT.OutputName;
