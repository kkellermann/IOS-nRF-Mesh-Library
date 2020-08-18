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

public struct ConfigHeartbeatSubscriptionSet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x803B
    public static let responseType: StaticMeshMessage.Type = ConfigHeartbeatSubscriptionStatus.self
    
    public var parameters: Data? {
        var data = Data() + source + destination
        data += periodLog
        return data
    }
    
    /// Source address for Heartbeat messages.
    ///
    /// The Heartbeat Subscription Source shall be the Unassigned Address or a Unicast a
    /// Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Subscription Source is set to the Uunassigned Address,
    /// the Heartbeat messages are not processed and subscription will be cancelled.
    public let source: Address
    /// Destination address for Heartbeat messages.
    ///
    /// The Heartbeat Subscription Destination shall be the Unassigned Address, a Unicast
    /// Address, or a Group Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Subscription Destination is set to the Unassigned Address, the
    /// Heartbeat messages are not processed.
    public let destination: Address
    /// Remaining Period for processing Heartbeat messages.
    ///
    /// Possible values (See table 4.1.2 in Bluetooth Mesh Specification 1.0.1):
    /// - 0x00 - Periodic Heartbeat messages are not processed.
    /// - 0x01 - 0x10 - Remaining period, in 2^(n-1) seconds, for processing Heartbeat messages.
    /// - 0x11 - 0xFFFF seconds.
    /// - Other values are Prohibited.
    internal let periodLog: UInt8
    
    /// Returns whether Heartbeat processing will be enabled.
    public var isEnabled: Bool {
        return source != .unassignedAddress && destination != .unassignedAddress
    }
    
    /// Creates Config Heartbeat Subscription Set message that will disable receiving
    /// and processing Heartbeat messages.
    public init() {
        self.source = .unassignedAddress
        self.destination = .unassignedAddress
        self.periodLog = 0
    }
    
    /// Creates Config Heartbeat Subscription Set message with given parameters.
    /// - Parameters:
    ///   - source: Source address for Heartbeat messages. The address shall
    ///             be a Unicast Address.
    ///   - destination: Destination address for Heartbeat messages. The address shall
    ///                  be a Unicast Address, or a Group Address.
    ///   - periodLog: Duration for processing Heartbeat messages. This field is the interval used
    ///                for sending messages. The value will be calculated as 2^(periodLog-1).
    ///
    ///               - 0x00 - Disables publishing periodic Heartbeat messages.
    ///               - 0x01 - 0x11 - Publication period represented as 2^(n-1) seconds.
    public init?(startProcessingHeartbeatMessagesFor periodLog: UInt8,
                 secondsSentFrom source: Address, to destination: Address) {
        guard source.isUnicast else {
         return nil
        }
        self.source = source
        guard destination.isUnicast || destination.isGroup else {
            return nil
        }
        self.destination = destination
        guard periodLog <= 0x11 else {
            return nil
        }
        self.periodLog = periodLog
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 else {
            return nil
        }
        self.source = parameters.read(fromOffset: 0)
        self.destination = parameters.read(fromOffset: 2)
        self.periodLog = parameters.read(fromOffset: 3)
    }
    
}
