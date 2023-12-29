//
//  EmojiArtMacApp.swift
//  EmojiArtMac
//
//  Created by Gideon Boateng on 12/26/23.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct EmojiArtMacApp: App {
    //    @StateObject var document = EmojiArtViewModel()
    @StateObject var paletteStoreVM = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtViewModel() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStoreVM)
        }
    }
}
