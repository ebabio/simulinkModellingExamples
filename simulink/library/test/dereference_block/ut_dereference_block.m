%% Test Dereference Block
classdef ut_dereference_block < matlab.unittest.TestCase
    %% Test Data
    % test parameters that may be overriden from external parameters
    properties (TestParameter)
        model = struct('def', 'top_level');
    end
    
    %% Test Setup / Teardown
    
    methods(TestClassSetup)
        function loadSystem(testCase)
            refMdls = find_mdlrefs(testCase.model.def);
            for i=1:size(refMdls)
                load_system(refMdls{i})
            end
        end
    end
    
    methods(TestClassTeardown)
        function closeSystem(testCase)
            refMdls = find_mdlrefs(testCase.model.def);
            for i=1:size(refMdls)
                close_system(refMdls{i})
            end
        end
    end
    
    
    
    %% Tests
    % tests function shall be named test**.m
    methods (Test)
        
        % a non-referenced block
        function nonReferencedBlock(testCase, model)
            % input
            block = strjoin({model,'A','A'},blocksep); % this block is in top_level model
            %expected output
            expectedblock = block;
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
        
        % a reference subsystem block: these are not deferenced
        function referenceSubsystemBlock(testCase, model)
            % input
            block = strjoin({model,'A','B','A'},blocksep); % this block is referenced subystem C
            %expected output
            expectedblock = block;
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
        
        % a unique reference model block
        function referenceModelBlockUnique(testCase, model)
            % input
            block = strjoin({model,'C','A'},blocksep); % this block is referenced model B
            %expected output
            expectedblock = strjoin({'X','A'},blocksep);
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
        
        % a duplciate reference model block
        function referenceModelBlockDuplicate(testCase, model)
            % input
            block = strjoin({model,'D','A'},blocksep); % this block is referenced model B
            %expected output
            expectedblock = strjoin({'W','A'},blocksep);
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
        
        % a reference model block in a reference model, recursive
        function referenceModelBlockRecursive(testCase, model)
            % input
            block = strjoin({model,'B','B','A'},blocksep); % this block is referenced model D, which is B
            %expected output
            expectedblock = strjoin({'Z','A'},blocksep);
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
        
        % a reference model parent, no block in it, should not dereference
        function referenceModel(testCase, model)
            % input
            block = strjoin({model,'B'},blocksep); % this block is B
            %expected output
            expectedblock = block;
            
            % test
            dereferenced_block = dereference_block(block);
            assert(strcmp(expectedblock, dereferenced_block));
        end
    end
    
end