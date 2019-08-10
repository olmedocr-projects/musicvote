//
//  QrViewController.swift
//  MusicVote
//
//  Created by Raul Olmedo on 07/11/2018.
//

import UIKit
import QRCode

class QrViewController: UIViewController {
    // MARK: - Properties
    var authorizationToken: String!
    var hostId: String!
    
    // MARK: - IBOutlets
    @IBOutlet weak var qrImageView: UIImageView!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let dictionary: [String: String] = ["authToken": authorizationToken, "hostId": hostId]
        let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        var qrCode = QRCode(jsonString!)
        qrCode?.size = CGSize(width: 300, height: 300)
        qrCode?.backgroundColor = CIColor(color: ColorPalette.darkMain)
        qrCode?.color = CIColor(color: ColorPalette.lightAccent)
        qrImageView.image = qrCode?.image
    }

}
