//
//  TransferViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/10/30.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class TransferViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    
    var ref: DatabaseReference!
    var userId: String!
    var dateFormatter = DateFormatter()
    var roomIdString: String!
    var connect = false
    
    var administratorArray = [(uId: String, userName: String, authority: String, email: String)]()
    var memberArray = [(uId: String, userName: String, authority: String, email: String)]()
    var guestArray = [(uId: String, userName: String, authority: String, email: String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUpAndData()
        obserbeRealtimeDatabase()
    }
    
    func UISetUpAndData() {
        title = "管理者権限を譲渡"
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
                GeneralPurpose.notConnectAlert(VC: self)
            }
        })
    }
    
    func obserbeRealtimeDatabase() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childAdded, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start")
            let userId = snapshot.key
            ref.child("rooms").child(roomIdString).child("members").observeSingleEvent(of: .value, with: { [self] snapshot in
                let userCount = snapshot.childrenCount
                ref.child("rooms").child(roomIdString).child("members").child(userId).observeSingleEvent(of: .value, with: { [self] snapshot in
                    guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
                    guard let email = snapshot.childSnapshot(forPath: "email").value as? String else { return }
                    ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                        if authority == "member" {
                            memberArray.append((uId: userId, userName: userName, authority: authority, email: email))
                        } else if authority == "guest" {
                            guestArray.append((uId: userId, userName: userName, authority: authority, email: email))
                        } else {
                            administratorArray.append((uId: userId, userName: userName, authority: authority, email: email))
                        }
                        if userCount == administratorArray.count + memberArray.count + guestArray.count {
                            GeneralPurpose.AIV(VC: self, view: view, status: "stop")
                            if memberArray.isEmpty { noMemberAlert() }
                        }
                        tableView.reloadData()
                    })
                })
            })
        })
        
        ref.child("users").observe(.childChanged, with: { [self] snapshot in
            let userId = snapshot.key
            ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                if let mIndex = memberArray.firstIndex(where: {$0.uId == userId}) {
                    memberArray[mIndex].userName = userName
                } else if let gIndex = guestArray.firstIndex(where: {$0.uId == userId}) {
                    guestArray[gIndex].userName = userName
                }
                tableView.reloadData()
            })
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childChanged, with: { [self] snapshot in
            let userId = snapshot.key
            guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
            if authority == "member" {
                guard let index = guestArray.firstIndex(where: {$0.uId == userId}) else { return }
                let userName = guestArray[index].userName
                let email = guestArray[index].email
                guestArray.remove(at: index)
                memberArray.append((uId: userId, userName: userName, authority: authority, email: email))
            }
            tableView.reloadData()
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childRemoved, with: { [self] snapshot in
            let userId = snapshot.key
            if let index = memberArray.firstIndex(where: {$0.uId == userId}) { memberArray.remove(at: index) }
            tableView.reloadData()
        })
    }
    
    func noMemberAlert() {
        let alert: UIAlertController = UIAlertController(title: "権限を譲渡できません", message: "権限を譲渡するには一人以上のメンバーが必要です。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var section = 1
        if !memberArray.isEmpty { section += 1}
        if !guestArray.isEmpty { section += 1}
        return section
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        
        let title = UILabel()
        let sectionNumber = tableView.numberOfSections
        switch sectionNumber {
        case 3:
            switch section {
            case 0:
                title.text = "管理者"
            case 1:
                title.text = "メンバー"
            default:
                title.text = "招待中"
            }
        case 2:
            if memberArray.isEmpty {
                switch section {
                case 0:
                    title.text = "管理者"
                default:
                    title.text = "招待中"
                }
            } else if guestArray.isEmpty {
                switch section {
                case 0:
                    title.text = "管理者"
                default:
                    title.text = "メンバー"
                }
            }
        default:
            break
        }
        
        title.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        title.textColor = .label
        title.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        title.sizeToFit()
        headerView.addSubview(title)

        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true

        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        if section == 0 {
            cellCount = administratorArray.count
        } else if section == 1 {
            if guestArray.isEmpty {
                cellCount = memberArray.count
            } else if memberArray.isEmpty {
                cellCount = guestArray.count
            } else {
                cellCount = memberArray.count
            }
        } else {
            cellCount = guestArray.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as! SettingTableViewCell
        if section == 0 {
            cell.ItemLabel.text = administratorArray[indexPath.row].userName
            cell.DataLabel.text = administratorArray[indexPath.row].email
            let userId = administratorArray[indexPath.row].uId
            if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
            else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            cell.selectionStyle = .none
        } else if section == 1 {
            if guestArray.isEmpty {
                cell.ItemLabel.text = memberArray[indexPath.row].userName
                cell.DataLabel.text = memberArray[indexPath.row].email
                let userId = memberArray[indexPath.row].uId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            } else if memberArray.isEmpty {
                cell.ItemLabel.text = guestArray[indexPath.row].userName
                cell.DataLabel.text = guestArray[indexPath.row].email
                let userId = guestArray[indexPath.row].uId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
                cell.selectionStyle = .none
            } else {
                cell.ItemLabel.text = memberArray[indexPath.row].userName
                cell.DataLabel.text = memberArray[indexPath.row].email
                let userId = memberArray[indexPath.row].uId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            }
        } else {
            cell.ItemLabel.text = guestArray[indexPath.row].userName
            cell.DataLabel.text = guestArray[indexPath.row].email
            let userId = guestArray[indexPath.row].uId
            if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
            else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            cell.selectionStyle = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if connect {
            if indexPath.section == 1 {
                let alert: UIAlertController = UIAlertController(title: "本当に管理者権限を譲渡しますか？", message: "再度権限を得るには保持者に譲渡してもらう必要があります。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                alert.addAction(UIAlertAction(title: "譲渡", style: .destructive, handler: { _ in
                    let oldHolder = self.administratorArray[indexPath.row].uId
                    let newHolder = self.memberArray[indexPath.row].uId
                    self.ref.child("rooms").child(self.roomIdString!).child("members").child(oldHolder).updateChildValues(["authority": "member"])
                    self.ref.child("users").child(oldHolder).child("rooms").updateChildValues([self.roomIdString!: "member"])
                    self.ref.child("rooms").child(self.roomIdString!).child("members").child(newHolder).updateChildValues(["authority": "administrator"])
                    self.ref.child("users").child(newHolder).child("rooms").updateChildValues([self.roomIdString!: "administrator"])
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
}
