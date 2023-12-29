//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 11/24/23.
//

import Foundation

// MARK: - EmojiArtModel Extension

/// An extension to EmojiArtModel defining the Background enumeration.
extension EmojiArtModel {
    
    // MARK: - Background Enumeration
    
    /// An enumeration representing the background of EmojiArt.
    enum Background: Equatable, Codable {
        
        /// A case representing a blank background.
        case blank
        
        /// A case representing a background with an image specified by a URL.
        case url(URL)
        
        /// A case representing a background with image data.
        case imageData(Data)
        
        // MARK: - Initialization
        
        /// Initializes a Background case from a decoder.
        /// - Parameter decoder: The decoder to use for decoding.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Attempt to decode a URL, if successful, set the case to .url
            if let url = try? container.decode(URL.self, forKey: .url) {
                self = .url(url)
            }
            // Attempt to decode image data, if successful, set the case to .imageData
            else if let imageData = try? container.decode(Data.self, forKey: .imageData) {
                self = .imageData(imageData)
            }
            // If neither URL nor image data is found, set the case to .blank
            else {
                self = .blank
            }
        }
        
        // MARK: - Coding Keys Enumeration
        
        /// An enumeration representing coding keys for encoding and decoding.
        enum CodingKeys: String, CodingKey {
            case url
            case imageData
        }
        
        // MARK: - Encoding
        
        /// Encodes the Background case to a given encoder.
        /// - Parameter encoder: The encoder to use for encoding.
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            // Switch on the Background case and encode accordingly
            switch self {
            case .url(let url):
                try container.encode(url, forKey: .url)
            case .imageData(let data):
                try container.encode(data, forKey: .imageData)
            case .blank:
                // .blank case does not need encoding
                break
            }
        }
        
        // MARK: - Computed Properties
        
        /// Returns the URL associated with the .url case, otherwise nil.
        var url: URL? {
            switch self {
            case .url(let url):
                return url
            default:
                return nil
            }
        }
        
        /// Returns the image data associated with the .imageData case, otherwise nil.
        var imageData: Data? {
            switch self {
            case .imageData(let data):
                return data
            default:
                return nil
            }
        }
    }
}
