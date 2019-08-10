//
//  QueueTableViewCell.swift
//  MusicVote
//
//  Created by Raul Olmedo on 12/11/2018.
//

import UIKit
import Firebase

protocol QueueCellDelegate: class {
    func didPressUpButton(at index: IndexPath)
    func didPressDownButton(at index: IndexPath)
}

class QueueTableViewCell: UITableViewCell {
    // MARK: - Properties
    weak var delegate: QueueCellDelegate!
    var indexPath: IndexPath!

    // MARK: - IBOutlets
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var songAlbum: UILabel!
    @IBOutlet weak var votes: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var upvoteButton: UIButton!
    
    // MARK: - IBActions
    @IBAction func didTapUpButton(_ sender: UIButton) {
        self.delegate?.didPressUpButton(at: indexPath)
    }
    
    @IBAction func didTapDownButton(_ sender: UIButton) {
        self.delegate?.didPressDownButton(at: indexPath)
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        thumbImageView.layer.cornerRadius = CGFloat(5)
        thumbImageView.clipsToBounds = true
    }
}
