# ML_UnityVR_Task
 Task directory for MonkeyLogic (Mar 23, 2019 build 182) to interface with Unity via LSL

Simply copy the repo in the task folder of monkeylogic. Keep in mind that the LSL library for Matlab was compiled for a 64bit windows 10 machine. You might need to recompile for your specific system. 

I'm using MonkeyLogic version Mar 23 2019 build 182. But I didn't change the source so it should work on anything after that. 

The installer I used should be in the gdrive link of the Temp repo. 


## LSL Build for Matlab on Windows 10
- Download and install Microsoft Visual Studio 
- Download and install CMake and Boost from the installers G-Drive. 
 -For CMake: check the box to add it to the path (for all users).
- Download and extract the zip file for LSL: liblsl-58b51d9ab933613ca70e8bba9ffaf415b4887e49.zip
- Open a command prompt and navigate to extracted LSL directory. 
  - `mkdir build`
  - `cd build`
  - `cmake-gui ..`
  - click `Configure` and select the proper Visual Studio installation, platform x64 and click `Finish`
  - Refer to [Here](https://github.com/sccn/labstreaminglayer/wiki/INSTALL) if errors. 
  - Click `Configure` again to validate. 
  - Click `Generate`.
  - Click `Open Project`. 
  - Change the target to Release (ADD PICTURE)
  - Right click on `INSTALL` in the solution explorer and click build. 
  - Once done, close everything. 
 - Copy the contents of the `../build/Release/` folder into the `../MonkeyLogic/task/ML_UnityVR_Task/libLSL/bin/` folder. 
 - Add all the ML_UnityVR_Task folder and sub-folders to the Matlab Path
 - Run `libLSL/build_mex.m`
 - Test run: `lib = lsl_loadlib(); outlet = lsl_outlet(lsl_streaminfo(lib, 'ML_ControlStream','LSL_Marker_Strings',1,0,'cf_string','control1214'));`
 
 Should work now. 
  
  
  

