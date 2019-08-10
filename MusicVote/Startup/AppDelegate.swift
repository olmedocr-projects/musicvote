//
//  AppDelegate.swift
//  MusicVote
//
//  Created by Raul Olmedo on 10/10/2018.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

struct ColorPalette {
    static let darkMain = UIColor(red: 0.17, green: 0.18, blue: 0.19, alpha: 1.0) // 2c2e30
    static let lightMain = UIColor(red: 0.27, green: 0.29, blue: 0.29, alpha: 1.0) // 464949
    static let darkAccent = UIColor(red: 0.56, green: 0.58, blue: 0.58, alpha: 1.0) // 8f9393
    static let lightAccent = UIColor(red: 0.60, green: 0.86, blue: 0.88, alpha: 1.0) // 98dce0
    static let background = UIColor(red: 0.33, green: 0.43, blue: 0.48, alpha: 1.0) // 536d7a
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var isNotFirstTimeLaunch: Bool!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = ColorPalette.darkMain
        UITextField.appearance().keyboardAppearance = .dark
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        // Check if the user is laucnhing the app for the first time
        isNotFirstTimeLaunch = UserDefaults.standard.bool(forKey: "isNotFirstTimeLaunch")
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String? {
            if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
                return true
            }
        }
        if SPTAuth.defaultInstance().canHandle(url) {
            // Send out a notification which we can listen for in our sign in view controller
            NotificationCenter.default.post(name: NSNotification.Name.Spotify.authURLOpened, object: url)
            return true
        }
        // other URL handling goes here.
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
