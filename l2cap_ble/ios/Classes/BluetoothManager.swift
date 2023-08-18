//
//  BluetoothManager.swift
//  BLE-iOS
//
//  Created by Syed Ismail on 12.07.23.
//

import Foundation
import CoreBluetooth

public typealias DefaultCompletion = (Bool)->Void
public typealias ConnectionStateCompletion = (Int)->Void
public typealias SendCompletion = (Int16)->Void

public protocol BluetoothRepresentable {
    func connectToDevice(deviceId: String, completion: @escaping DefaultCompletion)
    func disconnectFromDevice(deviceId: String, completion: @escaping DefaultCompletion)
    func createL2CapChannel(psm: UInt16, completion: @escaping DefaultCompletion)
    func sendMessage(message: Data, completion: @escaping SendCompletion)
}

public class BluetoothManager: NSObject, CBPeripheralManagerDelegate {
       
    static let shared = BluetoothManager()
    private var cbCentral:CBCentralManager?
    private var peripheral: CBPeripheral?
    private var psmCharacteristic: CBCharacteristic?
    private var connectCompletion: DefaultCompletion?
    private var initiateConnectCompletion: DefaultCompletion?
    private var disConnectCompletion: DefaultCompletion?
    private var connectionStateCompletion: ConnectionStateCompletion?
    private var createChannelCompletion: DefaultCompletion?
    private var sendDataCompletion: SendCompletion?

    private var channel: CBL2CAPChannel?
    private var sendDataQueue = DispatchQueue(label: "BLE_QUEUE", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    private var outputData = Data()
    private var managerQueue = DispatchQueue.global(qos: .utility)
    private var peripheralManager: CBPeripheralManager?
    private var characteristic: CBMutableCharacteristic?
    private var deviceId: String?

   
    private override init() {
        super.init()
        cbCentral = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: managerQueue)
        self.peripheralManager?.delegate = self
    }
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
}
extension BluetoothManager: CBCentralManagerDelegate {
   

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
            cbCentral?.stopScan()
        case .poweredOn:
            print("poweredOn")
            cbCentral?.scanForPeripherals(withServices: nil, options: nil)
        @unknown default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if peripheral.identifier.uuidString == self.deviceId {
            self.connectToDevice(deviceId: peripheral.identifier.uuidString) { status in
                self.sendConnectionState(value: peripheral.state.rawValue)
                self.initiateConnectCompletion?(true)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if let identifier = self.peripheral?.identifier, let connectCompletion, identifier == peripheral.identifier {
            print("Connected \(peripheral.identifier)")
            self.sendConnectionState(value: peripheral.state.rawValue)
            peripheral.addObserver(self, forKeyPath: "state", options: .new, context: nil)
            connectCompletion(true)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        if let identifier = self.peripheral?.identifier,
            let connectCompletion,
            identifier == peripheral.identifier {
            print("failed to connect \(peripheral.identifier) \(String(describing: error))")
            self.sendConnectionState(value: 4)
            connectCompletion(false)
        }
    }
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        guard error == nil else {
            print("failed to disconnect peripheral \(peripheral) \(String(describing: error))")
            disConnectCompletion?(false)
            return
        }
       
        if let identifier = self.peripheral?.identifier,
           let disConnectCompletion,
            identifier == peripheral.identifier {
            print("Disconnected \(peripheral.identifier)")
            peripheral.removeObserver(self, forKeyPath: "state")
            disConnectCompletion(true)
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let peripheral = object as? CBPeripheral, keyPath == "state" {
            self.sendConnectionState(value: peripheral.state.rawValue)
        }
    }
    
    public func sendConnectionState(value: Int) {
        let updatatedValue = Int32(value)
        let dataToSend = ["state": NSNumber(value: updatatedValue)]
        NotificationCenter.default.post(name: Notification.Name("getConnectionStateNotification"), object: nil, userInfo: dataToSend)
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening l2cap channel - \(error.localizedDescription)")
            self.createChannelCompletion?(false)
            return
        }
        guard let channel = channel else {
            return
        }
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
        self.createChannelCompletion?(true)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Characteristic update error - \(error)")
            return
        }
        print("characteristics are \(characteristic)")
        
        if let dataValue = characteristic.value, !dataValue.isEmpty {
            let psm = dataValue.uint16
            print("Opening channel \(psm)")
            self.peripheral?.openL2CAPChannel(psm)
        } else {
            print("Problem decoding PSM")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            print("failed to disconnect peripheral \(peripheral) \(String(describing: error))")
            createChannelCompletion?(false)
            return
        }
       
        if let identifier = self.peripheral?.identifier,
           let createChannelCompletion,
            identifier == peripheral.identifier {
            print("channel opened \(peripheral) \(characteristic.properties)")
            createChannelCompletion(true)
        }
    }
}

extension BluetoothManager: BluetoothRepresentable {
    
    public func connectToDevice(deviceId: String, completion: @escaping DefaultCompletion) {

        self.deviceId = deviceId
        
        guard let uuid = UUID(uuidString: deviceId),
              let peripheral = self.cbCentral?.retrievePeripherals(withIdentifiers: [uuid]).first else {
            self.initiateConnectCompletion = completion
            return
        }
        self.connectCompletion = completion
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        self.cbCentral?.connect(peripheral)
    }
    
    public func disconnectFromDevice(deviceId: String, completion: @escaping DefaultCompletion) {

        self.disConnectCompletion = completion
        if let peripheral {
            self.cbCentral?.cancelPeripheralConnection(peripheral)
        }
    }
   
    
    public func createL2CapChannel(psm: UInt16, completion: @escaping DefaultCompletion) {
       
        self.createChannelCompletion = completion
        if let peripheral {
            peripheral.openL2CAPChannel(psm)
        }
    }
    
    public func sendMessage(message: Data, completion: @escaping SendCompletion) {

        self.sendDataCompletion = completion
        sendDataQueue.sync  {
            self.outputData.append(message)
        }
        self.send()
    }
    
    private func send() {
        
        guard let ostream = self.channel?.outputStream  else{
            return
        }
        let bytesWritten =  ostream.write(self.outputData)
        if let sendDataCompletion {
            sendDataCompletion(Int16(bytesWritten))
        }
        sendDataQueue.sync {
            if bytesWritten < outputData.count {
                outputData = outputData.advanced(by: Int(bytesWritten))
            } else {
                outputData.removeAll()
            }
        }
    }
}

extension BluetoothManager: StreamDelegate {
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {}
}

