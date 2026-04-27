@echo off
echo --- Building Native Replay Engine for Windows ---

REM Navigate to the native source directory
cd native\replay_engine

REM Create a build directory
if not exist build mkdir build
cd build

REM Configure the project with CMake. Assumes Visual Studio generator.
REM You might need to specify the generator with -G "Visual Studio 17 2022"
cmake ..

REM Build the project in Release mode
cmake --build . --config Release

echo --- Build Complete ---

cd ..\..\..

echo Copying DLL to appropriate location...
copy native\replay_engine\build\Release\replay_engine.dll windows\runner\

echo --- Artifacts Copied Successfully ---