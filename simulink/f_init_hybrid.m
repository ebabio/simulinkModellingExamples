%% Initialization script for the Duffing system with a discrete controller

%% Setup workspace

clear
clc

%% Initialize, and design a controller for the continuous system

% define parameters for the duffing system
e_control_model;

% cleanup plots
close(f2)
close(f3)
close(f4)
close(f5)
clc

%% Discrete Control Parameters

% controller sampling time
Ts = 0.1;

%% Setup Hybrid Time Model

% the controller is discrete, introduce the ADC block
set_param(strjoin({modelCL,'adc'},blocksep), 'Commented', 'off');

% set controller to be atomic, this is the preferred way to handle CSCI
set_param(strjoin({modelCL,'controller'},blocksep), 'TreatAsAtomicUnit', 'on');

%% Simulate Model

% simulate
simOutCL_ts = sim(modelCL);

% plot trajectory in phase portrait
xCL_ts_dataset = get_simulation_dataset(simOutCL_ts.xout, 'x'); % get dataset from name
xCL_ts = xCL_ts_dataset.Values.Data';
f1 = figure(1);
plot(xCL_ts(1,:), xCL_ts(2,:))
f1Legend{3} = 'Closed Loop with sampling X0';
legend(f1Legend);

