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
set_param(derefBlock,'Commented', 'on')


