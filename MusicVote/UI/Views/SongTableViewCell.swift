//
//  SongTableViewCell.swift
//  MusicVote
//
//  Created by Raul Olmedo on 19/10/2018.
//

import UIKit

protocol SongCellDelegate: class {
    func didPressAddButton(at index: IndexPath)
}

class SongTableViewCell: UITableViewCell {
    // MARK: - Properties
    weak var delegate: SongCellDelegate!
    var indexPath: IndexPath!
    
    // MARK: - IBOutlets
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBAction func didTapAddButton(_ sender: UIButton) {
        self.delegate?.didPressAddButton(at: indexPath)
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
