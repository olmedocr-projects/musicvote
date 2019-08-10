//
//  SearchViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 14/10/2018.
//

import UIKit
import Spartan
import Kingfisher
import FirebaseDatabase
import NVActivityIndicatorView
import Alamofire

protocol SearchViewControllerDelegate: class {
    func songAddedToQueue(song: Track)
}

class SearchViewController: UITableViewController {
    // MARK: - Properties
    weak var delegate: SearchViewControllerDelegate!
    let defaultImageURL: String = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxtVFrGlu-W8CsCKncYpJQ3pvQjRIwsraMmQDyIiquE3lOSnbu"
    var trackSearchResult: PagingObject<Track>?
    var trackIsAdded: [Bool]!
    var ref: DatabaseReference!
    var refreshToken: String!
    var searchBar: UISearchBar!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref.parent?.child("refreshToken").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let remoteRefreshToken = snapshot.value as? String {
                self.refreshToken = remoteRefreshToken
            }
        }, withCancel: { (error) in
            print("Error while trying to get the token from firebase: \(error.localizedDescription)")
        })
        
        ref.parent?.child("authToken").observe(DataEventType.value, with: { (snapshot) in
            if let authToken = snapshot.value as? String {
                Spartan.authorizationToken = authToken
            } else {
                print("authToken could not be fetched from firebase, the value of the snapshot is \(snapshot.value ?? "null")")
            }
        }, withCancel: { (error) in
            print("Error while observing authToken endpoint: \(error.localizedDescription)")
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Check if we are authenticated by queuing a silent track!
        Spartan.getTrack(id: "42C5Bbb4dHwS5OFMvtGkG2", success: { (_) in
            // Do nothing, we are okay
        }, failure: { (error) in
            
            if error.errorType == SpartanErrorType.unauthorized {
                print("Unauthorized, token expired (testing it before making an actual search)")
                
                let activityData = ActivityData()
                NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
                NVActivityIndicatorPresenter.sharedInstance.setMessage(NSLocalizedString("Authenticating with Spotify", comment: ""))
                
                let request = Alamofire.request("https://music-vote-app.herokuapp.com/api/refresh_token", method: .post, parameters: ["refresh_token": "[\(self.refreshToken ?? "null")]"])
                
                request.responseJSON(completionHandler: { (response) in
                    if let responseDict = response.result.value as? [String: Any], let authToken = responseDict["access_token"] as? String {
                        print(authToken as Any)
                        Spartan.authorizationToken = authToken
                        self.ref.parent?.child("authToken").setValue(authToken)
                    } else {
                        print("Error while parsing auth token")
                        NVActivityIndicatorPresenter.sharedInstance.setMessage(NSLocalizedString("Error!", comment: ""))
                    }
                    NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
                })
            }
        })
    }
    
    // MARK: - UI Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of cells per section
        return (trackSearchResult?.items.count) ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        // Song cell
        let songCell = self.tableView.dequeueReusableCell(withIdentifier: "songTableViewCell", for: indexPath) as! SongTableViewCell
        
        songCell.titleLabel?.text = trackSearchResult?.items?[indexPath.row].name
        songCell.albumLabel?.text = trackSearchResult?.items?[indexPath.row].album.name
        songCell.artistLabel?.text = trackSearchResult?.items?[indexPath.row].artists[0].name
        songCell.delegate = self
        songCell.indexPath = indexPath
        songCell.addButton.isEnabled = !trackIsAdded[indexPath.row]
        cell = songCell
        
        return cell
    }
    
}

// MARK: - UI Search Results Updating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText: String = searchController.searchBar.text!
        if searchText != "" {
            // Query tracks
            _ = Spartan.search(query: searchText, type: .track, success: { (pagingObject: PagingObject<Track>) in
                self.trackSearchResult = pagingObject
                self.trackIsAdded = Array(repeating: false, count: pagingObject.items.count)
                self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }, failure: { (error) in
                if error.errorType == .unauthorized {
                    print("Unauthorized, token expired")
                } else {
                    print(error)
                }
            })
        }
        
    }
    
}

// MARK: - Song Cell Delegate
extension SearchViewController: SongCellDelegate {
    func didPressAddButton(at index: IndexPath) {
        self.trackIsAdded[index.row] = true
        self.tableView.reloadData()
        self.delegate.songAddedToQueue(song: (trackSearchResult?.items[index.row])!)
    }
}
