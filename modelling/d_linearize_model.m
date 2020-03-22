%%  Linearize the Duffing continuous simulation

%% Setup workspace

clear
clc

%% Run init script

% define parameters for the duffing system
a_init_model;

%% Trim
% no display trim data
trimopts = findopOptions('DisplayReport','off');

% get an operating point from the current state
op0 = operspec(model);

% find trim point: the equilibrium
opTrim = findop(model, op0, trimopts);

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
ol_sysCT.OutputName = {'x'};

% 2. linearize desired parts
% using linearize: in Simulink Control Design, this one is the desired one
setlinio(model, []);
ioOL(1) = linio(strjoin({model,'u'},blocksep), 1,'openinput');
ioOL(2) = linio(strjoin({model,'output'},blocksep), 1, 'output');
setlinio(model, ioOL);

% linearize
lsysOL = linearize(model, ioOL, opTrim);
lsysOL.StateName = ol_sysCT.StateName;
lsysOL.InputName = ol_sysCT.InputName;
lsysOL.OutputName = ol_sysCT.OutputName;

% display data
display(lsysOL)
