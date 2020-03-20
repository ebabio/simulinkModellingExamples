%% Linearization of the Duffing system with a discrete controller

%% Setup workspace
clear
clc

%% Initialize system

% define the duffing system
f_init_hybrid;

%% Trim
% trim to the equilibrium at the origin
trimopts = findopOptions('DisplayReport','off');

% ADC is Delay
adcIsDelay(adcBlock, 'Ts')
op0 = operspec(modelCL); % get operating point
opTrim_delay = findop(modelCL, op0, trimopts);

% ADC is ZOH
adcIsZoh(adcBlock, 'Ts')
op0 = operspec(modelCL); % get operating point
opTrim_zoh = findop(modelCL,op0, trimopts);

%% Linearizations
% We'll showcase a number of linearization strategies for the system

% linearization options
setlinio(modelCL, []);
ioCL_hybrid(1) = linio(strjoin({modelCL,'r'},blocksep), 1,'openinput');
ioCL_hybrid(2) = linio(strjoin({modelCL,'output'},blocksep), 1, 'output');
setlinio(modelCL, ioCL_hybrid);

% step options
stepopts = stepDataOptions('StepAmplitude', stepAmplitude);

%% Naive Linearization
% default linearization

% with Delay
stepLegend_naive{1} = 'DT sample w/ Delay';
adcIsDelay(adcBlock, 'Ts')
lsysCL_naiveDelay = linearize(modelCL, ioCL_hybrid, opTrim_delay);

% with ZOH
stepLegend_naive{2} = 'DT sample w/ ZOH';
adcIsZoh(adcBlock, 'Ts')
lsysCL_naiveZoh = linearize(modelCL, ioCL_hybrid, opTrim_zoh);

% display system
display(lsysCL_naiveDelay)
display(lsysCL_naiveZoh)

% plot response
f3 = figure(3);
copyobj(gca(f2), f3);
f3.Name = 'Linear discrete step response';
f3.NumberTitle = 'off';
step(lsysCL_naiveDelay, t_end, stepopts)
step(lsysCL_naiveZoh, t_end, stepopts)
grid on
legend([stepLegend, stepLegend_naive])

% Conlusions:
% Delay: Discrete time (not the best for analysis), w/ 4 states (extra delay)
% ZOH: Discrete time (not the best for analysis), w/ 2 states (this is correct)
% But both match the system response perfectly!
% From this, we would choose the ZOH since it's the right way for sim and
% lineaization.

%% Continuous time linearization
% done by forcing the sampling time to 0, otherwise we are naive
% <https://es.mathworks.com/help/slcontrol/ug/linearizeoptions.html>

% using tustin method for the d2c (pre-warping shows no difference here)
linearizeoptions = linearizeOptions('SampleTime', 0, 'RateConversionMethod', 'tustin');

% with Delay
stepLegend_c2d{1} = 'Tustin w/ Delay';
adcIsDelay(adcBlock, 'Ts')
lsysCL_d2cDelay = linearize(modelCL, ioCL_hybrid, opTrim_delay, linearizeoptions);

% with ZOH
stepLegend_c2d{2} = 'Tustin w/ ZOH';
adcIsZoh(adcBlock, 'Ts');
lsysCL_d2cZoh = linearize(modelCL, ioCL_hybrid, opTrim_zoh, linearizeoptions);

% display system
display(lsysCL_d2cDelay)
display(lsysCL_d2cZoh)

% plot response
f4 = figure(4);
copyobj(gca(f2), f4);
f4.Name = 'Step for Linear d2c tustin';
f4.NumberTitle = 'off';
step(lsysCL_d2cDelay, t_end, stepopts)
step(lsysCL_d2cZoh, t_end, stepopts)
grid on
legend([stepLegend, stepLegend_c2d])

% Conlusions:
% Both match the short term response, but the not long term response of 
% their system. In fact the ZOH is neglected in linearization (not 
% acceptable). The delay introduces a RHP zero and response is negative in 
% the beginning.

%% Correcting the RHZ Zero in the delay
% The ZOH should be the solution, but we didn't like the RHP zero behavior. 
% We try to get rid of it.

% using exact zoh linearization method for the d2c
linearizeoptions = linearizeOptions('SampleTime', 0, 'RateConversionMethod', 'zoh', 'UseExactDelayModel', 'on');

% with Delay
stepLegend_zoh{1} = stepLegend_c2d{1};
stepLegend_zoh{2} = 'ZOH Exact w/ Delay';
adcIsDelay(adcBlock, 'Ts')
lsysCL_zohDelay = linearize(modelCL, ioCL_hybrid, opTrim_delay, linearizeoptions);

% with ZOH
stepLegend_zoh{3} = 'ZOH Exact w/ ZOH';
adcIsDelay(adcBlock, 'Ts')
lsysCL_zohZoh = linearize(modelCL, ioCL_hybrid, opTrim_delay, linearizeoptions);

% display system
display(lsysCL_zohDelay)
display(lsysCL_zohZoh)

% plot response
f5 = figure(5);
copyobj(gca(f2), f5);
f5.Name = 'Step correcting RHP Zero';
f5.NumberTitle = 'off';
step(lsysCL_d2cDelay, t_end, stepopts)
step(lsysCL_zohDelay, t_end, stepopts)
step(lsysCL_zohZoh, t_end, stepopts)
grid on
legend([stepLegend, stepLegend_zoh])

% Conlusions:
% This has changed the way the delay shows, it incorporated in the model
% instead of being approximated. This changes nothing for the ZOH
% linearization, but we have corrected the initial effect of the RHP delay,
% this is good. But still, we have to solve the ZOH behavior.

%% Linearization Override
% we override the linearization of the ZOH in the block specification to
% include the ZOH dynamics. See:
% <https://es.mathworks.com/help/slcontrol/examples/modeling-computational-delay-and-sampling-effects.html>
% <https://en.wikipedia.org/wiki/Zero-order_hold#Frequency-domain_model>

% using exact zoh linearization method
linearizeoptions = linearizeOptions('SampleTime', 0, 'RateConversionMethod', 'zoh', 'UseExactDelayModel', 'on');

% with ZOH, full ZOH dynamics
stepLegend_zohDyn{1} = 'w/ Full Zoh Dynamics';
adcIsZoh(adcBlock, 'Ts', 'LinMethod', 'FullZOH');
lsysCL_fullZoh = linearize(modelCL, ioCL_hybrid, opTrim_zoh, linearizeoptions);

% with ZOH, full ZOH dynamics
stepLegend_zohDyn{2} = 'w/ Simple Zoh Dynamics';
adcIsZoh(adcBlock, 'Ts', 'LinMethod', 'SimpleZOH');
lsysCL_simpleZoh = linearize(modelCL, ioCL_hybrid, opTrim_zoh, linearizeoptions);

% display system
display(lsysCL_fullZoh)
display(lsysCL_simpleZoh)

% plot response
f6 = figure(6);
copyobj(gca(f2), f6);
f6.Name = ' Step with ZOH Dynamics';
f6.NumberTitle = 'off';
step(lsysCL_fullZoh, t_end, stepopts)
step(lsysCL_simpleZoh, t_end, stepopts)
grid on
legend([stepLegend, stepLegend_zohDyn])

% Conlusions:
% This is a compromise solution and the best we can achieve for a 
% continuous system. The approximate response tracks the system response
% with a half cycle delay. Both the full order and the approximate solution
% offer similar performance.
% The dynamics are the same since the ZOH dynamics have been included. The
% delay arises from the fact that the ZOH is modeled by a window that needs
% to acumulate error before it has an effect, unlink DT system the effect
% cannot be discrete, and has to satisfy continuous convolution.

%% Final Conclusions
% Some application conclusions:
% Matlab's default implementation uses the ZOH as a unit gain, since this
% linearizes perfectly in DT (the default). However, Matlab is not able to 
% apply different linearization techniques for CT and DT and thus it does
% nothing in CT. If the linearization override is applied and the system is
% linearized in DT, an extra (and non-existing delay) is introduced. This
% calls for a consistent, yet flexible way of using ZOH.
%
% Further work:
% * Ideally, this linearization strategies should be common for all ZOH
% blocks and incorporated into standard functionality. 
% * Here we have used tightly coupled functions to move strings around, 
% (e.g. abusing the Ts for sample time and linearization delay). This
% should be variable name independent and taken care of by the environment. 
% Masking the ZOH and implementing these functions in the mask could be a
% way of moving arguments and strings in a non-environment dependent way.
% * The linearization needs to be executed in a coordinated manner. Adding
% a finder for all custom ZOH blocks and a pre-linearize functions to apply
% the appropriate linearization override could be a solution.


