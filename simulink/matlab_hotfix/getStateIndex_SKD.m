function idx = getStateIndex_SKD(varargin)
% getStateIndex has a bug. This hotfix is meant to contain it. If the
% original implementation fails call skd safe override.
try
    idx = getStateIndex(varargin{:});
    % check if the bug is present but the function ran correctly (i.e. the
    % bug's been fixed)
    if(statename_is_faulty(varargin{2}))
        print_remove_hotfix('SKD:solvedBug')
    end
catch e
    if(strcmp(e.identifier, 'SKD:solvedBug'))
        rethrow(e)
    end
    idx = getStateIndex_hotfix(varargin{:});
end
end

%% Bug description
% if statename contains a reference model the path of the block includes a
% '|'. e.g. 'parent_model/ref_alias|ref_model/block'.
% When calling get_param in a sanity check the '|' character will make it
% fail since their syntax for reference models is different. The SKD
% override splits the model block and takes only the last substring after
% the '|'.

% Search for: 'SKD Change'

%% Hotfix Implementation
function idx = getStateIndex_hotfix(op, statename, element_idx)
% getStateIndex returns the index of the state in the state array of an
% operating point or an operating point specification.
%
% Syntax:
%  idx = getStateIndex(op, name, element_idx)
%
% Inputs:
%  op: An operating point or an operating point specification.
%  name: A state name or a block name. If the state is a Simscape state,
%		 the state name must be provided.
%  element_idx: (optional) Index of the element in the block, if name is a
%		 block name. Default value is [1:numOfStates].
%
% Outputs:
%  idx(1): Index in the state array of op.
%  idx(2): Index of the element in the state. It can be different from
%		   the input element_idx, since a block can break into multiple
%		   states.
%
% Example:
%   ops = operspec('scdspeedctrl')
%   idx = getStateIndex(ops, 'scdspeedctrl/Vehicle Dynamics/w = T//J w0 = 209 rad//s', 1)
%
% See also operspec

% Copyright 2016 The MathWorks, Inc.

narginchk(2,3)

% Load the model if it is not loaded
paramMgr = linearize.ModelLinearizationParamMgr.getInstance(op.Model);
paramMgr.loadModels;

% String conversion
if isstring(statename)
    statename = statename.char;
end
if ~ischar(statename)
    error(message('SLControllib:opcond:InvalidStateNameInput'))
end

% Process the statename, replace '\n' with ' ';
statename(statename == 10) = 32;

% Make a copy of the states
states = op.states;

% No inputs block exists
if isempty(states)
    error(message('SLControllib:opcond:StateBlockNameNotExist', statename))
end

% First, assume state name is used
statenames = get(states,'StateName');
% No need for regular expression in the state name
state_idx = find(strcmp(statename,statenames), 1);
% Check to see if a state is located
if isempty(state_idx)
    % Cannot find a statename, assuming a block name is used
    blocknames = get(states, 'Block');
    blocknames = regexprep(blocknames, '\n', ' ');
    state_idx = find(strcmp(statename,blocknames));
    if isempty(state_idx)
        error(message('SLControllib:opcond:StateBlockNameNotExist', ...
            statename))
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Beginning of SKD Change
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    elseif (~statename_is_faulty(statename) && ...
            strcmp(get_param(statename, 'BlockType'),'SimscapeBlock') )
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % End of SKD Change
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        % If this is a simscape block name but a blockname is used, error
        % out. This is because some states in a simscape block may be
        % eliminated.
        error(message('SLControllib:opcond:InvalidSimscapeStateNameInput'));
    end
end


nx = states(state_idx(1)).Nx;
% By default, output all elements for the block
if nargin < 3
    element_idx = 1:nx;
elseif	isempty(element_idx)
    element_idx = [];
end


if numel(state_idx) == 1
    % Found a single block
    
    % Error checking for the element indices
    % Check uniqueness and positive integer
    if ~isempty(element_idx)
        if      ~isnumeric(element_idx) ||...
                ~isvector(element_idx) || ...
                ~all(element_idx == floor(element_idx)) || ...
                numel(unique(element_idx)) < numel((element_idx)) || ...
                isempty(element_idx) || ...
                min(element_idx) <= 0
            error(message('SLControllib:opcond:InvalidElementIdxInput'))
        end
    end
    
    % Error check uppwer bound
    if nx < max(element_idx)
        error(message('SLControllib:opcond:IndexOutOfRange', num2str(nx)))
    end
elseif ~isempty(element_idx)
    % found multiple blocks
    state_idx = state_idx(element_idx);
    if numel(state_idx) > 1
        % The elements selected are across different states
        error(message('SLControllib:opcond:StateElementSplit', statename));
    else
        element_idx = 1;
    end
end

% Combine results
if ~isempty(element_idx)
    idx = [state_idx*ones(numel(element_idx),1) element_idx(:)];
else
    idx = [];
end
end

%% Check for the bug
function is_faulty = statename_is_faulty(statename)
% sanity checks (copied from the function)
% String conversion
if isstring(statename)
    statename = statename.char;
end
if ~ischar(statename)
    error(message('SLControllib:opcond:InvalidStateNameInput'))
end

% actual check for the bug condition
is_faulty = contains(statename, '|');
end

%% Remove function
function print_remove_hotfix(errorId)
    str = ['MATLAB''s getStateIndex function seems to have avoided a previous bug.\n' ...
        'Running this case in R2019b would have failed.\n' ...
        'You no longer have to thank us (EB & CP) for saving your ass.\n' ...
        'You can delete this whole file now and go fix all the code that contained it.\n'...
        ':)'];
    error(errorId, str)
end