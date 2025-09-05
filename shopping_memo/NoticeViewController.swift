//
//  NoticeViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2025/09/05.
//

import UIKit

class NoticeViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var creationTimeLabel: UILabel!
    @IBOutlet var contentTextView: UITextView!
    
    var alertTitle: String!
    var creationTime: Date!
    var content: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
    }
    
    func UISetUp() {
        title = "通知"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        titleLabel.text = alertTitle
        creationTimeLabel.text = dateFormatter.string(from: creationTime)
        contentTextView.text = content
    }

}
