% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'name','ML_FrameData', 1, 0.5);
end
% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

%%
disp('Now receiving chunked data...');
data = [];
a = true;
while a
    % get chunk from the inlet
    [sample, timestamp] = inlet.pull_sample(0);
    if isempty(sample)
       a = false; 
    end
%     for s=1:length(stamps)
%         % and display it
%         fprintf('%.2f\t',chunk(:,s));
%         fprintf('%.5f\n',stamps(s));
%     end
    data = [data sample];
    pause(0.05);
end