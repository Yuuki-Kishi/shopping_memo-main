//
//  ShoppingMemoListViewModel.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import Foundation
import WatchConnectivity

final class WatchViewModel: NSObject {
    var session: WCSession
    var memoArray = [(memoId: String, shoppingMemo: String, imageUrl: String)]()
    var listName = ""
    var watchDelegate: WatchViewModelDelegate? = nil
    var isLink = false
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
}

extension WatchViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("The session has completed activation.")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            let notice = message["notice"] as? String ?? ""
            if notice == "sendData" || notice == "reloadData" {
                guard let listName = message["listName"] as? String else { return }
                guard let memoIdArray = message["memoId"] as? Array<String> else { return }
                guard let shoppingMemoArray = message["shoppingMemo"] as? Array<String> else { return }
                guard let imageUrlArray = message["imageUrl"] as? Array<String> else { return }
                self.memoArray = []
                for i in 0 ..< memoIdArray.count {
                    self.memoArray.append((memoId: memoIdArray[i], shoppingMemo: shoppingMemoArray[i], imageUrl: imageUrlArray[i]))
                }
                self.listName = listName
                self.isLink = true
                self.watchDelegate?.reloadData()
                if notice == "sendData" {
                    let messages: [String : Any] = ["request": "getData"]
                    session.sendMessage(messages, replyHandler: nil) { (error) in
                        print("error:", error.localizedDescription)
                    }
                }
            } else if notice == "launched" {
                let messages: [String : Any] = ["request": "launched"]
                session.sendMessage(messages, replyHandler: nil) { (error) in
                    print("error:", error.localizedDescription)
                }
            } else if notice == "clear" || notice == "secretClear" {
                self.listName = ""
                self.isLink = false
                self.memoArray.removeAll()
                self.watchDelegate?.reloadData()
                if notice == "clear" {
                    let messages: [String : Any] = ["request": "clearData"]
                    session.sendMessage(messages, replyHandler: nil) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

protocol WatchViewModelDelegate {
    func reloadData()
}
