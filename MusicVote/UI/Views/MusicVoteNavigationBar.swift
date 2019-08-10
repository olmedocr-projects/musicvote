//
//  MusicVoteLabel.swift
//  MusicVote
//
//  Created by Raul Olmedo on 07/12/2018.
//

import UIKit

class MusicVoteNavigationBar: UINavigationBar {
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()

        self.barStyle = UIBarStyle.blackOpaque
        self.isTranslucent = false
        self.prefersLargeTitles = true
        //self.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        //self.shadowImage = UIImage()
        self.barTintColor = ColorPalette.darkMain
    }
}
