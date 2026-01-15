//
//  Item.swift
//  Only Albums
//
//  Created by Scott Koellner on 1/15/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
