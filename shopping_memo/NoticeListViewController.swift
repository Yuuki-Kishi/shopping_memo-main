//
//  NoticeViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2025/08/29.
//
import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore

class NoticeListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noCellLabel: UILabel!
    
    var alertArray = [(alertId: String, alertTitle: String, alertMessage: String, content: String, creationTime: Date, isAlert: Bool, minVersion: Double, maxVersion: Double)]()
    var tappedIndex: Int!
    var ref: DatabaseReference!
    var userId: String!
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        updateNoticeCheckedTime()
        checkIsMaintanance()
        setUpAndObserveRealtimeDatabase()
    }
    
    func UISetUp() {
        title = "通知一覧"
        tableView.delegate = self
        tableView.dataSource = self
        noCellLabel.isHidden = true
        noCellLabel.adjustsFontSizeToFitWidth = true
        tableView.register(UINib(nibName: "NoticeListViewCell", bundle: nil), forCellReuseIdentifier: "NoticeListViewCell")
    }
    
    func updateNoticeCheckedTime() {
        userId = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let now = dateFormatter.string(from: Date())
        self.ref.child("users").child(userId).child("metadata").updateChildValues(["noticeCheckedTime": now])
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
        
    func setUpAndObserveRealtimeDatabase() {
        GeneralPurpose.AIV(VC: self, view: view, status: "start")
        Firestore.firestore().collection("alerts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                let alertId = document.documentID
                let documentData = document.data()
                guard let alertTitle = documentData["alertTitle"] as? String else { continue }
                guard let alertMessage = documentData["alertMessage"] as? String else { continue }
                guard let alertContent = documentData["content"] as? String else { continue }
                guard let creationTimeString = documentData["creationTime"] as? String else { continue }
                let formatter = ISO8601DateFormatter()
                guard let creationTime = formatter.date(from: creationTimeString) else { continue }
                guard let isAlert = documentData["isAlert"] as? Bool else { continue }
                guard let minVersion = documentData["minVersion"] as? Double else { continue }
                guard let maxVersion = documentData["maxVersion"] as? Double else { continue }
                if creationTime > Date() { continue }
                self.alertArray.append((alertId: alertId, alertTitle: alertTitle, alertMessage: alertMessage, content: alertContent, creationTime: creationTime, isAlert: isAlert, minVersion: minVersion, maxVersion: maxVersion))
            }
            self.alertArray.sort { $0.creationTime > $1.creationTime }
            self.tableView.reloadData()
            GeneralPurpose.AIV(VC: self, view: self.view, status: "stop")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if alertArray.isEmpty { noCellLabel.isHidden = false }
        else { noCellLabel.isHidden = true}
        return alertArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateFormatter = DateFormatter()
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeListViewCell") as! NoticeListViewCell
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = .current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        cell.titleLabel.text = alertArray[indexPath.section].alertTitle
        let creationTime = alertArray[indexPath.section].creationTime
        let creationTimeString = dateFormatter.string(from: creationTime)
        cell.timeLabel.text = creationTimeString
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tappedIndex = indexPath.section
        GeneralPurpose.segue(VC: self, id: "toNVC", connect: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNVC" {
            let next = segue.destination as! NoticeViewController
            next.alertTitle = alertArray[tappedIndex].alertTitle
            next.creationTime = alertArray[tappedIndex].creationTime
            next.content = alertArray[tappedIndex].content
        }
    }
}
