//
//  DeleteViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/05/21.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore
import FirebaseAuth

class DeleteViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    
    var ref: DatabaseReference!
    let userDefaults: UserDefaults = UserDefaults.standard
    var connect = false
    var isAdministrator = false
    var roomCount = 0
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        setUpData()
        checkIsMaintanance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func setUpData() {
        ref = Database.database().reference()
        let userId = Auth.auth().currentUser?.uid
        ref.child("users").child(userId!).child("rooms").observeSingleEvent(of: .value, with: { [self] snapshot in
            roomCount = Int(snapshot.childrenCount)
        })
        ref.child("users").child(userId!).child("rooms").observe(.childAdded, with: { [self] snapshot in
            let roomId = snapshot.key
            ref.child("users").child(userId!).child("rooms").observeSingleEvent(of: .value, with: { [self] snapshot in
                guard let authority = snapshot.childSnapshot(forPath: roomId).value as? String else { return }
                if authority == "administrator" { isAdministrator = true }
            })
        })
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    func UISetUp() {
        title = "アカウント削除"
        emailLabel.text = " " + (Auth.auth().currentUser?.email)! + " "
        emailLabel.layer.cornerRadius = 6.0
        emailLabel.clipsToBounds = true
        emailLabel.adjustsFontSizeToFitWidth = true
        userIdLabel.text = " " + Auth.auth().currentUser!.uid + " "
        userIdLabel.layer.cornerRadius = 6.0
        userIdLabel.clipsToBounds = true
        userIdLabel.adjustsFontSizeToFitWidth = true
        deleteButton.layer.cornerRadius = 18.0
    }
    
    func checkIsMaintanance() {
        Firestore.firestore().collection("DBInfo").document("Maintenance").addSnapshotListener { [self]  querySnapshot, error in
            guard let startTimeString = querySnapshot?.get("startTime") as? String else { return }
            guard let endTimeString = querySnapshot?.get("endTime") as? String else { return }
            guard let isMaintenance = querySnapshot?.get("isMaintenance") as? Bool else { return }
            let formatter = ISO8601DateFormatter()
            guard let startTime = formatter.date(from: startTimeString) else { return }
            guard let endTime = formatter.date(from: endTimeString) else { return }
            if isMaintenance {
                dateFormatter.dateFormat = "MM/dd HH:mm"
                dateFormatter.timeZone = .autoupdatingCurrent
                dateFormatter.locale = .autoupdatingCurrent
                let displayStartTimeString = dateFormatter.string(from: startTime)
                let displayEndTimeString = dateFormatter.string(from: endTime)
                let message = "\(displayStartTimeString)から\(displayEndTimeString)はメンテナンス中です。\nこれ以降に再度お試しください。\nなお、終了時刻は繰り上がる場合があります。"
                let alert: UIAlertController = UIAlertController(title: "現在メンテナンス中です", message: message, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func delete() {
        if connect && !isAdministrator {
            let alert: UIAlertController = UIAlertController(title: "アカウントを削除してもよろしいですか？", message: "この操作は取り消すことはできません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { action in
                let userId = Auth.auth().currentUser?.uid
                self.ref.child("users").child(userId!).child("rooms").observe(.childAdded, with: { [self] snapshot in
                    let roomId = snapshot.key
                    ref.child("rooms").child(roomId).child("members").observeSingleEvent(of: .value, with: { [self] snapshot in
                        let memberCount = snapshot.childrenCount
                        if memberCount == 1 { ref.child("rooms").child(roomId).removeValue() }
                        else { ref.child("rooms").child(roomId).child("members").child(userId!).removeValue() }
                        ref.child("users").child(userId!).removeValue()
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                print("error")
                            } else {
                                self.userDefaults.removeObject(forKey: "email")
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                        return
                    })
                })
                let user = Auth.auth().currentUser
                user?.delete { error in
                    if let error = error {
                        print("error")
                    } else {
                        self.userDefaults.removeObject(forKey: "email")
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        } else if isAdministrator {
            let alert: UIAlertController = UIAlertController(title: "削除できません", message: "あなたが管理者のルームがあります。管理者権限を譲渡してからやり直してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
}
