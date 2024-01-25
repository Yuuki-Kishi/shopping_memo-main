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
    @State var isBackground = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        if !isBackground {
            if isLink {
                if memoArray.isEmpty {
                    ZStack {
                        VStack {
                            Image(systemName: "externaldrive.badge.xmark")
                                .resizable()
                                .foregroundColor(Color.primary)
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            Text("未完了項目がありません")
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    requestReloadData()
                                }, label: {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.system(size: 20.0))
                                })
                                .foregroundColor(.black)
                                .background(Color.accentColor)
                                .frame(width: 35.0, height: 35.0)
                                .clipShape(RoundedRectangle(cornerRadius: 17.5))
                                .padding()
                            }
                        }
                    }
                    .onChange(of: scenePhase) { phase in
                        if phase == .background {
                            isBackground = true
                        } else if phase == .active {
                            isBackground = false
                        }
                    }
                    .onAppear {
                        viewModel.watchDelegate = self
                        requestReloadData()
                    }
                } else {
                    NavigationStack {
                        ZStack {
                            List {
                                ForEach(Array(memoArray.enumerated()), id: \.element.memoId) { index, memo in
                                    //MARK: out of range
                                    let memoId = memo.memoId
                                    let shoppingMemo = memo.shoppingMemo
                                    let imageUrl = memo.imageUrl
                                    HStack {
                                        Button(action: {
                                            sendMessage(memoId: memoId)
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
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        requestReloadData()
                                    }, label: {
                                        Image(systemName: "arrow.clockwise.circle")
                                            .font(.system(size: 20.0))
                                    })
                                    .foregroundColor(.black)
                                    .background(Color.accentColor)
                                    .frame(width: 35.0, height: 35.0)
                                    .clipShape(RoundedRectangle(cornerRadius: 17.5))
                                    .padding()
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
                            isBackground = true
                        } else if phase == .active {
                            isBackground = false
                        }
                    }
                    .onAppear {
                        viewModel.watchDelegate = self
                        requestReloadData()
                    }
                }
            } else {
                let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                VStack {
                    Spacer()
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .resizable()
                        .foregroundColor(Color.primary)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text("接続準備完了")
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Version: " + AppVer!)
                    }
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        isBackground = true
                    } else if phase == .active {
                        isBackground = false
                    }
                }
                .onAppear {
                    viewModel.watchDelegate = self
                }
            }
        } else {
            let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            VStack {
                Spacer()
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .resizable()
                    .foregroundColor(Color.primary)
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("接続準備完了")
                Spacer()
                HStack {
                    Spacer()
                    Text("Version: " + AppVer!)
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    isBackground = true
                } else if phase == .active {
                    isBackground = false
                }
            }
        }
    }
    
    private func sendMessage(memoId: String) {
        let messages: [String : Any] = ["request": "check", "memoId": memoId]
        self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
            print("error:", error.localizedDescription)
        }
    }
    
    private func requestReloadData() {
        let messages:[String : Any] = ["request": "reloadData"]
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
//        ContentView()
//    }
//}
