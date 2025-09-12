//
//  RelayViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/11/20.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore

class RelayViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    var userDefaults: UserDefaults = UserDefaults.standard
    var ref: DatabaseReference!
    var connect = false
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        setUpDataAndDelegate()
        checkIsMaintanance()
    }
    
    func UISetUp() {
        title = "アカウント引き継ぎ"
        signInButton.layer.cornerRadius = 18.0
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    func setUpDataAndDelegate() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.text = userDefaults.string(forKey: "email")
        ref = Database.database().reference()
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signInBut() {
        if connect {
            signIn()
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if connect {
            signIn()
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
        return true
    }
    
    func signIn() {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        if emailTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if !connect {
            GeneralPurpose.notConnectAlert(VC: self)
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(result.user.uid, forKey: "userId")
                    let alert: UIAlertController = UIAlertController(title: "引き継ぎ準備が完了しました", message: "即座に新しいアカウントでログインしてください。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        let firebaseAuth = Auth.auth()
                        firebaseAuth.currentUser?.delete { error in
                            if let error = error {
                                print("error")
                            } else {
                                print("succeed")
                            }
                        }
                        do {
                            try firebaseAuth.signOut()
                        } catch let signOutError as NSError {
                            print ("Error signing out: %@", signOutError)
                        }
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("error: \(error!)")
                    let errorCode = (error as? NSError)?.code
                    if errorCode == 17008 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17009 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "パスワードが正しくありません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17011 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "アカウントが存在しません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
