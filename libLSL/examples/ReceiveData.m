%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'name','ML_FrameData'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving data...');

while true
    clc
    %tic
    % get data from the inlet
    [vec,ts] = inlet.pull_sample(0);
    if ~isempty(vec)
        vec
    end
    
    pause(0.005)
    %toc
    % and display it
%     fprintf('%.2f\t',vec);
%     fprintf('%.5f\n',ts);
end