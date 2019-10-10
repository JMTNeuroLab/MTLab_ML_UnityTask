%% Script to playback trial data from MonkeyLogic.
function UnityPlayback(filePath)

% Load session file ===================================================
fileHandle = mlread(filePath);
trials = arrayfun(@(x) num2str(x.Trial), fileHandle, 'uni', 0);

% LSL Streams =========================================================
lsl_lib = lsl_loadlib();

%Trial outlet
info = lsl_streaminfo(lsl_lib,...
    'ML_PlaybackTrial',... Name
    'Markers',... Type: NEEDS TO BE EXACTLY THE SAME IN UNITY
    1,... Number of channels
    0,... Rate: 0 = IRREGULAR
    'cf_string',... Type
    'trialPlayback1214'); % ID

trial_outlet = lsl_outlet(info);

timeout = tic;
stream = {};
while isempty(stream) && toc(timeout) < 10
    stream = lsl_resolve_byprop(lsl_lib,'name','ML_TrialData', 1, 0.5);
end
if ~isempty(stream)
    trial_inlet = lsl_inlet(stream{1});
else
    return;
end

%UI ===================================================================
fig = uifigure('Position',[100 500 150 300], 'units', 'pixels');
uilabel(fig, 'Position', [5 280 140 25], 'Text', 'Select Trials');

lbox = uilistbox(fig,...
    'Position',[5 100 140 170],...
    'Items',trials,'Multiselect', 'on');

uibutton(fig,'Position', [5 50 140 25], 'Text', 'GO', ...
    'ButtonPushedFcn',@startMainLoop);

    function startMainLoop(~, ~)
        sel = lbox.Value;
        close(fig);
        
        for s = sel
            %Eye Calibration data
            %tell Unity to start experiment.
            eyecal_JSON = struct();
            eyecal_JSON.command_name = 'EyeCalibration';
            eyecal_JSON.eyecal_parameters.el_gains = fileHandle(str2double(s)).UserVars.Eye_Calibration.el_gains;
            eyecal_JSON.eyecal_parameters.el_offsets = fileHandle(str2double(s)).UserVars.Eye_Calibration.el_offsets;
            eyecal_JSON.eyecal_parameters.t_offset = fileHandle(str2double(s)).UserVars.Eye_Calibration.t_offset;
            eyecal_JSON.eyecal_parameters.t_rotation = fileHandle(str2double(s)).UserVars.Eye_Calibration.t_rotation;
            eyecal_JSON.eyecal_parameters.t_transform = fileHandle(str2double(s)).UserVars.Eye_Calibration.t_transform;
            eyecal_JSON.eyecal_parameters.pix_per_deg = fileHandle(str2double(s)).UserVars.Eye_Calibration.pix_per_deg;
            eyecal_JSON.eyecal_parameters.ml_x_res = fileHandle(str2double(s)).UserVars.Eye_Calibration.ml_x_res;
            eyecal_JSON.eyecal_parameters.ml_y_res = fileHandle(str2double(s)).UserVars.Eye_Calibration.ml_y_res;
            eyecal_JSON.eyecal_parameters.el_IP = '127.0.0.1';
            eyecal_JSON.eyecal_parameters.el_eyeID = 0;
            eyecal_JSON.eyecal_parameters.t_rotation = reshape(eyecal_JSON.eyecal_parameters.t_rotation',1,[]);
            eyecal_JSON.eyecal_parameters.t_transform = reshape(eyecal_JSON.eyecal_parameters.t_transform',1,[]);
            % To string:
            eyecal_JSON = jsonencode(eyecal_JSON);
            trial_outlet.push_sample({eyecal_JSON});  % push cell array
            
            % Trial Parameters
            trial_struct = struct();
            trial_struct.command_name = 'TrialParameters';
            trial_struct.trial_parameters.Trial_Number = fileHandle(str2double(s)).UserVars.VR_Trial.Trial_Number;
            trial_struct.trial_parameters.Start_Position = fileHandle(str2double(s)).UserVars.VR_Trial.Start_Position;
            trial_struct.trial_parameters.cue_Objects = fileHandle(str2double(s)).UserVars.VR_Trial.cue_Objects;
            trial_struct.trial_parameters.cue_Material = fileHandle(str2double(s)).UserVars.VR_Trial.cue_Material;
            trial_struct.trial_parameters.target_Objects = fileHandle(str2double(s)).UserVars.VR_Trial.target_Objects;
            trial_struct.trial_parameters.target_Materials = fileHandle(str2double(s)).UserVars.VR_Trial.target_Materials;
            trial_struct.trial_parameters.Target_Positions = fileHandle(str2double(s)).UserVars.VR_Trial.Target_Positions;
            trial_struct.trial_parameters.distractor_Objects = fileHandle(str2double(s)).UserVars.VR_Trial.distractor_Objects;
            trial_struct.trial_parameters.Distractor_Positions = fileHandle(str2double(s)).UserVars.VR_Trial.Distractor_Positions;
            trial_struct.trial_parameters.distractor_Materials = fileHandle(str2double(s)).UserVars.VR_Trial.distractor_Materials;
            trial_struct.trial_parameters.n_Frames = size(fileHandle(str2double(s)).UserVars.VR_Data,2);
            %To string;
            trial_string = jsonencode(trial_struct);
            trial_outlet.push_sample({trial_string});
            
            if (strcmp(trial_string, '[]'))
                warning(['Trial #' s{1} ' ignored']);
                continue
            else
                frame_data = prepFrameData(fileHandle(str2double(s)).UserVars.VR_Data);
                
                trial_outlet.push_sample({trial_string});
                frame_struct = struct();
                frame_struct.command_name = 'TrialData';
                
                for ii = 1:size(frame_data, 2)
                    pause(0.005)
                    frame_struct.trial_data.data = frame_data(:,ii);
                    trial_outlet.push_sample({jsonencode(frame_struct)});
                    
                end
                trial_outlet.push_sample({'{"command_name":"StartPlayback"}'});
            end
            playing = true;
            while playing
                [s,~] = trial_inlet.pull_sample(0);
                
                if any(cellfun(@(x) strcmp(x, "Done"), s))
                    playing = false;
                end
                
            end
            pause(0.1);
        end
        
    end


    function data = prepFrameData(rawData)
        % Frame Data is a 26 x Samples array
        %  1: Pos X
        %  2: Pos Y
        %  3: Pos Z
        %  4: Rot
        %  5: Joystick X
        %  6: Joystick Y
        %  7: Collision Object InstanceID
        %  8: Gaze X
        %  9: Gaze Y
        %  10:14 Gaze collision object instanceIDs
        %  15:19 Gaze ray hit counts (max 33: 1 center and 4x8 circles)
        %  20: Trial State
        %  21: Photo Diode intensity
        %  22: Unity LSL local time
        %  23 Time Correction between the two LSL clocks
        %  24: Sample TimeStamp
        %  25: Local LSL TimeStamp
        %  26: MonkeyLogic Trial Time
        % We only need : 1,2,3,4,8,9,20
        data=rawData([1,2,3,4,8,9,20], :);
        
        % convert eye data (8,9) to pixels
        % Unity (0,0) is bottom left
        % This ASSUMES THAT UNITY HAS THE SAME RESOLUTION AS ML
        % data(5) = (data(5) * eyecal.pix_per_deg) + 0.5 * eyecal.ml_x_res;
        % data(6) = (data(6) * eyecal.pix_per_deg) + 0.5 * eyecal.ml_y_res;
        
    end

end