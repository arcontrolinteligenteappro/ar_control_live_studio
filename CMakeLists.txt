cmake_minimum_required(VERSION 3.14)
project(replay_engine LANGUAGES CXX)

# --- FFmpeg Dependency ---
# Find the required FFmpeg libraries.
# For this to work, you must have FFmpeg installed on your system and
# its pkg-config files (.pc) must be discoverable.
# Alternatively, you can set CMAKE_PREFIX_PATH to your FFmpeg installation directory.
find_package(PkgConfig REQUIRED)
pkg_check_modules(AVFORMAT REQUIRED libavformat)
pkg_check_modules(AVCODEC REQUIRED libavcodec)
pkg_check_modules(AVUTIL REQUIRED libavutil)
pkg_check_modules(SWSCALE REQUIRED libswscale)

# Add the source file for the library
add_library(replay_engine SHARED
    src/replay_engine.cpp
)

# Link against the found FFmpeg libraries
target_link_libraries(replay_engine PRIVATE
    ${AVFORMAT_LIBRARIES}
    ${AVCODEC_LIBRARIES}
    ${AVUTIL_LIBRARIES}
    ${SWSCALE_LIBRARIES}
)

# Include directories for FFmpeg headers
target_include_directories(replay_engine PRIVATE
    ${AVFORMAT_INCLUDE_DIRS}
    ${AVCODEC_INCLUDE_DIRS}
    ${AVUTIL_INCLUDE_DIRS}
    ${SWSCALE_INCLUDE_DIRS}
)

# Set properties for visibility and naming conventions
set_target_properties(replay_engine PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    DEFINE_SYMBOL "REPLAY_ENGINE_EXPORT"
)