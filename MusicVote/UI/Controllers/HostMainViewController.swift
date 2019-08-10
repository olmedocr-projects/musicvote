//
//  HostMainViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 29/10/2018.
//

import UIKit
import Spartan
import StoreKit
import FirebaseDatabase
import FirebaseAuth
import ObjectMapper
import AVFoundation
import MediaPlayer
import NVActivityIndicatorView
import Alamofire
import SafariServices

class HostMainViewController: UIViewController {
    // MARK: - Properties
    var searchController: UISearchController!
    var searchViewController: SearchViewController!
    var miniPlayer: MiniPlayerViewController?
    var currentSong: Track?
    var player: SPTAudioStreamingController!
    var session: SPTSession!
    var queueTableView: QueueTableViewController!
    var ref: DatabaseReference!
    var userId: String!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Restore Spotify session if present
        if let encodedSessionKey = UserDefaults.standard.object(forKey: "customSpotifySessionKey") as? Data {
            if let decodedSessionKey = NSKeyedUnarchiver.unarchiveObject(with: encodedSessionKey) as? SPTSession {
                self.session = decodedSessionKey
            }
        }
        
        Spartan.loggingEnabled = false
        
        setupFirebaseDatabase()
        setupSearch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        if player == nil {
            setupSpotify()
        }
    }
    
    // MARK: - Internal
    func setupFirebaseDatabase() {
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            ref = Database.database().reference().child("sessions").child(user.uid).child("queue")
            queueTableView?.loadDatabaseObservers(ref: ref)
            queueTableView.delegate = self
        } else {
            print("Error while getting user data")
        }
    }
    
    func setupSearch() {
        searchViewController = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as? SearchViewController
        searchViewController.delegate = self
        searchViewController.ref = self.ref
        searchController = UISearchController(searchResultsController: searchViewController)
        self.navigationItem.searchController = searchController
        searchViewController.searchBar = searchController.searchBar
        searchViewController.searchBar.setValue("Done", forKey: "cancelButtonText")
        searchController.searchResultsUpdater = searchViewController
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = NSLocalizedString("Search in Spotify", comment: "") 
        searchController.searchBar.tintColor = ColorPalette.lightAccent
        
        definesPresentationContext = true
    }
    
    func setupSpotify() {
        SPTAuth.defaultInstance().clientID = "SPOTIFY_CLIENT_ID"
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "URL_TOKEN")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "URL_REFRESH_TOKEN")
        SPTAuth.defaultInstance().redirectURL = URL(string: "musicvote://com.raulolmedo.musicvote")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthUserReadPrivateScope]
        
        if !SPTAudioStreamingController.sharedInstance().initialized {
            do {
                try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID!)
            } catch {
                fatalError("Couldn't start Spotify SDK")
            }
        }
        
        if session == nil {
            // No session at all - use SPTAuth to ask the user
            // for access to their account.
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(receievedUrlFromSpotify(_:)),
                                                   name: NSNotification.Name.Spotify.authURLOpened,
                                                   object: nil)
            
            displaySpotifyLogin()
        } else if session.isValid() {
            // Our session is valid - go straight to music playback.
            setupSpotifyPlayer()
        } else {
            // Session expired - we need to refresh it before continuing.
            // This process doesn't involve user interaction unless it fails.
            SPTAuth.defaultInstance().renewSession(session) { (error, session) in
                if error == nil {
                    print("Renewing Spotify session")
                    self.session = session
                    self.setupSpotifyPlayer()
                } else {
                    print("Error while renewing Spotify session: \(error?.localizedDescription ?? "null")")
                }
            }
        }
    }
    
    func displaySpotifyLogin() {
        let safari = SFSafariViewController(url: SPTAuth.defaultInstance().spotifyWebAuthenticationURL())
        safari.modalPresentationStyle = .overFullScreen
        safari.delegate = self
        self.navigationController?.present(safari, animated: true, completion: nil)
    }
    
    @objc func receievedUrlFromSpotify(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        self.dismiss(animated: true, completion: nil)
        let activityData = ActivityData()
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
        NVActivityIndicatorPresenter.sharedInstance.setMessage(NSLocalizedString("Authenticating with Spotify", comment: ""))
        SPTAuth.defaultInstance().handleAuthCallback(withTriggeredAuthURL: url) { (error, session) in
            //Check if there is an error because then there won't be a session.
            if let error = error {
                print("Spotify auth failed with error: \(error)")
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
                return
            }
            
            // Check if there is a session
            if let session = session {

                self.session = session
                self.setupSpotifyPlayer()
            }
        }
    }

    func setupSpotifyPlayer() {
        self.player = SPTAudioStreamingController.sharedInstance()
        self.player.delegate = self
        self.player.playbackDelegate = self
        
        self.player.login(withAccessToken: session.accessToken)
        
        let encodedSessionKey = NSKeyedArchiver.archivedData(withRootObject: session)
        UserDefaults.standard.set(encodedSessionKey, forKey: "customSpotifySessionKey")
        
        ref.parent?.child("refreshToken").setValue(session.encryptedRefreshToken)
        
        Spartan.authorizationToken = session.accessToken
        print("Spotify auth succeeded with session: \(session.accessToken)")
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
    
    }
    
    func playNextSongInQueue() {
        if !self.queueTableView.songs.isEmpty {
            if let song = self.queueTableView.songs.first {
                self.player.playSpotifyURI((song.track.uri)!, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                    if error != nil {
                        print("Error while trying to play a queued song with error: \(error.debugDescription)")
                    } else {
                        self.currentSong = song.track
                        song.reference.removeValue()
                    }
                })
            }
        } else {
            print("No more songs to play!")
            self.miniPlayer?.configure(song: nil)
        }
    }
    
    private func setupCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget {(_) -> MPRemoteCommandHandlerStatus in
            SPTAudioStreamingController.sharedInstance().setIsPlaying(true, callback: nil)
            return .success
        }
        commandCenter.pauseCommand.addTarget {(_) -> MPRemoteCommandHandlerStatus in
            SPTAudioStreamingController.sharedInstance().setIsPlaying(false, callback: nil)
            return .success
        }
        commandCenter.nextTrackCommand.addTarget {(_) -> MPRemoteCommandHandlerStatus in
            SPTAudioStreamingController.sharedInstance().skipNext({ (error) in
                if error != nil {
                    print("Error while skipping the track from outside the app: \(error!.localizedDescription)")
                }
            })
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget {(event) -> MPRemoteCommandHandlerStatus in
            print(event.debugDescription)
            return .success
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "shareQRSegue" {
            if let destination = segue.destination as? QrViewController {
                // FXME: si no tiene el token, no deberia ser capaz el usuario de clickar aqui, sin embargo si que puede. Mirar el NVActivityIndicator donde y cuando aparece
                destination.authorizationToken = Spartan.authorizationToken
                destination.hostId = self.userId
            }
        } else if segue.identifier == "queueSegue" {
            if let destination = segue.destination as? QueueTableViewController {
                queueTableView = destination
            }
        } else {
            if let destination = segue.destination as? MiniPlayerViewController {
                miniPlayer = destination
            }
        }
    }
}

// MARK: - Spotify Audio Streaming Delegate
extension HostMainViewController: SPTAudioStreamingDelegate {
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController) {
        
        // Setup AVAudio streaming session
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: AVAudioSession.Mode.default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AVAudioSession is Active and Category Playback is set")
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupCommandCenter()
        } catch {
            debugPrint("Error while setting up AVAudioSession: \(error)")
        }
        print("Audio streaming correctly started")
        playNextSongInQueue()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveError error: Error) {
        print("Audio streaming failed to start with error: \(error.localizedDescription)")
    }
}

// MARK: - Spotify Audio Streaming Playback Delegate
extension HostMainViewController: SPTAudioStreamingPlaybackDelegate {
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStopPlayingTrack trackUri: String) {
        print("Song \(trackUri) stopped")
        playNextSongInQueue()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStartPlayingTrack trackUri: String) {
        print("Song \(trackUri) started")
        self.miniPlayer?.configure(song: self.currentSong)
    }
    
    func audioStreamingDidSkip(toNextTrack audioStreaming: SPTAudioStreamingController) {
        print("Song skipped")
        playNextSongInQueue()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            miniPlayer?.playButton.setImage(UIImage(imageLiteralResourceName: "pause"), for: .normal)
        } else {
            miniPlayer?.playButton.setImage(UIImage(imageLiteralResourceName: "play"), for: .normal)
        }
    }
}

// MARK: - Search View Controller Delegate
extension HostMainViewController: SearchViewControllerDelegate {
    func songAddedToQueue(song: Track) {
        let newRef = ref.childByAutoId()
        newRef.child("track").setValue(song.toJSON())
        newRef.child("votes").setValue(0)
    }
}

// MARK: - Queue Table View Controller Delegate
extension HostMainViewController: QueueTableViewControllerDelegate {
    func playFirstSong() {
        if player != nil {
            if !player.playbackState.isPlaying {
                playNextSongInQueue()
            }
        }
    }
}

// MARK: - Safari View Controller Delegate
extension HostMainViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("Finsihed!")
        let alert = UIAlertController(title: "Error!", message: "In order to use this app you need to log in with a Spotify premium account", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (_) in
            self.displaySpotifyLogin()
        }))
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Helper Functions Inserted by Swift 4.2 Migrator
private func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
