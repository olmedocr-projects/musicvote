//
//  SpotifyPlayer.swift
//  MusicVote
//
//  Created by Raul Olmedo on 03/11/2018.
//

import Foundation
import Spartan

class SpotifyPlayer {
    static let sharedInstance = SpotifyPlayer()
    weak var delegate: SPTAppRemoteDelegate!
    var appRemote: SPTAppRemote!
    var lastPlayerState: SPTAppRemotePlayerState?
    public func loadAppRemote() {
        appRemote = {
            let appRemote = SPTAppRemote(configuration: SpotifySession.sharedInstance.configuration, logLevel: .debug)
            appRemote.delegate = self.delegate
            return appRemote
        }()
    }
    public func fetchArtwork(for track: SPTAppRemoteTrack, in imageView: UIImageView) {
        SpotifyPlayer.sharedInstance.appRemote.imageAPI?.fetchImage(forItem: track,
                                                                    with: CGSize.zero,
                                                                    callback: {(image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                imageView.image = image
            }
        })
    }
}
