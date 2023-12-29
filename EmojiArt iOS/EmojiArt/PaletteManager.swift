//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 12/7/23.
//

import SwiftUI

// MARK: - PaletteManager

struct PaletteManager: View {
    // Access the shared palette store
    @EnvironmentObject var store: PaletteStore
    // Access the presentation mode to control the sheet presentation
    @Environment(\.presentationMode) var presentationMode
    
    // State variable to track the edit mode of the list
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    // Navigating to another view
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                            Text(palette.emojis)
                        }
                        // Enable gesture only in active edit mode
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete { indexSet in
                    // Delete palettes at specified indexes
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    // Move palettes to new positions
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palette")
            .navigationBarTitleDisplayMode(.inline)
            .dismissable { presentationMode.wrappedValue.dismiss() }
            .toolbar {
                // Wrap the EditButton in a ToolbarItem
                ToolbarItem {
                    EditButton()
                }
                
               
            }
            // Set the edit mode environment variable
            .environment(\.editMode, $editMode)
        }
    }
    
    // Tap gesture for potential interactions
    var tap: some Gesture {
        TapGesture().onEnded { }
    }
}

// MARK: - PaletteManager_Preview

struct PaletteManager_Preview: PreviewProvider {
    static var previews: some View {
        // Preview of the PaletteManager
        PaletteManager()
            .previewDevice("iPhone 15 Pro Max")
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
