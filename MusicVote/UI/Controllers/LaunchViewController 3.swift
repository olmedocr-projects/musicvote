//
//  LaunchViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 01/12/2018.
//

import UIKit
import GoogleSignIn
import Firebase
import os.log

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
    }
}

extension LaunchViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            os_log("Failed to sign in using Google with error: %@", error.localizedDescription)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "loginViewController")
            UIApplication.shared.keyWindow?.rootViewController?.present(viewController, animated: true, completion: nil)
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        os_log("Success loggin into Google: %@", credential.debugDescription)
        
        // Pop the loginView if the user logged in for the first time and it was successfull
        if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? LoginViewController != nil {
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
        }
        
        Auth.auth().signInAndRetrieveData(with: credential) { (_, error) in
            if let error = error {
                os_log("Failed to sign in into Firebase with error: %@", error.localizedDescription)
                return
            }
            // User is signed in
            os_log("Success authenticating into Firebase: %@", credential.debugDescription)
            
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        os_log("User disconnected")
    }
}
