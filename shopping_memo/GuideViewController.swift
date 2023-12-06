//
//  GuideViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/12/03.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class GuideViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageV: UIImageView!
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    
    var administratorImageNameArray = ["titleAdministrator", "makeRoom", "chooseRoom", "makeList", "toMVC", "addMember", "chooseList", "writeMemo", "toIVVC", "uploadImage"]
    var memberImageNameArray = ["titleMember", "toInfo", "readQR", "chooseJoinRoom", "joinRoom", "chooseList", "writeMemo", "toIVVC", "uploadImage"]
    var tipsImageNameArray = ["titleTips", "roomMenu", "myInfo", "listMenu", "explainMemoScreen", "memoMenu"]
    var administratorImageArray = [(sortNumber: Int, imageData: UIImage)]()
    var memberImageArray = [(sortNumber: Int, imageData: UIImage)]()
    var tipsImageArray = [(sortNumber: Int, imageData: UIImage)]()
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpData()
        menu()
    }
    
    func setUpData() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.storageAdministratorImage()
            } else {
                GeneralPurpose.notConnectAlert(VC: self)
            }
        })
    }
    
    func storageAdministratorImage() {
        GeneralPurpose.AIV(VC: self, view: view, status: "start")
        if administratorImageNameArray.count == administratorImageArray.count {
            for imageName in administratorImageNameArray {
                Task {
                    let image = await getImage(imageName: imageName, folderName: "administrator")
                    let sortNumber = self.administratorImageNameArray.firstIndex(of: imageName)
                    administratorImageArray.append((sortNumber: Int(sortNumber!), imageData: image!))
                    administratorImageArray.sort {$0.sortNumber < $1.sortNumber}
                    if administratorImageArray.count == administratorImageNameArray.count {
                        setUpScrollView(count: administratorImageArray.count)
                        setUpImageView(type: "administrator")
                        setUpPageControl(count: administratorImageArray.count)
                        GeneralPurpose.AIV(VC: self, view: view, status: "stop")
                    }
                }
            }
        } else {
            setUpScrollView(count: administratorImageArray.count)
            setUpImageView(type: "administrator")
            setUpPageControl(count: administratorImageArray.count)
            GeneralPurpose.AIV(VC: self, view: view, status: "stop")
        }
    }
    
    func storageMemberImage() {
        GeneralPurpose.AIV(VC: self, view: view, status: "start")
        if memberImageNameArray.count == memberImageArray.count {
            for imageName in memberImageNameArray {
                Task {
                    let image = await getImage(imageName: imageName, folderName: "member")
                    let sortNumber = self.memberImageNameArray.firstIndex(of: imageName)
                    memberImageArray.append((sortNumber: Int(sortNumber!), imageData: image!))
                    memberImageArray.sort {$0.sortNumber < $1.sortNumber}
                    print(imageName, sortNumber!, memberImageArray.count)
                    if memberImageArray.count == memberImageNameArray.count {
                        setUpScrollView(count: memberImageArray.count)
                        setUpImageView(type: "member")
                        setUpPageControl(count: memberImageArray.count)
                        GeneralPurpose.AIV(VC: self, view: view, status: "stop")
                    }
                }
            }
        } else {
            setUpScrollView(count: memberImageArray.count)
            setUpImageView(type: "member")
            setUpPageControl(count: memberImageArray.count)
            GeneralPurpose.AIV(VC: self, view: view, status: "stop")
        }
    }
    
    func getImage(imageName: String, folderName: String) async -> UIImage? {
        do {
            let imageRef = Storage.storage().reference().child("/guide/\(folderName)/\(imageName).png")
            let image = try await imageRef.data(maxSize: 1 * 1024 * 1024)
            if let image = UIImage(data: image) {
                return image
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func setUpScrollView(count: Int) {
        let safeAreaTop = self.view.safeAreaInsets.top
        // scrollViewの画面表示サイズを指定
        scrollView = UIScrollView(frame: CGRect(x: 0, y: safeAreaTop, width: self.view.frame.size.width, height: self.view.frame.size.height))
        // scrollViewのサイズを指定（幅は1メニューに表示するViewの幅×ページ数）
        scrollView.contentSize = CGSize(width: Int(self.view.frame.size.width) * count, height: Int(self.view.frame.size.height))
        // scrollViewのデリゲートになる
        scrollView.delegate = self
        // メニュー単位のスクロールを可能にする
        scrollView.isPagingEnabled = true
        // 水平方向のスクロールインジケータを非表示にする
        scrollView.showsHorizontalScrollIndicator = false
        self.view.addSubview(scrollView)
    }
    
    func setUpImageView(type: String) {
        switch type {
        case "administrator":
            for i in 0 ..< administratorImageNameArray.count {
                let image = administratorImageArray[i].imageData
                let safeAreaTop = self.view.safeAreaInsets.top
                let imageView = createImageView(x: self.view.frame.size.width * CGFloat(i), y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - safeAreaTop - 30, image: image)
                imageView.contentMode = .scaleAspectFit
                scrollView.addSubview(imageView)
            }
        case "member":
            for i in 0 ..< memberImageNameArray.count {
                let image = memberImageArray[i].imageData
                let safeAreaTop = self.view.safeAreaInsets.top
                let imageView = createImageView(x: self.view.frame.size.width * CGFloat(i), y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - safeAreaTop - 30, image: image)
                imageView.contentMode = .scaleAspectFit
                scrollView.addSubview(imageView)
            }
        default:
            for i in 0 ..< tipsImageNameArray.count {
                let image = tipsImageArray[i].imageData
                let safeAreaTop = self.view.safeAreaInsets.top
                let imageView = createImageView(x: self.view.frame.size.width * CGFloat(i), y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - safeAreaTop - 30, image: image)
                imageView.contentMode = .scaleAspectFit
                scrollView.addSubview(imageView)
            }
        }
    }
    
    func setUpPageControl(count: Int) {
        // pageControlの表示位置とサイズの設定
        pageControl = UIPageControl(frame: CGRect(x: 0, y: self.view.frame.size.height - 30, width: self.view.frame.size.width, height: 30))
        // pageControlのページ数を設定
        pageControl.numberOfPages = count
        // pageControlのドットの色
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        // pageControlの現在のページのドットの色
        pageControl.currentPageIndicatorTintColor = UIColor.label
        self.view.addSubview(pageControl)
    }
    
    func menu() {
        let Items = [
            UIAction(title: "管理者編", image: UIImage(systemName: "person.circle"), handler: { _ in
                let subviews = self.view.subviews
                for subview in subviews {
                    subview.removeFromSuperview()
                }
                self.storageAdministratorImage()
            }),
            UIAction(title: "メンバー編", image: UIImage(systemName: "person.2.circle"), handler: { _ in
                let subviews = self.view.subviews
                for subview in subviews {
                    subview.removeFromSuperview()
                }
                self.storageMemberImage()
            }),
            UIAction(title: "使えると便利編", image: UIImage(systemName: "lightbulb.circle"), handler: { _ in
            })
        ]
        let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), children: Items)
        menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        menuBarButtonItem.tintColor = .label
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    func createImageView(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, image: UIImage) -> UIImageView {
        let imageView = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
        imageView.image = image
        return imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
}
