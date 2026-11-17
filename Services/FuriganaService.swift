import Foundation
import SwiftUI

struct FuriganaSegment: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let reading: String?
    let isKanji: Bool
}

final class FuriganaService {
    static let shared = FuriganaService()
    
    private let cache = NSCache<NSString, NSArray>()
    
    private init() {}
    
    func parse(_ text: String) -> [FuriganaSegment] {
        if let cached = cache.object(forKey: text as NSString) as? [FuriganaSegment] {
            return cached
        }
        
        let cfText = text as CFString
        let length = text.utf16.count
        guard length > 0 else { return [] }
        
        let locale = CFLocaleCreate(kCFAllocatorDefault, CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, "ja" as CFString))
        guard let tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, cfText, CFRangeMake(0, length), kCFStringTokenizerUnitWordBoundary, locale) else {
            return [FuriganaSegment(text: text, reading: nil, isKanji: false)]
        }
        
        var segments: [FuriganaSegment] = []
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let startIndex = text.utf16.index(text.utf16.startIndex, offsetBy: range.location)
            let endIndex = text.utf16.index(startIndex, offsetBy: range.length)
            
            if let word = String(text.utf16[startIndex..<endIndex]) {
                let containsKanji = word.unicodeScalars.contains { scalar in
                    (0x4E00...0x9FAF).contains(scalar.value) || (0x3400...0x4DBF).contains(scalar.value)
                }
                
                if containsKanji, let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                    let mutable = NSMutableString(string: latin)
                    CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
                    let reading = mutable as String
                    segments.append(FuriganaSegment(text: word, reading: reading, isKanji: true))
                } else {
                    segments.append(FuriganaSegment(text: word, reading: nil, isKanji: false))
                }
            }
            
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        cache.setObject(segments as NSArray, forKey: text as NSString)
        return segments
    }
}
