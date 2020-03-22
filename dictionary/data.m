%% Model parameters

%% Setup workspace
clear
clc

model = 'lissajous';
%% Design Data Management in Simulink
% The high-level page with the three methods described: base workspace,
% model workspace, and data dictionaries
% <https://es.mathworks.com/help/simulink/manage-design-data.html?s_tid=CRUX_lftnav>
% Here it is interesting to pay attention to the first four entries of
% 'Data Storage in Dictionaty'
%
% Some guidelines on which method to use:
% <https://es.mathworks.com/help/simulink/ug/determine-where-to-store-data-for-simulink-models.html>
% We will tend to use data dictionaries mostly, withs cripts writing to
% data dictionatiries mainly. See the last sentence in above.

%% Lissajous curve parameters
% Lissajous Curves depend on the parameters, we can play with parameters
% and see their effect:
% <https://en.wikipedia.org/wiki/Lissajous_curve#Examples>

% we set up the 3,2 lissajous curve
% x_motion
wn_x = 3;

x0 = 1;
xDot0 = 0;

% y_motion
wn_y = 2; % set to 1 in y_data.sldd, this will give some problems :)

y0 = 0;
yDot0 = wn_y * 1; % so that yMax = 1

%% Handle data in dicitonary
% Some guidelines on how to use dictionaries
% <https://es.mathworks.com/help/simulink/ug/determine-where-to-store-data-for-simulink-models.html>
% The dictionaries have some inconsistent data, let's see what happens

%%x_dictionary
x_data_dict = Simulink.data.dictionary.open('x_data.sldd'); % contains wn_x
% set wn_y entry from dictionary
sectionObj = getSection(x_data_dict, 'Design Data');
entryObj = getEntry(sectionObj, 'wn_x');
setValue(entryObj, wn_x);
% the wn_x entry is consistent with workspace, 
% it will give a warning and not an error, but not recommended

%%y dictionary
y_data_dict = Simulink.data.dictionary.open('y_data.sldd'); % contains wn_y
lissajous_data_dict = Simulink.data.dictionary.open('lissajous_data.sldd'); % this dictionary references y_data and duplicates wn_y
% discard existing changes
discardChanges(y_data_dict);
discardChanges(lissajous_data_dict);

% this way there's a conflict between different values of y
try
    try
        % try to simulate:
        % it will throw an error because of inconsistencies
        sim(model);
        
    catch e
        % display the error
        print_error(e)
        
        % set wn_y entry to y_data dictionary from worskpace
        sectionObj = getSection(y_data_dict, 'Design Data');
        entryObj = getEntry(sectionObj, 'wn_y');
        setValue(entryObj, wn_y);
        
        % wn_y is not necessary anymore
        clear wn_y
    end
    % try to simulate again:
    % it will throw an error because of inconsistencies
    sim(model);
catch
    % display the error
    print_error(e)
    
    % delete entry from lissajous dictionary
    sectionObj = getSection(lissajous_data_dict, 'Design Data');
    deleteEntry(sectionObj, 'wn_y', 'DataSource', 'lissajous_data.sldd'); % necessary if a variable if duplicated in different dictionaries    
    % now it is good
end

%% Simulate

% we should get the 3,2 lissajous curve
simOut = sim(model);

% Plot trajectory in phase portrait
x_dataset = get_simulation_dataset(simOut.yout, 'x');
y_dataset = get_simulation_dataset(simOut.yout, 'y');
x = x_dataset.Values.Data';
y = y_dataset.Values.Data';
f1 = figure(1);
clf reset
f1.Name=  'Lissajous Curve';
f1.NumberTitle = 'off';
axis equal
hold on
plot(x(1,:), y(1,:))
title('Lissajous Curve Model')
xlabel('$x$','interpreter','latex')
ylabel('$y$','interpreter','latex')

%% Auxiliary function

% Display error in a catch statement
function print_error(e)
fprintf(2, 'error in %s: line %d\n', e.stack.name, e.stack.line);
fprintf(2, '%s\n', e.message);
for i=1:numel(e.cause)
    fprintf(2, '\t%s\n', e.cause{i}.message);
end
end