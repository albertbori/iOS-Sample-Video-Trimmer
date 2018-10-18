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
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    
    var videoUrl: URL!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isManuallyPaused = false
    var playCount = 0
    let maxAutoPlayCount = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)        
        progressSlider.setThumbImage(UIImage(named: "sliderKnob"), for: .normal)
        progressSlider.setMinimumTrackImage(UIImage(named: "sliderLeft"), for: .normal)
        progressSlider.setMaximumTrackImage(UIImage(named: "sliderRight"), for: .normal)
        
        player = AVPlayer(url: self.videoUrl)
        playerLayer = AVPlayerLayer(player: self.player)
        addPeriodicTimeObserver()
        view.layer.insertSublayer(playerLayer, at: 0)
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
            player?.removeTimeObserver(_timeObserver)
            VideosCollectionViewController.deleteAsset(at: videoUrl.path) //clean up trimmed file
        }
    }
    
    private func updatePlayerFrame() {
        playerLayer.frame = self.view.bounds
    }
    
    
    //MARK: Slider Behavior
    
    private var _timeObserver: Any!
    private func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        _timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] time in
            let currentSeconds = CMTimeGetSeconds(time)
            guard let duration = self?.player.currentItem?.duration else { return }
            let totalSeconds = CMTimeGetSeconds(duration)
            let progress: Float = Float(currentSeconds/totalSeconds)
            self?.progressSlider.value = progress
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touchEvent = event.allTouches?.first else { return }
        switch touchEvent.phase {
        case .began:
            player.pause()
        case .moved:
            guard let duration = player.currentItem?.duration else { return }
            let seekTime = CMTime(seconds: duration.seconds * Double(sender.value), preferredTimescale: duration.timescale)
            player.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        case .ended:
            if !isManuallyPaused { player.play() }
        default:
            break;
        }
    }
    
    //MARK: Play/Pause
    
    @IBAction func togglePlay(_ sender: Any) {
        let isPlaying = player.timeControlStatus == .playing || player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        if isPlaying {
            isManuallyPaused = true
            player.pause()
        } else {
            isManuallyPaused = false
            player.play()
        }
        playPauseButton.setTitle(isPlaying ? "Pause" : "Play", for: .normal)
    }
    
    @objc func videoDidEnd(_ notification: Notification) {
        playCount += 1
        player.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
        if playCount <= maxAutoPlayCount {
            player.play()
        } else {
            playPauseButton.setTitle("Play", for: .normal)
        }
    }
    
    //MARK: Mute/Unmute
    
    @IBAction func toggleMute(_ sender: Any) {
        player.isMuted = !player.isMuted
        muteButton.setTitle(player.isMuted ? "Unmute" : "Mute", for: .normal)
    }
}
