//
//  MusicVoteButton.swift
//  MusicVote
//
//  Created by Raul Olmedo on 07/12/2018.
//

import UIKit

class MusicVoteButton: UIButton {
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 5
        self.backgroundColor = ColorPalette.lightAccent
        self.tintColor = UIColor.black
    }

}
