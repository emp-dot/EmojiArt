//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 11/24/23.
//

import Foundation

// MARK: - EmojiArtModel

/// A model representing the EmojiArt.
/// This struct conforms to the codable API
struct EmojiArtModel: Codable {
    
    // MARK: - Properties
    
    /// The background of the EmojiArt.
    var background = Background.blank
    
    /// An array of emojis in the EmojiArt.
    var emojis = [Emoji]()
    
    // MARK: - Emoji Structure
    
    /// A structure representing an emoji in the EmojiArt.
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        var id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    // MARK: - JSON Handling
    
    /// Encodes the EmojiArtModel to JSON data.
    /// - Returns: The JSON data representing the EmojiArtModel.
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    /// Initializes an EmojiArtModel from JSON data.
    /// - Parameter json: The JSON data to initialize the EmojiArtModel.
    /// - Throws: An error if decoding fails.
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    /// Initializes an EmojiArtModel from a file at the specified URL.
    /// - Parameter url: The URL of the file containing JSON data.
    /// - Throws: An error if data cannot be read or decoding fails.
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    /// Initializes an empty EmojiArtModel.
    init() { }
    
    // MARK: - Emoji ID Handling
    
    /// A private variable to maintain a unique identifier for emojis.
    private var uniqueEmojiId = 0
    
    /// Adds an emoji to the EmojiArtModel.
    /// - Parameters:
    ///   - text: The text representing the emoji.
    ///   - location: The location of the emoji.
    ///   - size: The size of the emoji.
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}

