//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 12/7/23.
//

import SwiftUI

struct PaletteEditor: View {
    // To be able to edit the palette from the model
    // Binding cannot be private
    @Binding var palette: Palette
    @State private var emojisToAdd = ""
    
    var body: some View {
        Form {
            nameSection
            addEmojisSection
            removeEmojiSection
        }
        .navigationTitle("Edit \(palette.name)")
        .frame(minWidth: 300, minHeight: 350)
    }
    
    var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $palette.name)
        }
    }
    
    
    
    var addEmojisSection: some View {
        Section(header: Text("Add Emojis")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    func addEmojis(_ emojis: String) {
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter { $0.isEmoji }
                .removingDuplicateCharacters
        }
    }
    
    var removeEmojiSection: some View {
        Section(header: Text("Remove Emojis")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emojis in
                    Text(emojis)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll(where: {String ($0) == emojis})
                            }
                        }
                }
            }
            .font(.system(size: 40))
        }
    }
}

struct PaletteEditor_Preview: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 3)))
            .previewLayout(.fixed(width: 300.0, height: 350.0))
        PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 5)))
            .previewLayout(.fixed(width: 300.0, height: 650.0))
        
    }
}
