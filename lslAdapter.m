classdef lslAdapter < mladapter  % CHANGE THE CLASS NAME! The name of this file must be identical with it.
    properties
        % Define user variables here. They will be both readable and writable.
        CurrentOutcome  % Will read the outcome from the trial inlet
        Outcomes % Cell array of all possible Unity Outcomes
        Unity_to_ml_map % Array mapping the ML equivalent of Unity outcomes
        Outcome_ID % index of CurrentOutcome in the Outcomes cell array.
        
    end
    properties (SetAccess = protected)
        % Define output variables here. They will be only readable to users.
        
    end
    properties (Access = protected)
        % Define internal variables here. They won't be accessible from the outside of the class.
        
    end

    methods
        % To access the variables defined in the class, prefix 'obj.' to their names, like obj.Variable.
        % The first line of the constructor and four other methods (init, fini, analyze, draw) must be a call for the base class method.
        
        function obj = lslAdapter(varargin)  % CHANGE THIS LINE! The constructor name must be the same as the class name.
            obj = obj@mladapter(varargin{:});      % DO NOT DELETE THIS LINE. It is necessary to completes the adapter chain.
            
            % Things to do when the class is instantiated.
            
        end
        function delete(obj) %#ok<INUSD>
            % Things to do when this adapter is destroyed by MATLAB

        end
        
        function init(obj,p)
            init@mladapter(obj,p);  % DO NOT DELETE THIS LINE. It is necessary to completes the adapter chain.
            
            % Things to do just before the scene starts
            
        end
        function fini(obj,p)
            fini@mladapter(obj,p);  % DO NOT DELETE THIS LINE. It is necessary to completes the adapter chain.
            
            % Things to do right after the scene ends
            
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);  % DO NOT DELETE THIS LINE. It is necessary to completes the adapter chain.

            obj.CurrentOutcome = obj.Tracker.GetOutcome(); % Get only the current state
            
            if ~isempty(obj.CurrentOutcome)
                obj.Outcome_ID = find(ismember(obj.Outcomes, obj.CurrentOutcome), 1, 'first');

%                 if any(ismember(obj.Outcome_ID, obj.CorrectOutcomes))
                if obj.Unity_to_ml_map(obj.Outcome_ID) == 0
                    obj.Success = true;
                    continue_ = false;
                    return
%                 elseif any(ismember(obj.Outcome_ID, obj.IncorrectOutcomes))
                else
                    obj.Success = false;
                    continue_ = false;
                    return
                end
            else
                obj.Success = false;
            end
            %obj.Success = obj.Adapter.Success;
            
            % Things to do for behavior analysis
            % This function will be called once per each frame while the scene runs.
            %
            % To end the scene, returns false (i.e., assign false to continue).
            % obj.Success is typically used to indicate the detection of the target behavior.
            %
            % See WaitThenHold.m for an example.
            continue_ = ~obj.Success;
        end
        function draw(obj,p)
            draw@mladapter(obj,p);  % DO NOT DELETE THIS LINE. It is necessary to completes the adapter chain.
            
            % Things to do to update graphics
            % This function will be called every frame during the scene but after analyze() is called.
            
        end
    end
end
