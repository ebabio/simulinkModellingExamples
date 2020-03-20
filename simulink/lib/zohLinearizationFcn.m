function zohLin = zohLinearizationFcn(BlockData)
%This function customizes the linearization of a zero-order hold to apply
%the transfer function of a zero-order hold. See:
% https://es.mathworks.com/help/slcontrol/examples/modeling-computational-delay-and-sampling-effects.html
% https://en.wikipedia.org/wiki/Zero-order_hold#Frequency-domain_model

% Get parameter values
Ts = BlockData.Parameters.Value;

% Implement dynamics as a linear system: (1-exp(-T*s))/(s*T)
nStates = BlockData.nu;
zohLin = (eye(nStates)-ss(eye(nStates),'InputDelay',Ts))*ss(zeros(nStates),eye(nStates),eye(nStates),zeros(nStates))/Ts;
end