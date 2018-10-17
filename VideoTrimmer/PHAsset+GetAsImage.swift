//
//  PHAsset+GetAsImage.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/16/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import Foundation
import Photos

extension PHAsset {
    func getAsImage() -> UIImage {
        if Thread.isMainThread { print("Warning: PHAsset.getAsImage() should not be called on the main thread!") }
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        option.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: self, targetSize: CGSize(width: self.pixelWidth, height: self.pixelHeight), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            guard let result = result else {
                print("Failed to get thumbnail for asset: \(self.mediaType) | \(String(describing: self.location))")
                if let info = info {
                    print("Thumbnail result info: ")
                    for item in info {
                        print("\(item.key): \(item.value)")
                    }
                }
                return
            }
            thumbnail = result
        })
        return thumbnail
    }
    
    func getAsThumbnailImage(width: CGFloat, height: CGFloat) -> UIImage {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        var thumbnail = UIImage()
        PHImageManager.default().requestImage(for: self, targetSize: CGSize(width: width, height: height), contentMode: .aspectFill, options: options, resultHandler: {(result, info)->Void in
            guard let result = result else {
                print("Failed to get thumbnail for asset: \(self.mediaType) | \(String(describing: self.location))")
                if let info = info {
                    print("Thumbnail result info: ")
                    for item in info {
                        print("\(item.key): \(item.value)")
                    }
                }
                return
            }
            thumbnail = result
        })
        return thumbnail
    }
}
