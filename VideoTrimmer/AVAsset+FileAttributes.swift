//
//  AVAsset+FileAttributes.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/17/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import Foundation
import AVKit

extension AVAsset {
    var dimension: CGSize? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    var aspectRatio: Double? {
        guard let size = dimension else { return nil }
        return Double(size.height/size.width)
    }
    
    func codec(for mediaType: CMMediaType) -> String? {
        let formatDescriptions = self.tracks.flatMap { $0.formatDescriptions }
        let mediaSubtypes = formatDescriptions
            .filter { CMFormatDescriptionGetMediaType($0 as! CMFormatDescription) == mediaType }
            .map { CMFormatDescriptionGetMediaSubType($0 as! CMFormatDescription).toString() }
        return mediaSubtypes.first
    }
}

fileprivate extension FourCharCode {
    func toString() -> String {
        let n = Int(self)
        var s: String = String(UnicodeScalar((n >> 24) & 255)!)
        s.append(Character(UnicodeScalar((n >> 16) & 255)!))
        s.append(Character(UnicodeScalar((n >> 8) & 255)!))
        s.append(Character(UnicodeScalar(n & 255)!))
        return s.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
