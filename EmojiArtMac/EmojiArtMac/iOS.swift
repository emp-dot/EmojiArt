//
//  iOS.swift
//  EmojiArtMac
//
//  Created by Gideon Boateng on 12/26/23.
//

import SwiftUI

extension UIImage {
    var imageData: Data? { jpegData(compressionQuality: 1.0) }
}

struct PasteBoard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    
    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}

extension View {
    
    func popoverPadding() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            NavigationView {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            self
        }
    }
    
    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        } else {
            self
        }
    }
}

extension View {
    func compactableToolbar<Content> (@ViewBuilder content: () -> Content) -> some View where Content: View {
        self.toolbar {
            content().modifier(CompactableIntoContextMenu())
        }
        
    }
}


struct CompactableIntoContextMenu: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var compact : Bool { horizontalSizeClass == .compact }
    
    func body(content: Content) -> some View {
        if compact {
            // return a single button with a context menu containing the content
            Button {
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .contextMenu{
                content
            }
        } else {
            content
        }
    }
}


