function adcIsDelay(sys, Tstring)
% Implement an ADC using a discrete delay block. 
% This function is coupled with model_closedloop.slx for testing.

% replace block
position = get_param(sys,'position');
delete_block(sys);
add_block('simulink/Discrete/Delay',sys)
set_param(sys, 'position', position); % this automatically connects things! not robust, but this is a prototype

% and add properties
set_param(sys, 'DelayLength', '1');
set_param(sys, 'StateName', 'adc');
set_param(sys, 'SampleTime', Tstring);
end