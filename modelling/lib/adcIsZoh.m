function adcIsZoh(sys, ts, varargin)
% Implement an ADC using a Zero-Order-Hold.
% This function is tightly couple with model_closedloop.slx for testing.

% parse inputs
validLinMethods = {'', 'FullZOH', 'SimpleZOH'};

p = inputParser;
addRequired(p, 'sys', @ischar);
addRequired(p, 'ts', @ischar);
addParameter(p, 'LinMethods', validLinMethods{1}, @(x) any(strcmp(x, validLinMethods)) );
parse(p, sys, ts, varargin{:});

% replace block
position = get_param(p.Results.sys,'position');
delete_block(p.Results.sys);
add_block('simulink/Discrete/Zero-Order Hold', p.Results.sys)
set_param(sys, 'position', position); % this automatically connects things! not robust, but this is a prototype

% and add properties
set_param(p.Results.sys, 'SampleTime', p.Results.ts);


% linearization override: see linearization

if(strcmp(p.Results.LinMethods, ''))
    % do nothing, take the default
    set_param(p.Results.sys,'SCDEnableBlockLinearizationSpecification','off');
else
    % override 
    if(strcmp(p.Results.LinMethods, 'FullZOH'))
        linFcn = 'zohLinearizationFcn'; % full ZOH dynamics
    elseif(strcmp(p.Results.LinMethods, 'SimpleZOH'))
        linFcn = 'zohLinearizationSimpleFcn'; % simplified delay
    else
        error('should never reach this');
    end
    set_param(p.Results.sys,'SCDEnableBlockLinearizationSpecification','on');
    zohLinSpec = struct('Specification',linFcn,...
        'Type','Function',...
        'ParameterNames','samplingTime',...
        'ParameterValues', p.Results.ts);
    set_param(p.Results.sys,'SCDBlockLinearizationSpecification',zohLinSpec);
end
end