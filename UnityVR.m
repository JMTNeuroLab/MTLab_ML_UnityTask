hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');
bhv_code(10,'Start',50,'Reward');  % behavioral codes
 
% get pointer to inlets defined in alert_function.m
% frame tracker: to get frame data 
Unity_ = lslTracker(TrialRecord.User.frame_inlet, ...
                    TrialRecord.User.trial_inlet, ...
                    MLConfig);
Unity_.Lib = TrialRecord.User.lsl_lib;

% Tobii tracker is here even if the EyeLink is used. It just wont collect
% any data. 
Tobii_ = tobiiTracker(TrialRecord.User.tobii_inlet, ...
                      MLConfig);
Tobii_.Lib = TrialRecord.User.lsl_lib;

% Can do this here since the runtime script is
% executed on every trial. This makes sure that
% the lsl_ tracker acquires data on each acquisition cycle. 
% ML_Tracker is a MonkeyLogic object containing all trackers (eye,
% joystick,...) and is defined in trialholder_v2.m line 54.
ML_Tracker.add(Unity_);  
ML_Tracker.add(Tobii_);

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
% match multiple custom outcomes to these ones.
% BE CAREFUL: although "correct" is = 0, Matlab uses 1 based indexing so: 
% correct outcome = unity_to_ml_outcomes(1) but
% the trial error call is : trialerror(0); 

% This is the list of possible Unity outcomes, we will match them to the
% default monkeylogic ones. It is possible to add new ones, as long as the
% unity_to_ml_code is updated properly. 
%                Unity Outcome           ML Code
unity_outcomes = {'correct', ...          0
                  'correct_mid', ...      0
                  'no_response', ...      1
                  'late_response', ...    2
                  'break_fixation',...    3
                  'no_fixation',...       4
                  'early_response',...    5
                  'incorrect', ...        6
                  'incorrect_mid',...     6
                  'lever_break', ...      7
                  'ignored', ...          8
                  'aborted'}; %           9

% Correct == 0; the rest is Incorrect 
unity_to_ml_code = [0, 0, 1, 2, 3, 4, 5, 6, 6, 7, 8, 9];              

unity = lslAdapter(Unity_);  % create Adapter from Tracker
% Specify which states trigger a (in)correct end of trial
unity.Outcomes = unity_outcomes;
unity.Unity_to_ml_map = unity_to_ml_code;

scene1 = create_scene(unity); 

run_scene(scene1,10);

% NOT success means that it is an Incorrect Outcome
if ~unity.Success          
    % Clear the screen.
    idle(0);              

    if (isempty(unity.Outcome_ID))
        unity.Outcome_ID = 12;
    end
    
    trialerror(unity_to_ml_code(unity.Outcome_ID));
% correct
else
    trialerror(0); 
end

% Give reward for both correct and incorrect-mid trials
% TODO: figure out ML GUI reward setting. 
if isempty(unity.CurrentOutcome)
    unity.CurrentOutcome = 'aborted';
end

switch unity.Outcome_ID
    case {1} % 'correct'
        goodmonkey(100, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50);
    case {2, 9} % 'correct_mid', 'incorrect_mid'
        goodmonkey(50, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50); 
end

% Get trial data and save 
[data, trial, xml] = Unity_.GetTrialData(param_);
bhv_variable('VR_Data', data)  % To Save variables to file. 
bhv_variable('VR_Trial', trial)

% The XML header from the LSL streams contains the convertion values
% between State System phase name and number, and between objects' instance
% IDs and their name. It is redundant to save for every trial but there
% isn't an easy way to save a single struct for each file. 
bhv_variable('XML_Header', xml)

bhv_variable('Tobii_Gaze', Tobii_.GetTrialData(param_));

% Since MonkeyLogic only saves the calibrated eye data in degrees, we need
% to keep the calibration and pixels per degree values for analysis and 
% playback. 
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