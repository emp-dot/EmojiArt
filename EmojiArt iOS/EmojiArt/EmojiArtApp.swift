//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 11/24/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
//    @StateObject var document = EmojiArtViewModel()
    @StateObject var paletteStoreVM = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtViewModel() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStoreVM)
        }
    }
}
