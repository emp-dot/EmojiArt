//
//  ContentView.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 11/24/23.
//

import SwiftUI

// MARK: - EmojiArtDocumentView

/// A view representing the EmojiArt document.
struct EmojiArtDocumentView: View {
    
    // MARK: - Observed Object
    
    /// Observed object representing the EmojiArtViewModel.
    @ObservedObject var document: EmojiArtViewModel
    
    @Environment (\.undoManager) var undoManager
    
    // MARK: - Default Emoji Font Size
    
    /// Default font size for emojis. is scaled to fit
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    // MARK: - Body View
    
    var body: some View {
           GeometryReader { geometry in
               VStack(spacing: 0) {
                   documentBody
                   PaletteChooser(emojiFontSize: defaultEmojiFontSize)
               }
           }
       }
    
    // MARK: - Document Body View
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Color and Image
                Color.white 
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                
                .gesture(doubleTapToZoom(in: geometry.size))
                
                // Progress View while Fetching Image
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    // Emojis
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .scaleEffect(zoomScale)
                            .font(.system(size: fontSize(for: emoji)))
                            .position(position(for: emoji, in: geometry))
                            .gesture(emojiDragGesture(for: emoji))
                    }
                }
            }
            .clipped()
            // Drop plainText, URL, and image
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location,  in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            #if os(iOS) || os(macOS)
            .toolbar {
                AnimatedActionButtion(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                if Camera.isAvailable {
                    AnimatedActionButtion(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButtion(title: "Search Photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButtion(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButtion(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
            }
            #endif
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library: PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                    
                }
            }
        }
    }
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autozoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: String, Identifiable {
        
        case camera
        case library
        var id: String { rawValue }
    }
    
    private func pasteBackground() {
        autozoom = true
        if let imageData = PasteBoard.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = PasteBoard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert (
                title: "Paste BAckground",
                message: "There is no image currently on the pasteboard."
            )
        }
    }
    
    @State private var autozoom = false
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert (id: "fetch failed: " + url.absoluteString , alert: {
            Alert (
                title: Text ("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("Ok"))
            )
        })
    }
    
    // MARK: - Drop Function
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        // Function to handle dropping of URLs, images, and plain text
        var found = providers.loadObjects(ofType: URL.self) { url in
            autozoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autozoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        #endif
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
                        undoManager: undoManager
                    )
                }
            }
        }
        return found
    }
    
    // MARK: - Emoji Position Functions
    
    private func position (for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    // MARK: - Font Size Function
    
    private func fontSize (for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    // MARK: - Pan Gesture Variables
    
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    // MARK: - Pan Offset Computed Property
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    // MARK: - Zoom Scale Variables
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    // MARK: - Zoom Scale Computed Property
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    // MARK: - Pan Gesture Function
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    // MARK: - Zoom Gesture Function
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                withAnimation {
                    steadyStateZoomScale *= gestureScaleAtEnd
                }
            }
    }
    
    // MARK: - Emoji Drag Gesture Function
    private func emojiDragGesture(for emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                document.moveEmoji(emoji, by: gesture.translation / zoomScale, undoManager: undoManager)
            }
            .onEnded { finalDragGesture in
//                document.moveEmoji(emoji, by: gesture.translation / zoomScale)
            }
    }

    
    // MARK: - Double Tap Gesture Function
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded{
                withAnimation{
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    // MARK: - Zoom to Fit Function
    
    /// Adjusts the zoom level and pan offset to fit an image within a specified size.
    /// - Parameters:
    ///   - image: The UIImage to fit within the specified size.
    ///   - size: The CGSize representing the target size.
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // Ensure valid image and size dimensions are provided
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            // Calculate horizontal and vertical zoom factors
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            // Reset pan offset and set zoom scale to the minimum of horizontal and vertical zoom
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
}

