cmake_minimum_required(VERSION 3.14)

project(ar_control_native LANGUAGES CXX)

# --- Ubicación de las Librerías Precompiladas de FFmpeg ---
# Se asume que ha colocado las librerías .so de FFmpeg en esta carpeta:
# android/app/src/main/jniLibs/${ANDROID_ABI}/
# CMAKE_SOURCE_DIR en este contexto es el directorio de este archivo CMakeLists.txt,
# que Flutter establece en android/app.
set(FFMPEG_LIBS_DIR ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI})

# --- Librería del Replay Engine ---
# Se asume que este CMakeLists.txt está en android/app/ y el código C++ está en lib/ui/remote/
add_library(
    replay_engine
    SHARED
    # Ruta al código fuente del Replay Engine
    ../../lib/ui/remote/replay_engine.cpp
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

# --- Incluir Cabeceras ---
# Asegúrate de que el compilador pueda encontrar los archivos .h de FFmpeg.
# Se asume que están en una carpeta 'include' junto a 'jniLibs'.
target_include_directories(replay_engine PRIVATE ${CMAKE_SOURCE_DIR}/src/main/jniLibs/include)

# --- Enlace con Librerías Nativas de Android ---
# Necesarias para logging y gráficos.
find_library(log-lib log)
find_library(jnigraphics-lib jnigraphics)

# --- Enlace Final ---
# Enlaza nuestra librería replay_engine con las de FFmpeg y las nativas de Android.
target_link_libraries(
    replay_engine
    avcodec
    avformat
    avutil
    swscale
    ${log-lib}
    ${jnigraphics-lib}
)

# --- Propiedades del Target ---
# Establece la visibilidad de los símbolos para una mejor optimización y convención.
set_target_properties(replay_engine PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    DEFINE_SYMBOL "REPLAY_ENGINE_EXPORT"
)