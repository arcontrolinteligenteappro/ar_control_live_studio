# 📡 AR Control Live Studio OS (OB VAN PRO)

**AR Control Live Studio** no es una simple aplicación, es un **Sistema Operativo Audiovisual Distribuido** que transforma cualquier red de dispositivos (Smartphones, Tablets, PCs, Smart TVs) en una productora profesional broadcast.

## 🌟 Arquitectura de Nodos (Topología de Red)

El ecosistema se distribuye en 4 roles que se auto-descubren en la red local vía **UDP/TCP (Puertos 8888/8889)**:

1. **ENGINE (Studio Mode):** Cerebro central. Procesa video, audio, gráficos (CG), grabación y streaming.
2. **CAMERA (Single Mode):** Dispositivo operando como lente en terreno (Run & Gun) con teleprompter.
3. **REMOTE (Stream Deck):** Mando a distancia táctico para controlar el Switcher, Macros y Replays.
4. **PLAYER (Monitor):** Pantalla limpia receptora inalámbrica (Multiviewer).

## 🚀 Motores Principales (Engines)

*   🎥 **Switcher Engine:** Pipeline Zero-Copy para mezcla de señales de video, cortes (CUT) y fundidos cruzados (AUTO).
*   🎛️ **Audio Engine Pro:** Procesamiento 32-bit float, ecualización 3-bandas, mixer profesional con 4 canales (Mic1, Mic2, Music, FX).
*   🎨 **Overlay Engine (CG):** Generador de caracteres para Lower Thirds, moscas y Marcadores Deportivos dinámicos.
*   ⏪ **Replay Engine:** Búfer circular instantáneo para capturar y emitir jugadas destacadas.
*   🔴 **Record Engine:** Grabación 4K en memoria interna usando hilos aislados.
*   📡 **Restream Engine:** Transmisión simultánea RTMP a YouTube, Facebook, Twitch, etc.
*   🤖 **AI Engine:** Auto-Director basado en actividad de audio (ponchado automático) y auto-replay.
*   🎧 **DJ Engine:** 2 Decks interactivos con sincronización de BPM y Crossfader.
*   🕹️ **Hardware Engine:** Abstracción HAL para mapear controladores físicos (MIDI/Gamepad) y comandos PTZ reales (VISCA/Pelco-D).
*   🌐 **NDI Engine:** Servidor de transmisión IP de latencia cero para conectar la señal a vMix/OBS de escritorio.
*   📝 **Teleprompter Engine:** Lector de guiones superpuesto a la cámara con ajuste de velocidad y tamaño en vivo.
*   🧩 **Plugin Engine:** Host de extensiones para cargar código dinámico sin recompilar.

## ✨ Funcionalidades Implementadas

### 🎥 Integración PTZ Real
- **Protocolo VISCA:** Comunicación TCP/IP con cámaras PTZ profesionales
- **Comandos Soportados:** Pan, Tilt, Zoom con control de velocidad
- **Auto-Discovery:** Detección automática de cámaras en la red
- **Configuración:** IP y puerto personalizables

### 🌐 Streaming NDI Profesional
- **NDI 5.0:** Transmisión IP de ultra baja latencia
- **Auto-Discovery:** Encuentra automáticamente fuentes NDI en la red
- **Multi-Fuente:** Soporte para múltiples streams simultáneos
- **Integración:** Compatible con OBS Studio, vMix, Resolume

### 🎛️ Audio Mixer Profesional
- **4 Canales:** Mic1, Mic2, Music, FX con controles independientes
- **EQ 3-Bandas:** Low/Mid/High con ajuste ±12dB
- **Master Section:** Control de volumen y pan global
- **Level Meters:** Monitoreo visual de niveles en tiempo real
- **Grabación:** Captura de audio multipista

## 🛠️ Instalación y Compilación

### Requisitos Previos
- **General:** Flutter SDK (>=3.11.0)
- **Android:** Android Studio
- **iOS / macOS:** Xcode (Mac obligatorio)
- **Windows:** Visual Studio 2022 (Desarrollo para escritorio con C++)
- **Linux:** CMake, ninja-build, libgtk-3-dev

### 1. Activar Soporte Multiplataforma
Si es tu primera vez compilando para escritorio, abre tu terminal y ejecuta:
```bash
flutter config --enable-windows-desktop --enable-macos-desktop --enable-linux-desktop
flutter create --platforms=android,ios,windows,macos,linux .
```

### 2. Configuración de Permisos por Sistema (IMPORTANTE)

**🍎 Para iOS (ios/Runner/Info.plist):**
Debes agregar los permisos de cámara, micrófono y red local:
```xml
<key>NSCameraUsageDescription</key>
<string>Requerido para el Motor de Captura (Single Mode)</string>
<key>NSMicrophoneUsageDescription</key>
<string>Requerido para el Motor de Audio Pro</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Requerido para descubrir Nodos y NDI en la LAN</string>
<key>NSBonjourServices</key>
<array>
  <string>_ndi._tcp</string>
</array>
```

**🍏 Para macOS (macos/Runner/DebugProfile.entitlements y Release.entitlements):**
Al ser una app tipo Servidor UDP/TCP, macOS te bloqueará los sockets si no habilitas el cliente/servidor de red y la cámara:
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
```

**🪟 Para Windows:**
Windows generará una alerta del "Firewall de Windows Defender" la primera vez que abras el Modo *Studio* o *OV Vand* debido a los puertos UDP 8888 y TCP 8889. El usuario debe darle en **"Permitir acceso"** para que el Clúster de nodos funcione.

### 3. Comandos de Compilación (Release)

Asegúrate de limpiar el caché y actualizar dependencias antes de compilar:
```bash
flutter clean && flutter pub get
```

**Android (APK):**
```bash
flutter build apk --release
```

**Windows (.exe):**
```bash
flutter build windows --release
```

**macOS (.app):**
```bash
flutter build macos --release
```

**iOS (.ipa - Requiere cuenta Apple Developer):**
```bash
flutter build ipa --release
```

**Linux (Binario):**
```bash
flutter build linux --release
```

## 🕹️ Modos de Operación (UI)

*   **SINGLE MODE:** Interfaz limpia con teleprompter, controles rápidos y cámara fullscreen.
*   **STUDIO MODE:** Tablero de producción. Incluye Multiviewer, Faders de Audio, panel de Macros y control DJ.
*   **OV VAND MODE:** Centro de Ingeniería. Muestra el estado del CPU, clúster de red y gestión de plugins.
*   **REMOTE MODE:** Botonera gigante en cuadrícula con respuesta háptica.
*   **PLAYER MODE:** Monitor "tonto" para despliegue de señales de Prev/Prog y Gráficos.

---
*Elaborado por ChrisRey91 / www.arcontrolinteligente.com*

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
