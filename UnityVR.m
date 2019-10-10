hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');
bhv_code(10,'Start',20,'Sample',30,'Delay',40,'Go',50,'Reward');  % behavioral codes
 
% get pointer to inlets defined in alert_function.m
% frame tracker: to get frame data 
Unity_ = lslTracker(TrialRecord.User.frame_inlet, TrialRecord.User.trial_inlet, MLConfig);
Unity_.Lib = TrialRecord.User.lsl_lib;

% Can do this here since the runtime script is
% executed on every trial. This makes sure that
% the lsl_ tracker acquires data on each acquisition cycle. 
% ML_Tracker is a MonkeyLogic object containing all trackers (eye,
% joystick,...) and is defined in trialholder_v2.m line 54.
ML_Tracker.add(Unity_);  

% scene: unity.
% We will only have one scene that will collect data and
% wait for the Unity engine to send a trial outcome signal. 

% All the possible possible trial outcomes (i.e trialerror(#)) are: 
%     'correct'          0
%     'no response'      1
%     'late response'    2
%     'break fixation'   3
%     'no fixation'      4
%     'early response'   5
%     'incorrect'        6
%     'lever break'      7
%     'ignored'          8
%     'aborted'          9
% These values are from the trialholder_v2.m script and they seem to be
% hard-coded in there so I don't think we can add more. We will hovever
% match unused outcomes such as 'lever break' to something else in 
% Unity like: 'Distractor'. 
% BE CAREFUL: although "correct" is = 0, Matlab uses 1 based indexing so: 
% correct outcome = unity_to_ml_outcomes(1) but
% the trial error call is : trialerror(0); 
% TODO: COMPLETE. 
unity_to_ml_outcomes = {'correct', ...          0
                        'no_response', ...      1
                        'distractor', ...       2
                        'break_fixation',...    3
                        'no_fixation',...       4
                        'incorrect', ...        6
                        'early_response',...    7
                        'ignored', ...          8
                        'aborted'}; %           9

%The outcomes from unity will be slightly different: no spaces, 
correct_outcomes = [1];
incorrect_outcomes = [2:9];

unity = lslAdapter(Unity_);  % create Adapter from Tracker
% Specify which states trigger a (in)correct end of trial
unity.Outcomes = unity_to_ml_outcomes;
unity.CorrectOutcomes = correct_outcomes;  
unity.IncorrectOutcomes = incorrect_outcomes;  

scene1 = create_scene(unity); 

run_scene(scene1,10);

if ~unity.Success          % The failure of MultiTarget means that none of the targets was chosen.
    idle(0);              % Clear the screen.

    if (isempty(unity.Outcome_ID))
        trialerror(9);
    else
        trialerror(unity.Outcome_ID - 1);
    end
    
else
    trialerror(0); % correct
    goodmonkey(100, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50); % 100 ms of juice x 2
end

% Get trial data and save 

[data, trial, xml] = Unity_.GetTrialData(param_);
bhv_variable('VR_Data', data)  % To Save variables to file. 
bhv_variable('VR_Trial', trial)
bhv_variable('XML_Header', xml)

% Since MonkeyLogic only saves the calibrated eye data in degrees, we need
% to keep the calibration and pixels per degree values. 
eye_cal = struct();
eye_cal.el_gains = MLConfig.EyeTracker.EyeLink.Source(1:2,4)';        %[gain_x, gain_y]
eye_cal.el_offsets = MLConfig.EyeTracker.EyeLink.Source(1:2,3)';      %[offset_x, offset_y]
eye_cal.t_offset = MLConfig.EyeTransform{1,1}.offset;
eye_cal.t_rotation = MLConfig.EyeTransform{1,2};                      % [2,2]
if isempty(eye_cal.t_rotation)
    eye_cal.t_rotation = eye(2);
end
eye_cal.t_transform = MLConfig.EyeTransform{1,3}.tdata.T;
eye_cal.pix_per_deg = MLConfig.PixelsPerDegree(1);
eye_cal.ml_x_res = MLConfig.Screen.Xsize;
eye_cal.ml_y_res = MLConfig.Screen.Ysize;
bhv_variable('Eye_Calibration', eye_cal);