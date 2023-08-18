import Flutter
import UIKit

public class L2capBlePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "l2cap_ble", binaryMessenger: registrar.messenger())
        let instance = L2capBlePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        

        // Register the event channel
        let eventChannel = FlutterEventChannel(name: "getConnectionState", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    override private init() {
        super.init()
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        NotificationCenter.default.addObserver(
             self,
             selector: #selector(L2capBlePlugin.getConnectionState(notification:)),
             name: Notification.Name("getConnectionStateNotification"),
             object: nil)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    @objc func getConnectionState(notification: Notification) {
        // Ensure there is an eventSink before sending the event
        
        guard let eventSink = self.eventSink,
        let userInfo = notification.userInfo,
        let updatedState = userInfo["state"] as? Int32 else {
            return
        }
        // Emit the connection state as an event
        eventSink(updatedState)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        switch call.method {
        case "connectToDevice":
            if let arguments = call.arguments as? [String: Any],
               let deviceId = arguments["deviceId"] as? String {
                BluetoothManager.shared.connectToDevice(deviceId: deviceId) { status in
                    if status {
                        print("connection successful")
                        result(true)
                    } else {
                        result(false)
                    }
                }
            }
        case "disconnectFromDevice":
            print("calling disconnect")
            if let arguments = call.arguments as? [String: Any],
               let deviceId = arguments["deviceId"] as? String {
                BluetoothManager.shared.disconnectFromDevice(deviceId: deviceId) { status in
                    if status {
                        print("disconnected successful")
                        result(true)
                    } else {
                        result(false)
                    }
                }
            }
            result(true)
        case "createL2capChannel":
            if let arguments = call.arguments as? [String: Any],
               let psm = arguments["psm"] as? UInt16 {
                BluetoothManager.shared.createL2CapChannel(psm: psm) { status in
                    if status {
                        print("created L2CAP channel")
                        result(true)
                    } else {
                        print("Failed to create L2CAP channel")
                        result(false)
                    }
                }
            }
        case "sendMessage":
            if let arguments = call.arguments as? [String: Any],
               let message = arguments["message"] as? FlutterStandardTypedData {
                
                if let byteArray = self.parseFlutterStandardTypedDataToData(message) {
                    BluetoothManager.shared.sendMessage(message: byteArray) { response in
                        let data = self.convertInt16ToData(response)
                        let stringValue = String(data: data, encoding: .utf8) ?? ""
                        print("Returned data is \(response) \(stringValue)")
                        result(self.parseDataToFlutterStandardTypedData(data))
                    }
                } else {
                    result(nil)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func parseFlutterStandardTypedDataToData(_ data: FlutterStandardTypedData) -> Data? {
        return data.data
    }
    
    func parseDataToFlutterStandardTypedData(_ data: Data) -> FlutterStandardTypedData {
        return FlutterStandardTypedData(bytes: data)
    }
    
    func convertInt16ToData(_ value: Int16) -> Data {
        var intValue = value
        return Data(bytes: &intValue, count: MemoryLayout<Int16>.size)
    }
}
