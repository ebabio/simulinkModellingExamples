%%  Handling script for the Duffing continuous/discrete system simulation
% This script is meant to show case how to operate the model and change
% model properties and modify it using programmatic methods
%% Setup workspace

clear
clc

%% Basic model setup

% this initializes the model
duffing_init;

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
block = strjoin({model,'controller','adc'},blocksep); % this block is behind a reference path
derefBlock = dereference_block(block); % see SKD Matlab Toolset

% comment block
set_param(derefBlock,'Commented','through')

%% Operate on a model within a referenced model
% this is a function example, this should be outside the script common use
% and extended for robustness handling. E.g. recursive model dereferencing

function derefBlock = dereference_block(block)
% from block name, get top level reference models nd their block name in the model
model_from_block = strtok(block,'/');
[refMdls, refMdlBlks] = find_mdlrefs(strtok(model_from_block,'/')); % this time returns two outputs

% check if model is part of a referenced subsystem by checking for matching strings
[~,endIndex] = regexp(block,refMdlBlks); % returns cell of matches of refMdlBlks size
empty = cellfun(@isempty, endIndex); % non-matching are returned as empty cells
refMdlBlkIndex = find(~empty); % if any refMdlBlks matches it is returned here

if(~isempty(refMdlBlkIndex)) % if there's a reference model, dereference it
    % dereference model
    referencedMdl = refMdls{refMdlBlkIndex};
    
    % dereferenced block
    derefBlock = [referencedMdl, block(endIndex{refMdlBlkIndex}+1:end)];
else %return original block
    derefBlock = block;
end

end
