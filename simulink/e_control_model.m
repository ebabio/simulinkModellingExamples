%% Design a control for the Duffing continuous simulation

%% Setup workspace

clear
clc

%% Initalize, trim and linearize the system

% define parameters for the duffing system,
% run an open loop sim and trim about a non equilibrium point
d_linearize_model;
clc

%% Design an LQR control

% some info on the selected equilibrium point
pOL = pole(lsysOL);

% add a min input lqr control in continuous time
[K, ~, pCL] = lqr(lsysOL, zeros(size(lsysOL.a)), ones(size(lsysOL.b,2)) );

% display new poles
f2 = figure(2);
clf reset
f2.Name=  'Pole Location';
f2.NumberTitle = 'off';
hold on
grid on
scatter(real(pOL), imag(pOL), 'x')
scatter(real(pCL), imag(pCL), '*')
legend('OL poles', 'CL poles')
title('Poles in the s-domain')

%% Load Closed Loop Model

% define the CL model, we will work on it from now on
modelCL = 'model_closedloop';

% load it
load_system(modelCL);

% apply reference to position only
ref2Pos = [1;0];

% the model is continuous, comment the ADC block
set_param(strjoin({modelCL,'adc'},blocksep), 'Commented', 'through')

% simulate CL
simOutCL = sim(modelCL);
xCL = simOutCL.xout{1}.Values.Data';

figure(f1)
plot(xCL(1,:), xCL(2,:))
f1Legend{2} = 'Close Loop from X0';
legend(f1Legend);

%% Analyze the Closed the loop
% the closed loop dynamics can be obtained in different ways:

% 1. Update Model and re-linearize:
% using linearize, from "d_linearize_model.m"
setlinio(modelCL, []);
ioCL(1) = linio(strjoin({modelCL,'r'},blocksep), 1,'openinput'); %only change in r
ioCL(2) = linio(strjoin({modelCL,'output'},blocksep), 1, 'output');
setlinio(modelCL,ioCL);

lsysCL1 = linearize(modelCL, ioCL);
lsysCL1.StateName = lsysOL.StateName;
lsysCL1.InputName = 'r'; % new input is the reference point
lsysCL1.OutputName = lsysOL.OutputName;

% 2. Analytic loop closure:
% working out the math
aFeedback = lsysOL.b * K;
uMapping = K * ref2Pos;
lsysCL2 = ss(lsysOL.a - aFeedback, lsysOL.b * uMapping, lsysOL.c, lsysOL.d * uMapping);
lsysCL2.StateName = lsysCL1.StateName;
lsysCL2.InputName = lsysCL1.InputName;
lsysCL2.OutputName = lsysCL1.OutputName;

% 3. Control Toolbox Connect:
% connecting blocks in an organized way, see
% https://es.mathworks.com/help/control/examples/connecting-models.html
lsysCL3_0 = lsysOL; 
lsysCL3_0.c = eye(2); % get both states as outputs, LQR is state feedback
lsysCL3_ff = series(K, lsysCL3_0);
lsysCL3_fb = feedback(lsysCL3_ff, eye(2));
lsysCL3_out = series(lsysCL3_fb, yMask);
lsysCL3 = series(ref2Pos, lsysCL3_out);
lsysCL3.StateName = lsysCL2.StateName;
lsysCL3.InputName = lsysCL2.InputName;
lsysCL3.OutputName = lsysCL2.OutputName;

% Display all 3 and compare: they should be the same!
% use display, not disp. display gives high-level relevant info
display(lsysCL1)
display(lsysCL2)
display(lsysCL3)

%% Closed vs Open Loop Properties

legendLabel = {'lsysOl', 'lsysCL'};

% Bode plot
f3 = figure(3);
clf reset
f3.Name = 'Bode plot';
f3.NumberTitle = 'off';
bodeHandle = bodeplot(lsysOL, lsysCL1);
grid on
legend(legendLabel)

% Nyquist plot
f4 = figure(4);
clf reset
f4.Name = 'Nyquist plot';
f4.NumberTitle = 'off';
nyqHandle = nyquistplot(lsysOL, lsysCL1);
grid on
legend(legendLabel)

% Nichols Plot
f5 = figure(5);
clf reset
f5.Name = 'Nyquist plot';
f5.NumberTitle = 'off';
nichHandle = nicholsplot(lsysOL, lsysCL1);
grid on
legend(legendLabel)

% System margins
[ gmOL , pmOL , wcgOL , wcpOL ] = margin(lsysOL);
[ gmCL , pmCL , wcgCL , wcpCL ] = margin(lsysCL1);