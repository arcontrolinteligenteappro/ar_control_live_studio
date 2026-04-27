#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Building Native Replay Engine ---"

# Navigate to the native source directory
cd native/replay_engine

# Create a build directory
mkdir -p build
cd build

# Configure the project with CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build the project
cmake --build . --config Release

echo "--- Build Complete ---"

# --- Copying Artifacts ---

cd ../../.. # Back to project root

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Copying for Linux..."
    cp native/replay_engine/build/libreplay_engine.so android/app/src/main/jniLibs/arm64-v8a/
    cp native/replay_engine/build/libreplay_engine.so linux/
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Copying for macOS..."
    # On macOS, CMake often produces a .dylib. For a framework, more steps are needed.
    # This is a simplified copy for a dynamic library.
    cp native/replay_engine/build/libreplay_engine.dylib macos/
else
    echo "Unsupported OS for this script. Please use build_native.bat on Windows."
fi

echo "--- Artifacts Copied Successfully ---"