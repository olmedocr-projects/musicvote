/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Spartan
import MediaPlayer

protocol SongSubscriber: class {
    var currentSong: Track? { get set }
}

class MiniPlayerViewController: UIViewController, SongSubscriber {
    // MARK: - Properties
    var currentSong: Track?
    let defaultImageURL: String = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxtVFrGlu-W8CsCKncYpJQ3pvQjRIwsraMmQDyIiquE3lOSnbu"
    
    // MARK: - IBOutlets
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure(song: nil)
        thumbImage.layer.cornerRadius = CGFloat(5)
        thumbImage.clipsToBounds = true
    }
    
    // MARK: - Internal
    func loadImage(song: Track, url: String, imageView: UIImageView) {
        let url = URL(string: url)
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url, completionHandler: {(image, error, _, _) in
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyAlbumTitle: song.album.name, MPMediaItemPropertyArtist: song.album.artists[0].name, MPMediaItemPropertyTitle: song.name, MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: (image?.size)!, requestHandler: {(_) -> UIImage in
                return image!
            })]
            if error != nil {
                print("Failed to fetch the image with error: \(error.debugDescription)")
            }
        })
    }
}

// MARK: - Internal
extension MiniPlayerViewController {
    func configure(song: Track?) {
        if let song = song {
            songTitle.text = song.name
            if song.album != nil {
                if !song.album.images.isEmpty {
                    loadImage(song: song, url: song.album.images[0].url, imageView: thumbImage)
                }
            } else {
                // Provide a default image
                loadImage(song: song, url: defaultImageURL, imageView: thumbImage)
            }
        } else {
            songTitle.text = nil
            thumbImage.image = nil
        }
        currentSong = song
    }
}

// MARK: - IBActions
extension MiniPlayerViewController {
    @IBAction func tapPlayPause(_ sender: UIButton) {
        if SPTAudioStreamingController.sharedInstance().playbackState.isPlaying {
            SPTAudioStreamingController.sharedInstance().setIsPlaying(false, callback: nil)
        } else {
            SPTAudioStreamingController.sharedInstance().setIsPlaying(true, callback: nil)
        }
    }
    
    @IBAction func tapFastForward(_ sender: UIButton) {
        SPTAudioStreamingController.sharedInstance().skipNext { (error) in
            if error != nil {
                print("Error while skipping a track: \(error.debugDescription)")
            }
        }
    }
}
