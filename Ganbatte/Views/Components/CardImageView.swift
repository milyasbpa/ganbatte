import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, PlatformImage>()
    
    private init() {
        cache.countLimit = 300 // Keep up to 300 images in memory
    }
    
    func image(named name: String) -> PlatformImage? {
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }
        
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension.isEmpty ? "webp" : (name as NSString).pathExtension
        
        var fileURL: URL?
        
        // 1. Try App Bundle resources
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Cards") ??
                     Bundle.main.url(forResource: baseName, withExtension: ext) {
            fileURL = url
        } else {
            // 2. Fallback to dev path if running directly in dev environment
            let devPath = "/Users/ilyasbashirah/Documents/kerja/bas.co/pictango/ganbatte/Ganbatte/Resources/Cards/\(baseName).\(ext)"
            if FileManager.default.fileExists(atPath: devPath) {
                fileURL = URL(fileURLWithPath: devPath)
            }
        }
        
        guard let url = fileURL else { return nil }
        
        #if os(iOS)
        if let img = UIImage(contentsOfFile: url.path) {
            cache.setObject(img, forKey: name as NSString)
            return img
        }
        #elseif os(macOS)
        if let img = NSImage(contentsOfFile: url.path) {
            cache.setObject(img, forKey: name as NSString)
            return img
        }
        #endif
        
        return nil
    }
}

struct CardImageView: View {
    let imageName: String
    var contentMode: ContentMode = .fit
    
    @State private var platformImage: PlatformImage?
    
    var body: some View {
        Group {
            if let img = platformImage {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                #endif
            } else {
                Rectangle()
                    .fill(AppTheme.cardBorder.opacity(0.4))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageName) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        if let cached = ImageCache.shared.image(named: imageName) {
            self.platformImage = cached
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let img = ImageCache.shared.image(named: imageName)
                DispatchQueue.main.async {
                    self.platformImage = img
                }
            }
        }
    }
}
