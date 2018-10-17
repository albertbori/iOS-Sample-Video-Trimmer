//
//  VideoViewController.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/16/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import UIKit
import AVKit

class VideoViewController: UIViewController {
    var videoUrl: URL!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer(url: self.videoUrl)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.view.layer.addSublayer(playerLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updatePlayerFrame()
        player?.play()
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.updatePlayerFrame()
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            player?.pause()
            VideosCollectionViewController.deleteAsset(at: videoUrl.path) //clean up trimmed file
        }
    }
    
    private func updatePlayerFrame() {
        playerLayer.frame = self.view.bounds
    }
}
