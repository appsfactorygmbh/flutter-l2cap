//
//  BluetoothManagerExtensions.swift
//  BLE-iOS
//
//  Created by Syed Ismail on 12.07.23.
//

import Foundation
import CoreBluetooth

enum BluetoothConnectionState: Int {
    case disconnected = 0
    case connecting
    case connected
    case disconnecting
    case error
}

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Data {
    
    var uint16: UInt16 {
        get {
            let i16array = self.withUnsafeBytes { $0.load(as: UInt16.self) }
            return i16array
        }
    }
}

extension OutputStream {
    func write(_ data: Data) -> UInt8 {
        return data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> UInt8 in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return UInt8(self.write(bufferPointer.baseAddress!, maxLength: data.count))
        })
    }

}
