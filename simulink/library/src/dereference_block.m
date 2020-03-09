function derefBlock = dereference_block(sys)
%DEREFBLOCK returns the name of the block accuting for possible reference
% models that change the effective block path

%% Check for reference blocks in the path

% from block name, get top level reference model
top_model = strtok(sys, blocksep);
% get reference models and their block name in the model
[~, refMdlBlks] = find_mdlrefs(top_model,false); % return ref models only in top_model

% block is a top level reference model
exactMatch = strcmp(sys,refMdlBlks);
exactMathIndex = find(exactMatch, 1); % return first match index

% check if model is part of a reference model
[~,endIndex] = regexp(sys,refMdlBlks); % returns match of block with refMdlBlks substring as a cell
subStringMatchHandle = @(endIndex) (~isempty(endIndex)); % if endIndex is not empty there is a match
subStringMatch = cellfun(subStringMatchHandle, endIndex);
subStringMatchIndex = find(subStringMatch, 1); %  return partial match index

%% Apply the change of path if rerence models are present

if(isempty(exactMathIndex) && ... % if it matches perfectly, we return the top level
        ~isempty(subStringMatchIndex)) % if it is a substring, return derefernced block
    % dereferenced block
    [~, modelReference, ~] = fileparts(get_param(refMdlBlks{subStringMatchIndex},'ModelFile'));
    derefCandidateBlock = [modelReference, sys(endIndex{subStringMatchIndex}+1:end)];
    % check for recursion
    derefBlock = dereference_block(derefCandidateBlock); 
else %return original block
    derefBlock = sys;
end

end