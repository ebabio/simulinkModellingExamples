%% Init Library

function init_library()
%% Add folder and subfolders to path
filepath = fileparts(mfilename('fullpath'));
addpath(genpath(filepath));

end