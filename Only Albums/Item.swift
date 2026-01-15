//
//  Item.swift
//  Only Albums
//
//  Created by Scott Koellner on 1/15/26.
//

import Foundation
import SwiftData

@Model
final class HiddenAlbum {
    @Attribute(.unique) var albumID: String
    var hiddenAt: Date

    init(albumID: String, hiddenAt: Date = Date()) {
        self.albumID = albumID
        self.hiddenAt = hiddenAt
    }
}
