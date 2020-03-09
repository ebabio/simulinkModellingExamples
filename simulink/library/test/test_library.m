%% Test Library

function ut_result = test_library()
%% Setup workspace

% clear workspace
clear
clc
close all

% init library
filepath = fileparts(mfilename('fullpath'));
run(fullfile(filepath, '..', 'src', 'init_library.m'))

% add tests to library
addpath(genpath(filepath));

%% Define Test parameters

%% Assemble Test Vector

% import TestSuite
import matlab.unittest.TestSuite

% get all files
all_files = dir(fullfile(filepath,'**'));

% search for unit test files
ut_suite_cell = {};
ut_index = 1;
for i=1:length(all_files)
    % check for matching
    startIndex = regexp(all_files(i).name, '((ut_).*(.m))', 'once');
    
    if(~isempty(startIndex)) % if there's a match
        % create the test suite from the unit class
        className = all_files(i).name(1:end-2);
        ut_suite_cell{ut_index} = TestSuite.fromClass( meta.class.fromName(className) ) ;
        ut_index = ut_index+1;
    end
end

%% Run unit tests
% concatenate al test suites
ut_suite = [ut_suite_cell{:}];
ut_result = run(ut_suite);

table(ut_result)
end
