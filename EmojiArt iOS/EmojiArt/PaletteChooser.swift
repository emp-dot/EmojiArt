//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 12/6/23.
//

import SwiftUI

// MARK: - PaletteChooser

struct PaletteChooser: View {
    // Font size for emojis
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize) }
    
    // Observable object for managing palettes
    @EnvironmentObject var store: PaletteStore
    // Index of the chosen palette
    @SceneStorage("PaletteChooser.chosenPaletteIndex")
    private var chosenPaletteIndex = 0
    // State variable for the new palette name
    @State private var newPaletteName = ""
    // State variable for the updated emojis
    @State private var updatedEmojis = ""
    
    var body: some View {
        HStack {
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped()
    }
    
    // Button for cycling through palettes
    var paletteControlButton: some View {
        Button {
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        .contextMenu { contextMenu }
    }
    
    // Context menu for additional actions
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButtion(title: "Edit", systemImage: "pencil") {
            // Edit action
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        
        AnimatedActionButtion(title: "New", systemImage: "plus") {
            // New palette action
            if var existingPalette = store.palettes.first(where: { $0.name == newPaletteName }) {
                // If a palette with the same name exists, update the emojis field
                if existingPalette.emojis != updatedEmojis {
                    existingPalette.emojis = updatedEmojis
                }
            } else {
                // If no palette with the same name exists, insert a new palette
                store.insertPalette(named: newPaletteName, emojis: updatedEmojis, at: chosenPaletteIndex)
            }
            // Reset the newPaletteName after performing the action
            newPaletteName = ""
            // Update the paletteToEdit variable
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        
        AnimatedActionButtion(title: "Delete", systemImage: "minus.circle") {
            // Delete palette action
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        #if os(iOS)
        AnimatedActionButtion(title: "Manage", systemImage: "slider.vertical.3") {
            // Manage action
            managing = true
        }
        #endif
        gotoMenu
    }
    
    // Go to menu for jumping to specific palettes
    // Computed Var
    var gotoMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButtion(title: palette.name) {
                    // Action for going to a specific palette
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }
    
    // Body for displaying the selected palette
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojiView(emojis: palette.emojis)
                .font(emojiFont)
        }
        .id(palette.id)
        .transition(rollTransition)
        .popover(item: $paletteToEdit) { palette in
            PaletteEditor(palette: $store.palettes[palette])
                .wrappedInNavigationViewToMakeDismissable {
                    paletteToEdit = nil
                }
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
        
    }
    

    @State private var managing = false
    @State private var paletteToEdit: Palette?
    
    // Transition animation for palette changes
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .offset(x: 0, y: emojiFontSize),
            removal: .offset(x: 0, y: -emojiFontSize))
    }
}

// MARK: - Scrolling Emoji View

/// A view for scrolling through emojis.
struct ScrollingEmojiView: View {
    
    // MARK: - Emoji String
    
    let emojis: String
    
    // MARK: - Body View
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                // Display unique emojis horizontally with drag-and-drop support
                ForEach(emojis.removingDuplicateCharacters.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

// MARK: - String Extension

extension String {
    // Remove duplicate characters from a string
    var removingDuplicateCharacters: String {
        var uniqueCharacters = Set<Character>()
        return self.filter { uniqueCharacters.insert($0).inserted }
    }
}


