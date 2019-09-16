lib = lsl_loadlib();
results = lsl_resolve_all(lib, 1);
clc
for(i = 1:numel(results))
    results{i}.name
end

%%
clc
% instantiate the library
disp('Loading the library...');

inlets = {};

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};


while isempty(result)
    result = lsl_resolve_byprop(lib,'name','finger'); end

% create a new inlet
disp('Opening an inlet...');

inlet = lsl_inlet(result{1});

disp('Now receiving data...');
figure
hold on
set(gca, 'xlim', [-100 100])
set(gca, 'ylim', [-50 150])
h = plot(0,0,'.', 'markersize', 25);
while true
    
    %tic
    % get data from the inlet
    [vec,ts] = inlet.pull_sample(0);
    if ~isempty(vec)
        h.XData=vec(1);
        h.YData=vec(2);
    end
    
    pause(0.0001)
    %toc
    % and display it
%     fprintf('%.2f\t',vec);
%     fprintf('%.5f\n',ts);
end