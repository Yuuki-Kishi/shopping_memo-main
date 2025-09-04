//
//  NoticeListViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2025/09/04.
//

import UIKit

class NoticeListViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        titleLabel.adjustsFontSizeToFitWidth = true
        timeLabel.adjustsFontSizeToFitWidth = true
    }
    
}
