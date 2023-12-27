//
//  ContentView.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import SwiftUI

struct ContentView: View {
    
    var viewModel = WatchViewModel()
    
    @State var testData = ["キャベツ", "トマト", "レタス", "ジャガイモ", "ダイコン", "ゴボウ", "モヤシ", "ピーマン"]
    
    @State var listName: String!
    @State var memoArray = [(memoId: String, shoppingMemo: String, imageUrl: String)]()
    @State var isShowProgressView = false
    @State var isLink = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        if !memoArray.isEmpty {
            NavigationView {
                ZStack {
                    List {
                        ForEach(Array(memoArray.enumerated()), id: \.element.memoId) { index, memo in
                            //MARK: out of range
                            let shoppingMemo = memo.shoppingMemo
                            let imageUrl = memo.imageUrl
                            HStack {
                                Button(action: {
                                    sendMessage(index: index)
                                    isShowProgressView = true
                                }){
                                    Image(systemName: "square")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 30, height: 25)
                                Text(shoppingMemo)
                                Spacer()
                                if imageUrl == "" {
                                    Image(systemName: "plus.viewfinder")
                                } else {
                                    Image(systemName: "photo")
                                }
                            }
                        }
                    }
                    if isShowProgressView {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(Color.white)
                    }
                }
                .navigationTitle(listName)
                .environment(\.defaultMinListRowHeight, 25)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    isLink = false
                    memoArray = []
                }
            }
        } else {
            if isLink {
                VStack {
                    Image(systemName: "externaldrive.badge.xmark")
                        .resizable()
                        .foregroundColor(Color.primary)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text("表示可能な項目がありません")
                }
            } else {
                VStack {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .resizable()
                        .foregroundColor(Color.primary)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text("接続準備完了")
                }
                .onAppear {
                    viewModel.watchDelegate = self
                }
            }
        }
    }
    
    private func sendMessage(index: Int) {
        let messages: [String : Any] = ["request": "check", "index": index]
        self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
            print("error:", error.localizedDescription)
        }
    }
}

extension ContentView: WatchViewModelDelegate {
    func reloadData() {
        isLink = viewModel.isLink
        listName = viewModel.listName
        memoArray = viewModel.memoArray
        isShowProgressView = false
    }
    
    
}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(, imageUrl: "aiuu")
//    }
//}
