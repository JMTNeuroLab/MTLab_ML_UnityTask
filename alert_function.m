function alert_function(hook,MLConfig,TrialRecord)
% NIMH MonkeyLogic
switch hook
    case 'task_start'   % when the task starts by '[Space] Start' from the pause menu
        % When launching a task we need to create the LSL in/outlets for: 
        % Unity -> ML: 
        %   Frame data
        %   Events and trial parameters 
        % ML -> Unity:
        %   Experimental control (e.g. start, stop, pause,...)
        
        % instantiate the LSL library
        TrialRecord.User.lsl_lib = lsl_loadlib();
        
        % create control outlet
        TrialRecord.User.control_markers = {'Begin', 'End', 'Pause', 'Resume'};
        
        info = lsl_streaminfo(TrialRecord.User.lsl_lib,...
            'ML_ControlStream',... Name
            'Markers',... Type: NEEDS TO BE EXACTLY THE SAME IN UNITY
            1,... Number of channels
            0,... Rate: 0 = IRREGULAR
            'cf_string',... Type
            'control1214'); % ID
        
        TrialRecord.User.control_outlet = lsl_outlet(info);
        % resolve the Frame and Event streams
        %try for 10 seconds
        timeout = tic;
        
        stream = {};
        while isempty(stream) && toc(timeout) < 10
            stream = lsl_resolve_byprop(TrialRecord.User.lsl_lib,'name','ML_FrameData', 1, 0.5);
        end
        if ~isempty(stream) 
            TrialRecord.User.frame_inlet = lsl_inlet(stream{1});
        else
            TrialRecord.User.frame_inlet = [];
        end
        
        stream = {};
        while isempty(stream) && toc(timeout) < 10
            stream = lsl_resolve_byprop(TrialRecord.User.lsl_lib,'name','ML_TrialData', 1, 0.5);
        end
        if ~isempty(stream)
            TrialRecord.User.trial_inlet = lsl_inlet(stream{1});
        else
            TrialRecord.User.trial_inlet = [];
        end
        
        pause(0.1)
        %tell Unity to start experiment. 
        eyecal_JSON = struct();
        eyecal_JSON.command_name = 'EyeCalibration';
        eyecal_JSON.eyecal_parameters.el_gains = MLConfig.EyeTracker.EyeLink.Source(1:2,4)';        %[gain_x, gain_y]
        eyecal_JSON.eyecal_parameters.el_offsets = MLConfig.EyeTracker.EyeLink.Source(1:2,3)';      %[offset_x, offset_y]
        eyecal_JSON.eyecal_parameters.t_offset = MLConfig.EyeTransform{1,1}.offset;                 %[offset_x, offset_y]
        eyecal_JSON.eyecal_parameters.t_rotation = MLConfig.EyeTransform{1,2};                      % [2,2]
        if isempty(eyecal_JSON.eyecal_parameters.t_rotation)
           eyecal_JSON.eyecal_parameters.t_rotation = eye(2);
        end
        eyecal_JSON.eyecal_parameters.t_transform = MLConfig.EyeTransform{1,3}.tdata.T;
        eyecal_JSON.eyecal_parameters.pix_per_deg = MLConfig.PixelsPerDegree(1);
        eyecal_JSON.eyecal_parameters.ml_x_res = MLConfig.Screen.Xsize;
        eyecal_JSON.eyecal_parameters.ml_y_res = MLConfig.Screen.Ysize;
        
        % Get EyeLink IP address and tracked eye
        eyecal_JSON.eyecal_parameters.el_IP = MLConfig.EyeTracker.EyeLink.IP_address;
        %LEFT = 0; RIGHT = 1;
        eyecal_JSON.eyecal_parameters.el_eyeID = MLConfig.EyeTracker.EyeLink.Source(1,1);
        
        %flatten all arrays to row vectors
        eyecal_JSON.eyecal_parameters.t_rotation = reshape(eyecal_JSON.eyecal_parameters.t_rotation',1,[]);
        eyecal_JSON.eyecal_parameters.t_transform = reshape(eyecal_JSON.eyecal_parameters.t_transform',1,[]);
                
        % To string:
        eyecal_JSON = jsonencode(eyecal_JSON);
%         display(eyecal_JSON)
        TrialRecord.User.control_outlet.push_sample({eyecal_JSON});  % push cell array
        
        
        TrialRecord.User.control_outlet.push_sample(ReturnLSLMessage(TrialRecord.User.control_markers{1}));
        
    case 'block_start'
        
    case 'trial_start'
        % ML is a passive observer, should not influence Unity on a trial
        % to trial basis. 

    case 'trial_end'
        % ML is a passive observer, should not influence Unity on a trial
        % to trial basis. 

    case 'block_end'
        
    case 'task_end'      % when '[q] Quit' is selected in the pause menu or the task stops with an error
        % Quit
        TrialRecord.User.control_outlet.push_sample(ReturnLSLMessage(TrialRecord.User.control_markers{2}));
        % wait for Unity's frame engine to pick the sample up before closing the streams 
        pause(0.1)  
        TrialRecord.User.control_outlet.delete();
        TrialRecord.User.control_outlet = [];

        if ~isempty(TrialRecord.User.frame_inlet)
            TrialRecord.User.frame_inlet.close_stream();
            TrialRecord.User.frame_inlet.delete();
            TrialRecord.User.frame_inlet = [];
        
%             TrialRecord.User.params_inlet.close_stream();
%             TrialRecord.User.params_inlet.delete();
%             TrialRecord.User.params_inlet = [];
        end
    case 'task_aborted'  % in case that the task stops with an error. The 'task_end' hook will follow.

    case 'task_paused'   % when the task is paused with ESC during the task
        % Pause
            TrialRecord.User.control_outlet.push_sample(ReturnLSLMessage(TrialRecord.User.control_markers{3}));
    case 'task_resumed'  % when the task is resumed by '[Space] Resume' from the pause menu
        % Resume
            TrialRecord.User.control_outlet.push_sample(ReturnLSLMessage(TrialRecord.User.control_markers{4}));
end

 %
    function msg = ReturnLSLMessage(in_command)
      msg = {jsonencode(struct('command_name', in_command))}; 
    end

end
