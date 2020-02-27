//
//  Device.swift
//  Push Notification GUI
//
//  Created by Hina Kormoczi on 2020. 02. 24.
//  Copyright © 2020. Hina Kormoczi. All rights reserved.
//

import Foundation

class Device : Hashable, Identifiable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    var name : String = ""
    var uuid : String = ""
    var isAvailable : Bool = false
}
