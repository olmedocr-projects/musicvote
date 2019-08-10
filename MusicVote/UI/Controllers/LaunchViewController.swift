//
//  LaunchViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 01/12/2018.
//

import UIKit
import Firebase
import NVActivityIndicatorView
import FirebaseUI

class LaunchViewController: UIViewController {
    // MARK: - Properties
    var authUI: FUIAuth?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI!.delegate = self
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth()
        ]
        authUI!.providers = providers
        authUI?.shouldHideCancelButton = true
        authUI?.auth?.useAppLanguage()
        if Auth.auth().currentUser?.uid == nil {
            let authViewController = authUI!.authViewController()
            self.present(authViewController, animated: true)
        }
    }
}

// MARK: - Firebase UI Auth Delegate
extension LaunchViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // Handle user returning from authenticating
        if error != nil {
            print("Error while authenticating in Firebase with error: \(error?.localizedDescription ?? "null")")
        }
        
        if user != nil {
            print("Success while authenticating in Firebase with user: \(user?.email ?? "null")")
        }
    }
}
