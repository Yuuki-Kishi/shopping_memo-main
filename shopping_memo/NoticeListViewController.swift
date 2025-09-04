//
//  NoticeViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2025/08/29.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class NoticeListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noCellLabel: UILabel!
    
    var alertArray = [(alertId: String, alertTitle: String, alertMessage: String, alertContent: String, creationTime: Date, isAlert: Bool, minVersion: Double, maxVersion: Double)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
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
    
    func setUpAndObserveRealtimeDatabase() {
        GeneralPurpose.AIV(VC: self, view: view, status: "start")
        Firestore.firestore().collection("alerts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                let alertId = document.documentID
                let documentData = document.data()
                guard let alertTitle = documentData["alertTitle"] as? String else { continue }
                guard let alertMessage = documentData["alertMessage"] as? String else { continue }
                guard let alertContent = documentData["alertContent"] as? String else { continue }
                guard let creationTimeString = documentData["creationTime"] as? String else { continue }
                let formatter = ISO8601DateFormatter()
                guard let creationTime = formatter.date(from: creationTimeString) else { continue }
                guard let isAlert = documentData["isAlert"] as? Bool else { continue }
                guard let minVersion = documentData["minVersion"] as? Double else { continue }
                guard let maxVersion = documentData["maxVersion"] as? Double else { continue }
                self.alertArray.append((alertId: alertId, alertTitle: alertTitle, alertMessage: alertMessage, alertContent: alertContent, creationTime: creationTime, isAlert: isAlert, minVersion: minVersion, maxVersion: maxVersion))
            }
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
        cell.titleLabel.text = alertArray[indexPath.row].alertTitle
        let creationTime = alertArray[indexPath.row].creationTime
        let creationTimeString = dateFormatter.string(from: creationTime)
        cell.timeLabel.text = creationTimeString
        return cell
    }
}
