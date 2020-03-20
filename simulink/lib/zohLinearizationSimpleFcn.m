function zohLin = zohLinearizationSimpleFcn(BlockData)
%This function customizes the linearization of a zero-order hold to apply
%the transfer function of a zero-order hold. See:
% https://es.mathworks.com/help/slcontrol/examples/modeling-computational-delay-and-sampling-effects.html
% https://en.wikipedia.org/wiki/Zero-order_hold#Frequency-domain_model

% Get parameter values
Ts = BlockData.Parameters.Value;

% Implement dynamics as a approximate linear system: exp(-T*s/2)
nStates = BlockData.nu;
zohLin = ss(eye(nStates),'InputDelay',Ts/2);
end