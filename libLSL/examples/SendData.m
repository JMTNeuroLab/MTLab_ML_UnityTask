% Test to control monkeylogic with LSL

%% instantiate the library
disp('Loading library...');
lib = lsl_loadlib();

% make a new stream outlet
disp('Creating a new streaminfo...');
frame_outlet = lsl_outlet(lsl_streaminfo(lib, ...
    'ML_ControlStream','LSL_Marker_Strings',1,0,'cf_string','control1214'));
%event_outlet = lsl_outlet(lsl_streaminfo(lib,'UnityEventStream','Markers',1,0,'cf_string','sdfwerr32432'));

% send data into the outlet, sample by sample
disp('Now transmitting data...');

%%
tic
data = [];
%while toc < 100 
 %   temp = "Gne";
    frame_outlet.push_sample({'BOB BOB BOB BOB'});
    
 %   pause(0.01);
%end