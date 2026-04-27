cmake_minimum_required(VERSION 3.14)
project(replay_engine)

# --- Ubicación de las Librerías Precompiladas de FFmpeg ---
# Se asume que ha colocado las librerías .so de FFmpeg en esta carpeta:
# android/app/src/main/jniLibs/${ANDROID_ABI}/
set(FFMPEG_LIBS_DIR ../jniLibs/${ANDROID_ABI})

# --- Librería del Replay Engine ---
# Se compila desde el código fuente ubicado en este mismo directorio.
add_library(
    replay_engine
    SHARED
    replay_engine.cpp
)

# --- Enlace con FFmpeg ---
# Añade las librerías de FFmpeg como IMPORTED para que CMake las encuentre.
add_library(avcodec SHARED IMPORTED)
set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavcodec.so)

add_library(avformat SHARED IMPORTED)
set_target_properties(avformat PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavformat.so)

add_library(avutil SHARED IMPORTED)
set_target_properties(avutil PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavutil.so)

add_library(swscale SHARED IMPORTED)
set_target_properties(swscale PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libswscale.so)

# --- Enlace con Librerías Nativas de Android ---
find_library(log-lib log)
find_library(jnigraphics-lib jnigraphics)

# --- Enlace Final ---
target_link_libraries(
    replay_engine
    avcodec
    avformat
    avutil
    swscale
    ${log-lib}
    ${jnigraphics-lib}
)