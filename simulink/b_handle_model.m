%%  Handling script for the Duffing continuous/discrete system simulation
% This script is meant to show case how to operate the model and change
% model properties and modify it using programmatic methods
%% Setup workspace

clear
clc

%% Basic model setup

% this initializes the model
a_init_model;

%% Model Opening

% open model
open_system(model)

% identify reference models and open them
refMdls = find_mdlrefs(model); % refMdls includes the top level model

for i=1:size(refMdls)
    load_system(refMdls{i}) % load but don't open GUI, it's faster
end

clear refMdls refMdlBlks

%% Comment blocks

% comment through adc to have a fully continuous system
block = strjoin({model,'duffing','forcing'},blocksep); 
% use this function to access blocks behing reference models
derefBlock = dereference_block(block); % see SKD Matlab Toolset

% comment block
set_param(derefBlock,'Commented', 'on');

%% Running simulink programatically
% simulate a step responses

% Using Simulink.SimulationInputs
% EB: i've made some tests, setting the initial state this way is a mess, but
% it's clean for settings inputs

% Create the simulink input object
simIn = Simulink.SimulationInput(model);

% Set initial state: the origin (this is a bit messy)
set_param(model,'SaveFinalState','on', 'SaveOperatingPoint','on', 'FinalStateName', 'myOpPoint'); % save model operating point
simTemp = sim(model,'StopTime','0'); % void sim to get a SimulationOutput
modelOpPoint = simTemp.myOpPoint; % get modelOperatingPoint
% logged states are a dataset
[~, stateIndex] = get_simulation_dataset(modelOpPoint.loggedStates, 'x');
modelOpPoint.loggedStates{stateIndex}.Values.Data(1,:) = [0, 0];
simIn = simIn.setInitialState(modelOpPoint);

% Set inputs
ts = timeseries(0*[1; 1], [0; t_end]);
ts.Name = 'u';
simIn = simIn.setExternalInput(ts);

% Set sim options
set_param(model, 'SaveState', 'on');

% Sim
simOutProg = sim(simIn);

% Access outputs
xProg0_dataset = get_simulation_dataset(simOutProg.xout, 'x');

% Plot trajectory in phase portrait
f2 = figure(2);
clf reset
f2.Name=  'Step response';
f2.NumberTitle = 'off';
axis equal
hold on
plot(xProg0_dataset.Values.Data(:,1)', xProg0_dataset.Values.Data(:,2)')
% plot(xProg0_dataset.Values.Time', xProg0_dataset.Values.Data(:,1)')
% plot(ts.Time', ts.Data')
title('Duffing System Step Response')
xlabel('$x$','interpreter','latex')
ylabel('time')
f2Legend = {'x','u'};
legend(f2Legend);
