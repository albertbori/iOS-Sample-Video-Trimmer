//
//  ViewController.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/12/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import UIKit

import Photos
import MobileCoreServices

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func checkPhotoLibraryPermissions() {
        print("Checking photos permission...")
        let permissions = PHPhotoLibrary.authorizationStatus()
        
        switch permissions {
        case .authorized:
            print("Permission previously granted")
            showEditor()
        case .denied, .restricted:
            print("Permission previously denied.")
            showAccessDenied()
        case .notDetermined:
            print("Permission not yet determined. Showing permission request...")
            PHPhotoLibrary.requestAuthorization({ status in
                DispatchQueue.main.sync {
                    if status == .authorized{
                        print("Permission granted.")
                        self.showEditor()
                    } else {
                        print("Permission denied.")
                        self.showAccessDenied()
                    }
                }
            })
        }
    }
    
    func showAccessDenied() {
        let ac = UIAlertController(title: "Oops!", message: "You have disabled photos access. This app won't work.", preferredStyle: UIAlertController.Style.alert)
        self.present(ac, animated: true, completion: nil)
    }
    
    func showEditor() {
        let allVidOptions = PHFetchOptions()
        allVidOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        allVidOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allVids = PHAsset.fetchAssets(with: allVidOptions)
        
        print("Found \(allVids.count) videos")
        
        let tempFolderUrl = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL
        print("Found temporary url: \(tempFolderUrl)")
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: tempFolderUrl.path, isDirectory: &isDirectory) else {
            print("Temp directory doesn't exist!")
            return
        }
        
        guard let selectedAsset = allVids.firstObject else {
            print("Failed to get first asset from all videos.")
            return
        }
        
        print("Requesting AVAsset for first video...")
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: selectedAsset, options: options, resultHandler: { (assetUrl, mix, info) in
            print("AVAsset request complete.")
            guard let assetUrl = assetUrl as? AVURLAsset else {
                print("Failed to get assetUrl from AVAsset request.")
                return
            }
            let outputUrl = tempFolderUrl.appendingPathComponent(assetUrl.url.lastPathComponent)
            guard !FileManager.default.fileExists(atPath: outputUrl.path) else {
                print("Exported video file already exists at \(outputUrl.path)")
                self.exportCompleted(outputUrl: outputUrl)
                return
            }
            
            let asset = AVAsset(url: assetUrl.url)
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                print("Failed to get exporter from AVAsset at url: \(assetUrl.url)")
                return
            }
            let outputFileType = AVFileType(rawValue: self.mimeTypeForPath(path: outputUrl.absoluteString))
            print("Outputting file at url: \(outputUrl) to type \(outputFileType)...")
            
            exporter.outputURL = outputUrl
            exporter.outputFileType = AVFileType.mp4
            exporter.exportAsynchronously {
                self.exportCompleted(outputUrl: outputUrl)
            }
        })
    }
    
    func exportCompleted(outputUrl: URL) {
        guard UIVideoEditorController.canEditVideo(atPath: outputUrl.path) else {
            print("Can't edit video at \(outputUrl.path)")
            return
        }
        print("Presenting video editor...")
        let vc = UIVideoEditorController()
        vc.videoPath = outputUrl.path
        vc.videoMaximumDuration = 15
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }

    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

extension ViewController: UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        print("Result saved to path: \(editedVideoPath)")
        dismiss(animated:true)
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        dismiss(animated:true)
    }
    
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("an error occurred: \(error.localizedDescription)")
        dismiss(animated:true)
    }
}

