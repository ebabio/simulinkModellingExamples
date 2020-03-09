%% Test Unit Test
classdef ut_test < matlab.unittest.TestCase
    
    %% Test Data
    % test parameters that may be overriden from external parameters
    properties (TestParameter)
       tol = struct('def', 1e-6); 
    end
    
    
    %% Tests
    % tests function shall be named test**.m
    methods (Test)
        
        % a sample function that doesn't use any tolerance
        function passAlways(testCase)
            assert(true)
        end
        
        % a sample function with tolerance
        function testTestHarness(testCase, tol)
            belowTolerance = th_test() < tol;
            assert(belowTolerance);
        end
        
        % a sample function with tolerance that should fail
        function failTestHarness(testCase, tol)
            belowTolerance = sqrt(th_test()) < tol;
            assert(~belowTolerance);
        end
    end
    
end