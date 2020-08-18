/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public struct ConfigHeartbeatPublicationSet: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8039
    public static let responseType: StaticMeshMessage.Type = ConfigHeartbeatPublicationStatus.self
    
    public var parameters: Data? {
        var data = Data() + destination
        data += countLog
        data += periodLog
        data += ttl
        data += features.rawValue
        data += networkKeyIndex
        return data
    }
    
    public let networkKeyIndex: KeyIndex

    /// Destination address for Heartbeat messages.
    ///
    /// The Heartbeat Publication Destination shall be the Unassigned Address, a Unicast
    /// Address, or a Group Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Publication Destination is set to the Unassigned Address, the
    /// Heartbeat messages are not being sent.
    public let destination: Address
    /// Number of Heartbeat messages remaining to be sent.
    ///
    /// Possible values:
    /// - 0x00 - Periodic Heartbeat messages are not published.
    /// - 0x01 - 0x11 - Number of Heartbeat messages, 2^(n-1), that remain to be sent.
    /// - 0xFF - Periodic Heartbeat messages are publishedbeing sent indefinitely.
    /// - Other values are prohibited.
    ///
    /// The Heartbeat Publication Count Log is a representation of the Heartbeat Publication
    /// Count state value. The Heartbeat Publication Count Log and Heartbeat Publication Count
    /// with the value 0x00 and 0x0000 are equivalent. The Heartbeat Publication Count Log
    /// value of 0xFF is equivalent to the Heartbeat Publication count value of 0xFFFF.
    /// The Heartbeat Publication Count Log value between 0x01 and 0x11 shall represent that
    /// smallest integer n where 2^(n-1) is greater than or equal to the Heartbeat Publication
    /// Count value. For example, if the Heartbeat Publication Count value is 0x0579, then the
    /// Heartbeat Publication Count Log value would be 0x0C.
    internal let countLog: UInt8
    /// Period for sending Heartbeat messages.
    ///
    /// Possible values:
    /// - 0x00 - Periodic Heartbeat messages are not published.
    /// - 0x01 - 0x11 - Publication period represented as 2^(n-1) seconds.
    /// - Other values are prohibited.
    ///
    /// The value is represented as 2^(n-1) seconds. For example, the value 0x04 would
    /// have a publication period of 8 seconds, and the value 0x07 would have a publication
    /// period of 64 seconds.
    internal let periodLog: UInt8
    /// TTL to be used when sending Heartbeat messages.
    ///
    /// Valid values are in range 0-127.
    public let ttl: UInt8
    /// The Heartbeat Publication Features state determines the features that trigger
    /// sending Heartbeat messages when changed.
    public let features: NodeFeatures
    
    /// Returns whether Heartbeat publishing will be enabled.
    public var isEnabled: Bool {
        return destination != .unassignedAddress
    }
    
    /// Creates Config Heartbeat Publication Set message that will disable all Heartbeat
    /// messages sent by the target Node.
    public init() {
        self.destination = .unassignedAddress
        self.countLog = 0
        self.periodLog = 0
        self.ttl = 0
        self.features = []
        self.networkKeyIndex = 0
    }
    
    /// Creates Config Heartbeat Publication Set message with given parameters.
    /// - Parameters:
    ///   - countLog: Number of Heartbeat messages to be sent:
    ///
    ///               - 0x00 - Disables publishing periodic Heartbeat messages.
    ///               - 0x01 - 0x11 - Number of Heartbeat messages, 2^(n-1), to be sent.
    ///               - 0xFF - Periodic Heartbeat messages are published indefinitely.
    ///   - periodLog: Period for sending Heartbeat messages. This field is the interval used
    ///                for sending messages:
    ///
    ///               - 0x00 - Disables publishing periodic Heartbeat messages.
    ///               - 0x01 - 0x11 - Publication period represented as 2^(n-1) seconds.
    ///   - destination: Destination address for Heartbeat messages. The address shall
    ///                  be a Unicast Address, or a Group Address.
    ///   - ttl: TTL to be used when sending Heartbeat messages.
    ///   - networkKey: Network Key that will be used to send Heartbeat messages.
    ///   - features: Node features that trigger Heartbeat messages when changed.
    public init?(startSending countLog: UInt8,
                 heartbeatMessagesEvery periodLog: UInt8,
                 secondsTo destination: Address,
                 usingTtl ttl: UInt8, andNetworkKey networkKey: NetworkKey,
                 andEnableHeartbeatMessagesTriggeredByChangeOf features: NodeFeatures = []) {
        guard destination.isUnicast || destination.isGroup else {
            return nil
        }
        self.destination = destination
        guard countLog <= 0x11 || countLog == 0xFF else {
            return nil
        }
        self.countLog = countLog
        guard periodLog <= 0x11 else {
            return nil
        }
        self.periodLog = periodLog
        guard ttl <= 0x7F else {
            return nil
        }
        self.ttl = ttl
        guard networkKey.index.isValidKeyIndex else {
            return nil
        }
        self.networkKeyIndex = networkKey.index
        self.features = features
    }
    
    /// Creates Config Heartbeat Publication Set message with given parameters.
    /// - Parameters:
    ///   - destination: Destination address for Heartbeat messages. The address shall
    ///                  be a Unicast Address, or a Group Address.
    ///   - ttl: TTL to be used when sending Heartbeat messages.
    ///   - networkKey: Network Key that will be used to send Heartbeat messages.
    ///   - features: Node features that trigger Heartbeat messages when changed.
    public init?(startSendingHeartbeatMessagesTo destination: Address,
                 usingTtl ttl: UInt8, andNetworkKey networkKey: NetworkKey,
                 triggeredByChangeOf features: NodeFeatures) {
        guard destination.isUnicast || destination.isGroup else {
            return nil
        }
        self.destination = destination
        self.countLog = 0
        self.periodLog = 0
        guard ttl <= 0x7F else {
            return nil
        }
        self.ttl = ttl
        guard networkKey.index.isValidKeyIndex else {
            return nil
        }
        self.networkKeyIndex = networkKey.index
        self.features = features
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 9 else {
            return nil
        }
        self.destination = parameters.read(fromOffset: 0)
        self.countLog = parameters.read(fromOffset: 2)
        self.periodLog = parameters.read(fromOffset: 3)
        self.ttl = parameters.read(fromOffset: 4)
        self.features = NodeFeatures(rawValue: parameters.read(fromOffset: 5))
        self.networkKeyIndex = parameters.read(fromOffset: 7)
    }
    
}
