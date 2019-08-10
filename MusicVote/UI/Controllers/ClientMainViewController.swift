//
//  ClientMainViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 08/11/2018.
//

import UIKit
import AVFoundation
import QRCodeReader
import Spartan
import FirebaseDatabase

class ClientMainViewController: UIViewController {
    // MARK: - Properties
    var searchController: UISearchController!
    var searchViewController: SearchViewController!
    var queueTableView: QueueTableViewController!
    var ref: DatabaseReference!
    var userId: String!
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearch()
        
        Spartan.loggingEnabled = false
        
        readerVC.delegate = self
        
        readerVC.modalPresentationStyle = .formSheet
        
        navigationController?.present(readerVC, animated: true, completion: nil)
        
    }
    
    // MARK: - Internal
    func setupSearch() {
        searchViewController = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as? SearchViewController
        searchViewController.delegate = self
        searchController = UISearchController(searchResultsController: searchViewController)
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        searchViewController.searchBar = searchController.searchBar
        searchViewController.searchBar.setValue("Done", forKey: "cancelButtonText")
        searchController.searchResultsUpdater = searchViewController
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = NSLocalizedString("Search in Spotify", comment: "") 
        searchController.searchBar.tintColor = ColorPalette.lightAccent
        
        definesPresentationContext = true
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "shareQRSegue" {
            if let destination = segue.destination as? QrViewController {
                destination.authorizationToken = Spartan.authorizationToken
                destination.hostId = self.userId
            }
        } else if let destination = segue.destination as? QueueTableViewController {
            queueTableView = destination
        }
    }

}

// MARK: - QR Reader View Controller Delegate
extension ClientMainViewController: QRCodeReaderViewControllerDelegate {
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        let dictionary = convertToDictionary(text: result.value)
        if let token = dictionary?["authToken"] as? String, let hostId = dictionary?["hostId"] as? String {
            reader.stopScanning()
            dismiss(animated: true, completion: nil)
            print("User scanned correctly: \(result.value)")
            
            Spartan.authorizationToken = token
            userId = hostId
            ref = Database.database().reference().child("sessions").child(userId).child("queue")
            searchViewController.ref = self.ref
            queueTableView.loadDatabaseObservers(ref: self.ref)
        }
        reader.startScanning()
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
        print("User canceled scanning")
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

// MARK: - Search View Controller Delegate
extension ClientMainViewController: SearchViewControllerDelegate {
    func songAddedToQueue(song: Track) {
        let newRef = ref.childByAutoId()
        newRef.child("track").setValue(song.toJSON())
        newRef.child("votes").setValue(0)
    }
}
