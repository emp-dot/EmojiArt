//
//  EmojiArtViewModel.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 11/24/23.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType (exportedAs: "edu.hunter.c3900.emojiart")
}

// MARK: - EmojiArtViewModel

/// A view model for EmojiArt.
class EmojiArtViewModel:  ReferenceFileDocument
{
    static var readableContentTypes = [UTType.emojiart]
    static var writeableContentTypes = [UTType.emojiart]
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        }
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    // MARK: - Published Properties
    
    /// Published property representing the emojiArt model.
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes an EmojiArtViewModel.
    init() {
            emojiArt = EmojiArtModel()
    }
    
    // MARK: - Computed Properties
    
    /// Computed property representing the emojis in the emojiArt model.
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    
    /// Computed property representing the background of the emojiArt model.
    var background: EmojiArtModel.Background { emojiArt.background }
    
    // MARK: - Published Properties for Background Image
    
    /// Published property representing the background image.
    @Published var backgroundImage: UIImage?
    
    /// Published property representing the background image fetch status.
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    // MARK: - Background Image Fetch Status Enumeration
    
    /// Enumeration representing the background image fetch status.
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed (URL)
    }
    
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    // MARK: - Fetch Background Image Function
    
    /// Fetches the background image data if necessary based on the background type.
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            // Multithreading when fetching the URL
            backgroundImageFetchStatus = .fetching
            backgroundImageFetchCancellable?.cancel()
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)
                .map{(data, URLResponse) in UIImage(data: data)}
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
            
            backgroundImageFetchCancellable = publisher
                .sink { [weak self] image in
                    self?.backgroundImage = image
                    self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
                }
            
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    // MARK: - Intents
    
    /// Sets the background of the emojiArt model.
    /// - Parameter background: The background type to set.
    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
            print("Background set to \(background)")
        }
    }
    
    /// Adds an emoji to the emojiArt model.
    /// - Parameters:
    ///   - emoji: The text representation of the emoji.
    ///   - location: The location where the emoji should be added.
    ///   - size: The size of the emoji.
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, at: location, size: Int(size))
        }
    }
    
    /// Moves an emoji in the emojiArt model by a given offset.
    /// - Parameters:
    ///   - emoji: The emoji to move.
    ///   - offset: The offset by which to move the emoji.
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }
    
    /// Scales an emoji in the emojiArt model by a given scale factor.
    /// - Parameters:
    ///   - emoji: The emoji to scale.
    ///   - scale: The scale factor by which to scale the emoji.
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    // MARK: - Undo
    
    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(operation)
    }
}
