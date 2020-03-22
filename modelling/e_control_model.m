%% Design a control for the Duffing continuous simulation

%% Setup workspace

clear
clc

%% Initalize, trim and linearize the system

% define parameters for the duffing system
d_linearize_model;
clc

%% Closed Loop Parameters

% apply reference to position only
ref2Pos = [1;0];

%% Design an LQR control

% some info on the selected equilibrium point
pOL = pole(lsysOL);

% add a min input lqr control in continuous time
[K, ~, pCL] = lqr(lsysOL, 0*eye(size(lsysOL.a)), eye(size(lsysOL.b,2)) );

% display new poles
f3 = figure(3);
clf reset
f3.Name=  'Pole Location';
f3.NumberTitle = 'off';
hold on
grid on
scatter(real(pOL), imag(pOL), 'x')
scatter(real(pCL), imag(pCL), '*')
legend('OL poles', 'CL poles')
title('Poles in the s-domain')

%% Load Closed Loop Model

% define the CL model, we will work on it from now on
modelCL = 'model_closedloop';

% load
load_system(modelCL);

% terminate model if started
try
    feval(modelCL, [],[],[],'term');
catch
end

% model settings
% https://www.mathworks.com/help/simulink/slref/set_param.html
set_param(modelCL, 'LoadExternalInput', 'off') % remove operating points
set_param(modelCL, 'LoadInitialState', 'off')
set_param(modelCL, 'Solver', 'FixedStepAuto', 'FixedStep', 'dt' )

% reference models settings
for i=1:size(refMdls)
    set_param(refMdls{i},'SaveFormat','Dataset');   
end

% the model is continuous, comment the ADC block
set_param(strjoin({modelCL,'adc'},blocksep), 'Commented', 'through')

% simulate CL
simOutCL = sim(modelCL);
xCL_dataset = get_simulation_dataset(simOutCL.xout, 'x'); % get dataset from name
xCL = xCL_dataset.Values.Data';

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

clLegend = {'lsysOl', 'lsysCL'};

% Bode plot
f4 = figure(4);
clf reset
f4.Name = 'Bode plot';
f4.NumberTitle = 'off';
bodeHandle = bodeplot(lsysOL, lsysCL1);
grid on
legend(clLegend)

% Nyquist plot
f5 = figure(5);
clf reset
f5.Name = 'Nyquist plot';
f5.NumberTitle = 'off';
nyqHandle = nyquistplot(lsysOL, lsysCL1);
grid on
legend(clLegend)

% Nichols Plot
f6 = figure(6);
clf reset
f6.Name = 'Nichols plot';
f6.NumberTitle = 'off';
nichHandle = nicholsplot(lsysOL, lsysCL1);
grid on
legend(clLegend)

% System stability margins for the CL system
[ gmCL , pmCL , wcgCL , wcpCL ] = margin(lsysCL1);