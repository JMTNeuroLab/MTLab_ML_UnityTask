% In MonkeyLogic a tracker is the object responsible with interfacing with
% the data collection hardware/software. It receives calls to acquire
% samples and holds the tracer pointer to display on screen. 

% In this case it holds the pointers to the LSL frame inlet to receive
% frame data, time differences between the clocks and properly timestamps
% everything in monkeylogic time. 


classdef tobiiTracker < mltracker
    properties
        Tobii_Inlet  % LSL inlet for Tobii Gaze data from Unity
        Lib  % lsl_lib
    end
    properties (SetAccess = protected)
        Counter = 1  % position within the pre-allocated memory arrays

        % current gaze data from Tobii has 10 x sample data: 
        %   Left eye: 
        %       X in Active Display Coordinate System (normalized 0-1)
        %       Y in Active Display Coordinate System (normalized 0-1)
        %       Pupil Size
        %       Validity
        %   Right eye: 
        %       X in Active Display Coordinate System (normalized 0-1)
        %       Y in Active Display Coordinate System (normalized 0-1)
        %       Pupil Size
        %       Validity
        %   System Time: Computer clock time in useconds
        %   LSL time: computer clock time in seconds
        Gaze_Data = NaN(14, 120 * 250); % 120 sec @ 250 Hz
    end
    
    methods
        function obj = tobiiTracker(tobii_inlet, MLConfig)
            obj = obj@mltracker(MLConfig,[],[],[]);
            obj.Tobii_Inlet = tobii_inlet;
            obj.Signal = 'Tobii';
        end
        
        function tracker_init(obj,~)
            %Clear data
            obj.Counter = 1;
        end
        function tracker_fini(~,~)
           
        end
        function acquire(obj, p)
            
            % Gaze Data acquisition for tracker execution
            if ~isempty(obj.Tobii_Inlet)
                % stamps are on the remote (sender) clock time
                % To get proper time: 
                %   Local clock + time correction = remote clock;
                [chunk, timestamp] = obj.Tobii_Inlet.pull_chunk();
                if ~isempty(chunk)
                    temp_array = obj.ProcessChunk(chunk, timestamp, lsl_local_clock(obj.Lib), p.trialtime());
                    obj.Gaze_Data(:, obj.Counter:obj.Counter+size(temp_array,2)-1) = temp_array;
                    obj.Counter = obj.Counter + size(temp_array,2);

                    % make sure we have all the available samples
                    has_buffer = true;
                    while has_buffer
                        [chunk, timestamp] = obj.Tobii_Inlet.pull_chunk();
                        if isempty(chunk)
                            has_buffer = false;
                            continue
                        end
                        temp_array = obj.ProcessChunk(chunk, timestamp, lsl_local_clock(obj.Lib), p.trialtime());
                        obj.Gaze_Data(:, obj.Counter:obj.Counter+size(temp_array,2)-1) = temp_array;
                        obj.Counter = obj.Counter + size(temp_array,2);
                    end
                    obj.Success = true;
                else
                    obj.Success = false;
                end
            end
        end
        
        function temp_array = ProcessChunk(obj, chunk, timestamp, lsl_clock, trialtime)
            Time_Corr = obj.Tobii_Inlet.time_correction();
            temp_array = [chunk; % is a (10, x)
                nan(1, size(chunk,2)-1), Time_Corr;
                timestamp;
                nan(1, size(chunk,2)-1), lsl_clock;
                nan(1, size(chunk,2)-1), trialtime];
        end
        
        function sample = GetLastSample(obj)
            if obj.Counter > 1
                sample = obj.Gaze_Data(:,obj.Counter-1);
            else
                sample = [];
            end
        end
        
        function gaze_data = GetTrialData(obj, p)
            % get remaining frame samples in lsl stream
%             obj.acquire(p)
            
            % remove nan columns
            gaze_data = obj.Gaze_Data(:, 1:obj.Counter-1);
        end
    end
    
end
