//
//  paletteStoreVM.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 12/5/23.
//

import SwiftUI

// Define a data model for a palette
struct Palette: Identifiable, Hashable, Codable {
    var name: String
    var emojis: String
    var id: Int
    
    // Private initializer to ensure instances are created with a unique identifier
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

// Observable object to manage a collection of palettes
class PaletteStore: ObservableObject {
    // Name of the palette store
    let name: String
    
    // Published property to store an array of palettes with automatic UserDefaults syncing
    @Published var palettes = [Palette]() {
        
        didSet {
            // When palettes are updated, store the changes in UserDefaults
            storeInUserDefaults()
        }
    }
    
    // Key for storing palettes in UserDefaults, based on the palette store's name
    private var userDefaultsKey: String {
        "PaletteStore:" + name
    }
    
    // Store palettes in UserDefaults as an array of property lists
    private func storeInUserDefaults() {
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }
    
    // Restore palettes from UserDefaults
    private func restoreFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
        let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
            palettes = decodedPalettes
        }
//        if let palettesAsPropertyList = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String]] {
//            // Logic to convert the property list back to Palette instances
//            // and update the 'palettes' array
//            for paletteAsArray in palettesAsPropertyList {
//                if paletteAsArray.count == 3, let id = Int(paletteAsArray[2]), !palettes.contains(where: {$0.id == id}) {
//                    let palette = Palette(name: paletteAsArray[0], emojis: paletteAsArray[1], id: id)
//                    palettes.append(palette)
//                }
//            }
//        }
    }
    
    // Initializer for the PaletteStore
    init(named name: String) {
        self.name = name
        restoreFromUserDefaults()
        if palettes.isEmpty {
            print("using built-in palette")
            insertPalette(named: "Vehicle", emojis: "✈️🚀🚗⛽️🚘🚙🛫🛬🚜🚍🚑🚛🚐🚌🚕🚔🚚🛺🚖🚡🚃🛻🚎🏎️🛥️🚅🚁🛞🛳️🚊🚲🚕🚔🚚🚞🚉🛺🚟🛞🚁🚂🚓🚒" )
            insertPalette(named: "Sports", emojis: "⚽️🏀🏈⚾️🥎🎾🏐🏉🏸🏑🥍🏏🥊" )
            insertPalette(named: "Music", emojis: "🎶🎼🎵🎤🎧🎸🥁🎹🪇🪗🎷🎻🎺𝄁🪈🪕🪘݉" )
            insertPalette(named: "Animals", emojis: "🐈🐈‍⬛🐕‍🦺🦮🐕🐩🐇🐀🐁🦔🐿️🦡🦝🐖🐗🐄🐂🐃🦬🐎🫏🐐🦄🦍🐒🐝🐍🦅🦍🐓🦆🐢🦀🦁🐘🦎🐬🐛🦃🐙🦌🦗🐌🦒🦜🦞🦇" )
            insertPalette(named: "Animal faces", emojis: "🙈😹😻🐶🙊🐷🙀🦄🐻😺🐒🐱🐸😸😽😿🐼😾🙉😼🐭🐯🐰🐴🐺🐵🐹🐨🐔🦁🐽🦊🐮🐧🐗🐤🐦🫎" )
            insertPalette(named: "Flora", emojis: "🌸💐☙❦❧" )
            insertPalette(named: "Weather", emojis: "☁️☀️🌤️🌥️⛅️🌦️🌧️🌪️❄️☂️☔️⚡️🌩️⛈️🌨️💨🌈🌊☃️🌬️🌀🌫️🌁☄️" )
            insertPalette(named: "COVID", emojis: "🤮😷🤢🥴💉💉" )
            insertPalette(named: "Faces", emojis: "😘🤣😭😍😊🥰😁🙄😩🤪😬😀😢😅😉🥺😳😔☺️🤔🤗😜💀🙂😄🥳😏☹️😆😒😡😎😃🙃😞😋😌🙈😱🤩😝🤭😫😑🤤🥴😕😐😇😤🤦🤦‍♀️🤦‍♂️🤨😴😛🙁😹😥😚🧐😪🤓🤡😓🤯😻😖🤫🤧😣😮🤠🤑😶😗😟😰😙😲🌚😠" )
        } else {
            print("successfully loaded palettes from UserDefaults: \(palettes)")
        }
    }
    
    // MARK: - Intent
    
    // Get a palette at a specific index, ensuring the index is within bounds
    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }
    
    // Remove a palette at a specific index, ensuring the index is valid
    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }
    
    // Insert a new palette at a specific index, ensuring the index is within bounds
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        // Create a unique identifier for the new palette
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        // Insert the new palette at the specified index
        palettes.insert(palette, at: safeIndex)
    }
}
