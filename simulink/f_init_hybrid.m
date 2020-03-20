%% Initialization script for the Duffing system with a discrete controller

%% Setup workspace

clear
clc

%% Initialize, and design a controller for the continuous system

% define parameters for the duffing system
e_control_model;

% cleanup plots
close(f3)
close(f4)
close(f5)
close(f6)
clc

%% Discrete Control Parameters

% controller sampling time
Ts = .2;

%% Setup Hybrid Time Model

% the controller is discrete, introduce the ADC block
adcBlock = strjoin({modelCL,'adc'},blocksep);
set_param(adcBlock, 'Commented', 'off');

% set controller to be atomic, this is the preferred way to handle CSCI
set_param(strjoin({modelCL,'controller'},blocksep), 'TreatAsAtomicUnit', 'on');

%% Simulate Model

% ADC is Delay
adcIsDelay(adcBlock, 'Ts')
simOutCL_delay = sim(modelCL);

% ADC is ZOH
adcIsZoh(adcBlock, 'Ts')
simOutCL_zoh = sim(modelCL);

% get outputs
xCL_delay_dataset = get_simulation_dataset(simOutCL_delay.xout, 'x'); % get dataset from name
xCL_delay = xCL_delay_dataset.Values.Data';
xCL_zoh_dataset = get_simulation_dataset(simOutCL_zoh.xout, 'x'); % get dataset from name
xCL_zoh = xCL_zoh_dataset.Values.Data';

% plot trajectories in phase portrait
f1 = figure(1);
plot(xCL_delay(1,:), xCL_delay(2,:))
plot(xCL_zoh(1,:), xCL_zoh(2,:))
f1Legend{3} = 'Closed Loop with sampling using delay';
f1Legend{4} = 'Closed Loop with sampling using ZOH';
legend(f1Legend);

% Takeaway:
% Notice the big difference between the real ZOH and the discrete delay,
% they have a huge difference in terms of performance. Why?
% ZOH applies a constant input, but at the sampling time sampled signal and
% reality match. The delay adds another full cycle on top of that. In terms
% of modelling we may want to keep the ZOH for the ADC and the delay for
% iternal computation delays. This has some effects on linearization that
% we will study later.

%% Step responses
% These will be useful when comparing the real model vs the linearized one
% simulate the real system: see example "b"

% step parameters
stepAmplitude = 1e-2;

% setup step simulation
simInCL_step = Simulink.SimulationInput(modelCL);
simInCL_step = simInCL_step.setVariable('x0',[0;0]);
simInCL_step = simInCL_step.setExternalInput( timeseries(stepAmplitude*[1; 1], [0; t_end]) );

% ADC is Delay
stepLegend{1} = 'DT feedback w/ Delay';
adcIsDelay(adcBlock, 'Ts')
simStepCL_delay = sim(simInCL_step);
xCLStep_delay_dataset = get_simulation_dataset(simStepCL_delay.xout, 'x');

% ADC is ZOH
stepLegend{2} = 'DT feedback w/ ZOH';
adcIsZoh(adcBlock, 'Ts')
simStepCL_zoh = sim(simInCL_step);
xCLStep_zoh_dataset = get_simulation_dataset(simStepCL_zoh.xout, 'x');

% ADC commented
stepLegend{3} = 'CT feedback Model';
set_param(adcBlock, 'Commented', 'through');
simStepCL = sim(simInCL_step);
set_param(adcBlock, 'Commented', 'off');
xCLStep_dataset = get_simulation_dataset(simStepCL.xout, 'x');

% compare responses
f2 = figure(2);
clf reset
hold on
f2.Name = 'Step response';
f2.NumberTitle = 'off';
plot(xCLStep_delay_dataset.Values.Time', xCLStep_delay_dataset.Values.Data(:,1)', '-.')
plot(xCLStep_zoh_dataset.Values.Time', xCLStep_zoh_dataset.Values.Data(:,1)', '-.')
plot(xCLStep_dataset.Values.Time', xCLStep_dataset.Values.Data(:,1)', '-.')
grid on
legend(stepLegend)