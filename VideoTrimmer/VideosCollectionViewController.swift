//
//  VideosCollectionViewController.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/15/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import UIKit

import Photos
import MobileCoreServices

class ImageCache: NSCache<NSString, UIImage> { static let shared = NSCache<NSString, UIImage>(); private override init() { super.init() } }

class CellData { var asset: PHAsset!; var image: UIImage?; var timestamp: String = "" }

class VideosCollectionViewController: UICollectionViewController {
    private var _videos: [CellData] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView.register(UINib(nibName: "VideoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VideoCollectionViewCell")
        
        checkPhotoLibraryPermissions()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _videos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as! VideoCollectionViewCell
    
        let data = _videos[_videos.count-indexPath.item-1]
        cell.data = data
        if let image = data.image {
            cell.imageView.image = image
        } else {
            DispatchQueue.global().async {
                let image = data.asset.getAsThumbnailImage(width: 93, height: 93)
                DispatchQueue.main.async {
                    data.image = image
                    if data.asset.localIdentifier == cell.data.asset.localIdentifier {
                        cell.imageView.image = image
                    }
                }
            }
        }
        cell.timestampLabel.text = data.timestamp
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = _videos[_videos.count-indexPath.item-1]
        
        print("Requesting AVAsset for first video...")
        
        let loadingView = UIActivityIndicatorView(frame: CGRect(x: (collectionView.frame.width-50)/2, y: (collectionView.frame.height-50)/2, width: 50, height: 50))
        loadingView.style = .whiteLarge
        loadingView.backgroundColor = UIColor.black
        
        self.navigationController?.view.addSubview(loadingView)
        loadingView.startAnimating()
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: data.asset, options: options, resultHandler: { (assetUrl, mix, info) in
            print("AVAsset request complete.")
            guard let assetUrl = assetUrl as? AVURLAsset else {
                //TODO: Let the user know, because internet connectivity can cause this to fail intermittently
                print("Failed to get assetUrl from AVAsset request.")
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                }
                return
            }
            let tempVideoPath = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL.appendingPathComponent(assetUrl.url.lastPathComponent)
            try! FileManager.default.copyItem(at: assetUrl.url, to: tempVideoPath)
            DispatchQueue.main.async {
                loadingView.removeFromSuperview()
                self.showEditor(for: tempVideoPath)
            }
        })
    }
    
    //MARK: Helper Methods
    
    func checkPhotoLibraryPermissions() {
        print("Checking photos permission...")
        let permissions = PHPhotoLibrary.authorizationStatus()
        
        switch permissions {
        case .authorized:
            print("Permission previously granted")
            self.loadAssets()
        case .denied, .restricted:
            print("Permission previously denied.")
            showAccessDenied()
        case .notDetermined:
            print("Permission not yet determined. Showing permission request...")
            PHPhotoLibrary.requestAuthorization({ status in
                DispatchQueue.main.async {
                    if status == .authorized{
                        print("Permission granted.")
                        self.loadAssets()
                    } else {
                        print("Permission denied.")
                        self.showAccessDenied()
                    }
                }
            })
        }
    }
    
    func loadAssets() {
        let allVidOptions = PHFetchOptions()
        allVidOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        allVidOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allVideos = PHAsset.fetchAssets(with: allVidOptions)
        print("Found \(allVideos.count) videos. Loading meta data...")
        for i in 0..<allVideos.count {
            self._videos.append(self.getCellData(for: allVideos[i], index: i))
        }
        self.collectionView.reloadData()
    }
    
    func getCellData(for asset: PHAsset, index: Int) -> CellData {
        let data = CellData()
        data.asset = asset
        data.timestamp = " \(asset.duration.durationText) "
        return data
    }
    
    func showAccessDenied() {
        let ac = UIAlertController(title: "Oops!", message: "You have disabled photos access. This app won't work.", preferredStyle: UIAlertController.Style.alert)
        self.present(ac, animated: true, completion: nil)
    }
    
    func showEditor(for selectedAsset: PHAsset) {
        let tempFolderUrl = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL
        print("Found temporary url: \(tempFolderUrl)")
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: tempFolderUrl.path, isDirectory: &isDirectory) else {
            print("Temp directory doesn't exist!")
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
                self.showEditor(for: outputUrl)
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
                self.showEditor(for: outputUrl)
            }
        })
    }
    
    func showEditor(for outputUrl: URL) {
        guard UIVideoEditorController.canEditVideo(atPath: outputUrl.path) else {
            print("Can't edit video at \(outputUrl.path)")
            return
        }
        
        let originalAsset = AVAsset(url: outputUrl)
        printAssetDetails(asset: originalAsset)
        
        print("Presenting video editor...")
        let vc = UIVideoEditorController()
        vc.videoPath = outputUrl.path
        vc.videoMaximumDuration = 15
        vc.videoQuality = UIImagePickerController.QualityType.typeIFrame960x540
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
    
    func printAssetDetails(asset: AVAsset) {
        let urlAsset = asset as! AVURLAsset
        print("File Attributes for \(urlAsset.url.path):")
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: urlAsset.url.path),
            let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64 {
            print("\(Double(fileSize) / 1000000)mb")
            
            for attribute in fileAttributes {
                print("\t\(attribute.key.rawValue): \(attribute.value)")
            }
        }
        if let dimension = asset.dimension {
            print("\tDimension: \(dimension)")
        }
        if let codec = asset.codec(for: kCMMediaType_Video) {
            print("\tCodec: \(codec)")
        }
    }
    
    static func deleteAsset(at path: String) {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
            print("Deleted asset file at: \(path)")
        } catch {
            print("Failed to delete assete file at: \(path).")
            print("\(error)")
        }
    }
}

extension VideosCollectionViewController: UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        print("Result saved to path: \(editedVideoPath)")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
            VideosCollectionViewController.deleteAsset(at: editor.videoPath)
        })
        
        let asset = AVAsset(url: URL(fileURLWithPath: editedVideoPath))
        printAssetDetails(asset: asset)
        
        dismiss(animated:true, completion: {
            let vc = VideoViewController()
            vc.videoUrl = URL(fileURLWithPath: editedVideoPath)
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        dismiss(animated:true)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
            VideosCollectionViewController.deleteAsset(at: editor.videoPath)
        })
    }
    
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("an error occurred: \(error.localizedDescription)")
        dismiss(animated:true)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
            VideosCollectionViewController.deleteAsset(at: editor.videoPath)
        })
    }
}

extension TimeInterval {
    var durationText: String {
        let hours:Int = Int(self / 3600)
        let minutes:Int = Int(self.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(self.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
