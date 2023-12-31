//
//  GeneralPurpose.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/18.
//

import UIKit
import Foundation
import FirebaseAuth
import FirebaseDatabase

class GeneralPurpose {
    
    static let dateFormatter = DateFormatter()
    static let ref = Database.database().reference()
    static let AIV = UIActivityIndicatorView()

    static func notConnectAlert(VC: UIViewController) {
        let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        VC.present(alert, animated: true)
    }
    
    static func updateEditHistory(roomId: String) {
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let timeNow = dateFormatter.string(from: Date())
        let editor = Auth.auth().currentUser?.uid
        ref.child("rooms").child(roomId).child("info").updateChildValues(["lastEditTime": timeNow, "lastEditor": editor!])
    }
    
    static func AIV(VC: UIViewController, view: UIView, status: String) {
        if status == "start" {
            AIV.center = view.center
            AIV.style = .large
            AIV.color = .label
            view.addSubview(AIV)
            AIV.startAnimating()
        } else if status == "stop" {
            AIV.stopAnimating()
        }
    }
    
    static func segue(VC: UIViewController, id: String, connect: Bool) {
        if connect { VC.performSegue(withIdentifier: id, sender: nil) }
        else { notConnectAlert(VC: VC) }
    }
    
    static func noData(VC: UIViewController, num: Int) {
        let alert: UIAlertController = UIAlertController(title: "閲覧中のデータが削除されました", message: "ホームに戻ります。詳しくは削除実行者にお問い合わせください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
            let viewControllers = VC.navigationController?.viewControllers
            VC.navigationController?.popToViewController(viewControllers![viewControllers!.count - num], animated: true)
        }))
        VC.present(alert, animated: true, completion: nil)
    }
}
