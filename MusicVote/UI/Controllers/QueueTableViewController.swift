//
//  QueueTableViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 06/11/2018.
//

import UIKit
import FirebaseDatabase
import Spartan
import Kingfisher
import ObjectMapper

protocol QueueTableViewControllerDelegate: class {
    func playFirstSong()
}

protocol QueueTableViewCoachingDelegate: class {
    func resumeCoaching()
}

class QueueTableViewController: UITableViewController {
    // MARK: - Properties
    weak var delegate: QueueTableViewControllerDelegate!
    weak var coachingDelegate: QueueTableViewCoachingDelegate!
    var songs: [(track: Track, votes: Int, isUpvoted: Bool, reference: DatabaseReference)] = []
    var ref: DatabaseReference!
    let defaultImageURL: String = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxtVFrGlu-W8CsCKncYpJQ3pvQjRIwsraMmQDyIiquE3lOSnbu"

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: .zero)
    }

    // MARK: - UI Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "queueTableViewCell", for: indexPath) as! QueueTableViewCell
        cell.songTitle.text = songs[indexPath.row].track.name
        cell.songAlbum.text = songs[indexPath.row].track.album.name
        cell.songArtist.text = songs[indexPath.row].track.artists[0].name
        cell.votes.text = String(songs[indexPath.row].votes)
        cell.delegate = self
        cell.indexPath = indexPath
        cell.upvoteButton.isEnabled = !songs[cell.indexPath.row].isUpvoted
        cell.downvoteButton.isEnabled = songs[cell.indexPath.row].isUpvoted
        if !songs[indexPath.row].track.album.images.isEmpty {
            let url = URL(string: (songs[indexPath.row].track.album.images[0].url) ?? defaultImageURL)
            cell.thumbImageView?.kf.indicatorType = .activity
            cell.thumbImageView?.kf.setImage(with: url, completionHandler: {(_, error, _, _) in
                if error != nil {
                    print("Error while getting the images: \(String(describing: error?.debugDescription))")
                }
            })
        }
        return cell
    }
    
    // MARK: - Internal
    func loadDatabaseObservers(ref: DatabaseReference) {
        self.ref = ref
        
        ref.observe(DataEventType.childAdded, with: { (snapshot) in
            if let remoteQueueElementDictionary = snapshot.value as? [String: AnyObject] {
                var song: Track?
                
                guard let trackDict = remoteQueueElementDictionary["track"] else {return}
                if let trackDictString = trackDict as? [String: Any] {
                    song = Track(map: Map(mappingType: MappingType.fromJSON, JSON: trackDictString))
                }
                
                snapshot.ref.child("votes").observe(DataEventType.value, with: { (snapshot) in
                    if let votes = snapshot.value as? Int {
                        if let row = self.songs.index(where: {$0.track == song}) {
                            self.songs[row].votes = votes
                            self.songs.sort(by: { $0.votes > $1.votes })
                            self.tableView.reloadData()
                        }
                    }
                })
                if self.songs.isEmpty {
                    self.songs.append((track: song!, votes: 0, isUpvoted: false, reference: snapshot.ref))
                    print("Appended first song \(song?.name ?? "null") to array")
                    self.delegate?.playFirstSong()
                } else {
                    self.songs.append((track: song!, votes: 0, isUpvoted: false, reference: snapshot.ref))
                    print("Appended song \(song?.name ?? "null") to array")
                }
            }
            self.tableView.reloadData()
        }, withCancel: { (error) in
            print("Error while getting song in remote queue: \(error.localizedDescription)")
        })
        
        ref.observe(DataEventType.childRemoved, with: { (snapshot) in
            if let index = self.songs.firstIndex(where: { (track) -> Bool in
                let trackDict = snapshot.value as? [String: AnyObject]
                if track.track.id as? String == trackDict?["track"]?["id"] as? String {
                    track.reference.removeAllObservers()
                    return true
                }
                return false
            }) {
                print("Removed song \(self.songs.remove(at: index).track.name ?? "null")")
                self.tableView.reloadData()
            }
        }, withCancel: { (error) in
            print("Error while deleting song in remote queue: \(error.localizedDescription)")
        })
        
        ref.parent?.child("authToken").observe(DataEventType.childChanged, with: { (snapshot) in
            if let token = snapshot.value as? String {
                print("Getting authToken from database: \(token)")
                Spartan.authorizationToken = token
            }
        }, withCancel: { (error) in
            print("Error while reading authToken in database: \(error.localizedDescription)")
        })
    }
}

// MARK: - Queue Cell Delegate
extension QueueTableViewController: QueueCellDelegate {
    // FIXME: this is some crazy shit: the first one works, the second doesn't (but obv the delegate is set)
    func didPressUpButton(at index: IndexPath) {
        coachingDelegate?.resumeCoaching()
        
        songs[index.row].reference.child("votes").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if let votes = currentData.value as? Int {
                currentData.value = votes + 1
                self.songs[index.row].isUpvoted = true
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }
    
    func didPressDownButton(at index: IndexPath) {
        songs[index.row].reference.child("votes").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if let votes = currentData.value as? Int {
                currentData.value = votes - 1
                self.songs[index.row].isUpvoted = false
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }
}
