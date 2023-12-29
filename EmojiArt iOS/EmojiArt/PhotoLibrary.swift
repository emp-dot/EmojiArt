//
//  PhotoLibrary.swift
//  EmojiArt
//
//  Created by Gideon Boateng on 12/25/23.
//

import SwiftUI
import PhotosUI

struct PhotoLibrary: UIViewControllerRepresentable {
    
    
    var handlePickedImage: (UIImage?) -> Void
    
    static var isAvailable: Bool {
        return true
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let found = results.map {$0.itemProvider}.loadObjects(ofType: UIImage.self) { [weak self] image in
                self?.handlePickedImage(image)
            }
            if !found {
                handlePickedImage(nil)
            }
        }
        
        var handlePickedImage: (UIImage?) -> Void
        
        init(handlePickedImage: @escaping (UIImage?) -> Void) {
            self.handlePickedImage = handlePickedImage
        }
        
        
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
}

