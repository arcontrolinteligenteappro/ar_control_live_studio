import Flutter
import UIKit
import CoreMIDI
import Network

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let MIDI_CHANNEL = "com.arcontrol.midi"
  private let PTZ_CHANNEL = "com.arcontrol.ptz"

  private var midiClient = MIDIClientRef()
  private var midiInputPort = MIDIPortRef()
  private var midiOutputPort = MIDIPortRef()
  private var midiDevices: [String: MIDIEndpointRef] = [:]
  private var ptzCameras: [String: PtzCamera] = [:]

  private var receivedMidiMessages: [String] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Initialize MIDI
    setupMidi()

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Setup MIDI MethodChannel
    let midiChannel = FlutterMethodChannel(name: MIDI_CHANNEL, binaryMessenger: engineBridge.binaryMessenger)
    midiChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMidiCall(call, result: result)
    }

    // Setup PTZ MethodChannel
    let ptzChannel = FlutterMethodChannel(name: PTZ_CHANNEL, binaryMessenger: engineBridge.binaryMessenger)
    ptzChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handlePtzCall(call, result: result)
    }
  }

  private func setupMidi() {
    var clientName = "AR Control MIDI Client" as CFString
    let status = MIDIClientCreateWithBlock(clientName, &midiClient) { [weak self] notification in
      self?.handleMidiNotification(notification)
    }

    if status == noErr {
      // Create input port
      var inputPortName = "AR Control Input" as CFString
      let inputStatus = MIDIInputPortCreateWithBlock(midiClient, inputPortName, &midiInputPort) { [weak self] packetList, srcConnRefCon in
        self?.handleMidiPacketList(packetList, srcConnRefCon: srcConnRefCon)
      }

      // Create output port
      var outputPortName = "AR Control Output" as CFString
      let outputStatus = MIDIOutputPortCreate(midiClient, outputPortName, &midiOutputPort)
    }
  }

  private func handleMidiCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanMidiDevices":
      scanMidiDevices(result: result)
    case "testMidiConnectivity":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceId is required", details: nil))
        return
      }
      testMidiConnectivity(deviceId: deviceId, result: result)
    case "sendMidiMessage":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            let message = args["message"] as? [Int] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceId and message are required", details: nil))
        return
      }
      sendMidiMessage(deviceId: deviceId, message: message, result: result)
    case "testMidiReceive":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceId is required", details: nil))
        return
      }
      let timeout = args["timeout"] as? Int ?? 2000
      testMidiReceive(deviceId: deviceId, timeout: timeout, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handlePtzCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanPtzCameras":
      scanPtzCameras(result: result)
    case "testPtzConnectivity":
      guard let args = call.arguments as? [String: Any],
            let cameraId = args["cameraId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "cameraId is required", details: nil))
        return
      }
      testPtzConnectivity(cameraId: cameraId, result: result)
    case "ptzMove":
      guard let args = call.arguments as? [String: Any],
            let cameraId = args["cameraId"] as? String,
            let pan = args["pan"] as? Double,
            let tilt = args["tilt"] as? Double else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "cameraId, pan, and tilt are required", details: nil))
        return
      }
      let speed = args["speed"] as? Double ?? 0.5
      ptzMove(cameraId: cameraId, pan: pan, tilt: tilt, speed: speed, result: result)
    case "ptzStop":
      guard let args = call.arguments as? [String: Any],
            let cameraId = args["cameraId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "cameraId is required", details: nil))
        return
      }
      ptzStop(cameraId: cameraId, result: result)
    case "ptzZoom":
      guard let args = call.arguments as? [String: Any],
            let cameraId = args["cameraId"] as? String,
            let zoom = args["zoom"] as? Double else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "cameraId and zoom are required", details: nil))
        return
      }
      ptzZoom(cameraId: cameraId, zoom: zoom, result: result)
    case "ptzRecallPreset":
      guard let args = call.arguments as? [String: Any],
            let cameraId = args["cameraId"] as? String,
            let preset = args["preset"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "cameraId and preset are required", details: nil))
        return
      }
      ptzRecallPreset(cameraId: cameraId, preset: preset, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func scanMidiDevices(result: @escaping FlutterResult) {
    var devices: [[String: Any]] = []

    // Scan MIDI destinations (output devices)
    let destinationCount = MIDIGetNumberOfDestinations()
    for i in 0..<destinationCount {
      let endpoint = MIDIGetDestination(i)
      if let deviceInfo = getMidiDeviceInfo(endpoint: endpoint) {
        devices.append(deviceInfo)
        midiDevices[deviceInfo["id"] as! String] = endpoint
      }
    }

    // Scan MIDI sources (input devices)
    let sourceCount = MIDIGetNumberOfSources()
    for i in 0..<sourceCount {
      let endpoint = MIDIGetSource(i)
      if let deviceInfo = getMidiDeviceInfo(endpoint: endpoint) {
        // Avoid duplicates
        if !devices.contains(where: { $0["id"] as? String == deviceInfo["id"] as? String }) {
          devices.append(deviceInfo)
          midiDevices[deviceInfo["id"] as! String] = endpoint
        }
      }
    }

    result(devices)
  }

  private func getMidiDeviceInfo(endpoint: MIDIEndpointRef) -> [String: Any]? {
    var name: Unmanaged<CFString>?
    let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name)

    if status == noErr, let deviceName = name?.takeRetainedValue() as String? {
      return [
        "id": String(endpoint),
        "name": deviceName,
        "manufacturer": "Unknown",
        "product": deviceName,
        "type": "midi",
        "connected": true
      ]
    }

    return nil
  }

  private func testMidiConnectivity(deviceId: String, result: @escaping FlutterResult) {
    if let endpoint = midiDevices[deviceId] {
      result("connected")
    } else {
      result("disconnected")
    }
  }

  private func sendMidiMessage(deviceId: String, message: [Int], result: @escaping FlutterResult) {
    guard let endpoint = midiDevices[deviceId] else {
      result(FlutterError(code: "DEVICE_NOT_FOUND", message: "MIDI device not found", details: nil))
      return
    }

    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)

    let byteMessage = message.map { UInt8($0) }
    let timestamp = mach_absolute_time()

    MIDIPacketListAdd(&packetList, 1024, packet, timestamp, byteMessage.count, byteMessage)

    let status = MIDISend(midiOutputPort, endpoint, &packetList)

    if status == noErr {
      result("sent")
    } else {
      result(FlutterError(code: "SEND_FAILED", message: "Failed to send MIDI message", details: nil))
    }
  }

  private func testMidiReceive(deviceId: String, timeout: Int, result: @escaping FlutterResult) {
    guard let endpoint = midiDevices[deviceId] else {
      result(FlutterError(code: "DEVICE_NOT_FOUND", message: "MIDI device not found", details: nil))
      return
    }

    receivedMidiMessages.removeAll()

    let status = MIDIPortConnectSource(midiInputPort, endpoint, nil)

    if status == noErr {
      // Wait for messages
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeout)) {
        MIDIPortDisconnectSource(self.midiInputPort, endpoint)
        result(self.receivedMidiMessages.isEmpty ? "no_messages" : "received")
      }
    } else {
      result("connection_failed")
    }
  }

  private func scanPtzCameras(result: @escaping FlutterResult) {
    // Simulate PTZ camera discovery
    let cameras: [[String: Any]] = [
      [
        "id": "ptz_1",
        "name": "PTZ Camera 1",
        "model": "Sony BRC-X1000",
        "ip": "192.168.1.100",
        "port": 80,
        "type": "ptz",
        "connected": true,
        "presets": [1, 2, 3, 4, 5]
      ],
      [
        "id": "ptz_2",
        "name": "PTZ Camera 2",
        "model": "Panasonic AW-HE130",
        "ip": "192.168.1.101",
        "port": 80,
        "type": "ptz",
        "connected": true,
        "presets": [1, 2, 3, 4, 5]
      ]
    ]

    for camera in cameras {
      if let id = camera["id"] as? String,
         let ip = camera["ip"] as? String {
        ptzCameras[id] = PtzCamera(id: id, ip: ip, port: 80, username: "admin", password: "admin")
      }
    }

    result(cameras)
  }

  private func testPtzConnectivity(cameraId: String, result: @escaping FlutterResult) {
    guard let camera = ptzCameras[cameraId] else {
      result("camera_not_found")
      return
    }

    // Simple connectivity test using URLSession
    let url = URL(string: "http://\(camera.ip):\(camera.port)/")!
    let task = URLSession.shared.dataTask(with: url) { _, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        result("connected")
      } else {
        result("disconnected")
      }
    }
    task.resume()
  }

  private func ptzMove(cameraId: String, pan: Double, tilt: Double, speed: Double, result: @escaping FlutterResult) {
    guard let camera = ptzCameras[cameraId] else {
      result(FlutterError(code: "CAMERA_NOT_FOUND", message: "PTZ camera not found", details: nil))
      return
    }

    let url = URL(string: "http://\(camera.ip):\(camera.port)/ptz")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = [
      "command": "move",
      "pan": pan,
      "tilt": tilt,
      "speed": speed
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: request) { _, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        result("moved")
      } else {
        result(FlutterError(code: "MOVE_FAILED", message: "Failed to move camera", details: nil))
      }
    }
    task.resume()
  }

  private func ptzStop(cameraId: String, result: @escaping FlutterResult) {
    guard let camera = ptzCameras[cameraId] else {
      result(FlutterError(code: "CAMERA_NOT_FOUND", message: "PTZ camera not found", details: nil))
      return
    }

    let url = URL(string: "http://\(camera.ip):\(camera.port)/ptz")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = ["command": "stop"]
    request.httpBody = try? JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: request) { _, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        result("stopped")
      } else {
        result(FlutterError(code: "STOP_FAILED", message: "Failed to stop camera", details: nil))
      }
    }
    task.resume()
  }

  private func ptzZoom(cameraId: String, zoom: Double, result: @escaping FlutterResult) {
    guard let camera = ptzCameras[cameraId] else {
      result(FlutterError(code: "CAMERA_NOT_FOUND", message: "PTZ camera not found", details: nil))
      return
    }

    let url = URL(string: "http://\(camera.ip):\(camera.port)/ptz")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = [
      "command": "zoom",
      "zoom": zoom
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: request) { _, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        result("zoomed")
      } else {
        result(FlutterError(code: "ZOOM_FAILED", message: "Failed to zoom camera", details: nil))
      }
    }
    task.resume()
  }

  private func ptzRecallPreset(cameraId: String, preset: Int, result: @escaping FlutterResult) {
    guard let camera = ptzCameras[cameraId] else {
      result(FlutterError(code: "CAMERA_NOT_FOUND", message: "PTZ camera not found", details: nil))
      return
    }

    let url = URL(string: "http://\(camera.ip):\(camera.port)/ptz")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = [
      "command": "recall_preset",
      "preset": preset
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: request) { _, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        result("preset_recalled")
      } else {
        result(FlutterError(code: "PRESET_FAILED", message: "Failed to recall preset", details: nil))
      }
    }
    task.resume()
  }

  private func handleMidiNotification(_ notification: UnsafePointer<MIDINotification>) {
    // Handle MIDI notifications (device connections/disconnections)
  }

  private func handleMidiPacketList(_ packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) {
    receivedMidiMessages.append("received")
  }
}

struct PtzCamera {
  let id: String
  let ip: String
  let port: Int
  let username: String
  let password: String
}
