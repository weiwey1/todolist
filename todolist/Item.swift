//
//  Item.swift
//  todolist
//
//  Created by 梁庆卫 on 2026/2/13.
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
