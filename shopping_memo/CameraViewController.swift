//
//  CameraViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/11/08.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var takePhotoButton: UIButton!
    @IBOutlet var flashModeButton: UIButton!
    @IBOutlet var changeCameraReTakeButton: UIButton!
    @IBOutlet var previewLayerBackgroundView: UIView!
    
    var userId: String!
    var roomIdString: String!
    var listIdString: String!
    var memoIdString: String!
    var shoppingMemoName: String!
    var imageRef: StorageReference!
    var ref: DatabaseReference!
    let df = DateFormatter()
    let settings = AVCapturePhotoSettings()
    let userDefaults: UserDefaults = UserDefaults.standard
    let storage = Storage.storage()
    var connect = false
    var flashMode = 2
    var uploadBarButtonItem: UIBarButtonItem!
    var cancelBarButtonItem: UIBarButtonItem!
    
    // デバイスからの入力と出力を管理するオブジェクトの作成
    var captureSession = AVCaptureSession()
    // カメラデバイスのイン・アウトの管理
    var isBack = true
    // 現在使用しているカメラデバイスの管理オブジェクトの作成
    var currentDevice: AVCaptureDevice?
    // キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput : AVCapturePhotoOutput?
    // プレビュー表示用のレイヤ
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpData()
        menu()
        setupPreviewLayer()
        startCamera(isBack: isBack)
        obserbeRealtimeDatabase()
    }
    
    override func viewDidLayoutSubviews() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let viewHeight = screenWidth * 4 / 3
        let y = (screenHeight - viewHeight) / 2
        let safeAreaTop = self.view.safeAreaInsets.top
        if y > 100 {
            self.previewLayerBackgroundView.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
            self.imageView.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
        } else {
            self.previewLayerBackgroundView.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
            self.imageView.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
        }
        self.cameraPreviewLayer?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: viewHeight)
    }
    
    func setUpUI() {
        title = "画像を撮影"
        imageView.isHidden = true
        takePhotoButton.layer.cornerRadius = 35.0
        takePhotoButton.setImage(UIImage(systemName: "camera.shutter.button"), for: .normal)
        flashModeButton.layer.cornerRadius = 25.0
        setUpChangeCameraReTakeButton()
    }
    
    func setUpChangeCameraReTakeButton() {
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let windowHeight = (window?.screen.bounds.height)!
        let windowWidth = (window?.screen.bounds.width)!
        if imageView.isHidden {
            changeCameraReTakeButton.frame = CGRect(x: Int(windowWidth) - 100, y: Int(windowHeight) - 90, width: 50, height: 50)
            changeCameraReTakeButton.layer.cornerRadius = 25.0
            changeCameraReTakeButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        } else {
            changeCameraReTakeButton.frame = CGRect(x: Int(windowWidth) - 100, y: Int(windowHeight) - 100, width: 70, height: 70)
            changeCameraReTakeButton.layer.cornerRadius = 35.0
            changeCameraReTakeButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        }
    }
    
    func setUpData() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    func startCamera(isBack: Bool) {
        setupCaptureSession()
        setupDevice(isBack: isBack)
        setupInputOutput()
        captureSession.startRunning()
    }
    
    func menu() {
        cancelBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.up"), style: .done, target: self, action: #selector(uploadBarButtonItem(_:)))
        cancelBarButtonItem.tintColor = .label
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        uploadBarButtonItem = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancelBarButtonItem(_:)))
        uploadBarButtonItem.tintColor = .tintColor
        navigationItem.leftBarButtonItem = uploadBarButtonItem
        if #available(iOS 16.0, *) { uploadBarButtonItem.isHidden = true }
    }
    
    func obserbeRealtimeDatabase() {
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childRemoved, with: { [self] snapshot in
            let memoId = snapshot.key
            if memoId == memoIdString {
                let alert: UIAlertController = UIAlertController(title: "閲覧中のデータが削除されました", message: "ホームに戻ります。詳しくは削除したメンバーにお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    self.userDefaults.set(true, forKey: "isBack")
                    self.dismiss(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childRemoved, with: { snapshot in
            let userId = snapshot.key
            if userId == self.userId {
                let alert: UIAlertController = UIAlertController(title: "ルームを追放されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    self.userDefaults.set(4, forKey: "back")
                    self.dismiss(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func changeFlashMode() {
        switch flashMode {
        case 0:
            flashMode = 1
            flashModeButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            flashModeButton.tintColor = .yellow
        case 1:
            flashMode = 2
            flashModeButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            flashModeButton.tintColor = .label
        default:
            flashMode = 0
            flashModeButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            flashModeButton.tintColor = .label
        }
    }
    
    // シャッターボタンが押された時のアクション
    @IBAction func takePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        // カメラの手ぶれ補正
//        settings.isAutoStillImageStabilizationEnabled = true
        switch flashMode {
        case 0:
            settings.flashMode = .off
        case 1:
            settings.flashMode = .on
        default:
            settings.flashMode = .auto
        }
        // 撮影された画像をdelegateメソッドで処理
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    @IBAction func changeCameraReTake() {
        if imageView.isHidden {
            reverseCameraPosition()
        } else {
            imageView.isHidden = true
            setUpChangeCameraReTakeButton()
            if #available(iOS 16.0, *) { uploadBarButtonItem.isHidden = true }
            takePhotoButton.isHidden = false
            previewLayerBackgroundView.isHidden = false
            flashModeButton.isHidden = false
        }
    }
    
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            // Data型をUIImageオブジェクトに変換
            let uiImage = UIImage(data: imageData)
            takePhotoButton.isHidden = true
            previewLayerBackgroundView.isHidden = true
            flashModeButton.isHidden = true
            imageView.isHidden = false
            setUpChangeCameraReTakeButton()
            if #available(iOS 16.0, *) { uploadBarButtonItem.isHidden = false }
            imageView.image = uiImage
        }
    }
    
    // カメラの画質の設定
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    // デバイスの設定
    func setupDevice(isBack: Bool) {
        // カメラデバイスのプロパティ設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        // プロパティの条件を満たしたカメラデバイスの取得
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if isBack && device.position == AVCaptureDevice.Position.back {
                currentDevice = device
            } else if !isBack && device.position == AVCaptureDevice.Position.front {
                currentDevice = device
            }
        }
    }
    // プロパティの条件を満たしたカメラデバイスの取得
//        let devices = deviceDiscoverySession.devices
//        for device in devices {
//            if isBack && device.position == AVCaptureDevice.Position.back {
//                currentDevice = device
//            } else if !isBack && device.position == AVCaptureDevice.Position.front {
//                currentDevice = device
//            }
//        }
    
    // 入出力データの設定
    func setupInputOutput() {
        do {
            // 指定したデバイスを使用するために入力を初期化
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            // 指定した入力をセッションに追加
            captureSession.addInput(captureDeviceInput)
            // 出力データを受け取るオブジェクトの作成
            photoOutput = AVCapturePhotoOutput()
            // 出力ファイルのフォーマットを指定
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }
    
    // カメラのプレビューを表示するレイヤの設定
    func setupPreviewLayer() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let viewHeight = screenWidth * 4 / 3
        let y = (screenHeight - viewHeight) / 2
        let safeAreaTop = self.view.safeAreaInsets.top
        let settings = AVCapturePhotoSettings()
        // フラッシュの設定
        settings.flashMode = .auto
        flashMode = 2
        flashModeButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashModeButton.tintColor = .label
        // 指定したAVCaptureSessionでプレビューレイヤを初期化
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // プレビューレイヤの表示の向きを設定
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.previewLayerBackgroundView.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
    func reverseCameraPosition() {
        captureSession.stopRunning()
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }
        // prepare new capture session & preview
        isBack = !isBack
        let newVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let viewHeight = screenWidth * 4 / 3
        let y = (screenHeight - viewHeight) / 2
        let safeAreaTop = self.view.safeAreaInsets.top
        if y > 100 {
            newVideoLayer.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
        } else {
            newVideoLayer.frame = CGRect(x: 0, y: safeAreaTop, width: screenWidth, height: viewHeight)
        }
        newVideoLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: viewHeight)
        newVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.startCamera(isBack: isBack)
        // horizontal flip
        if isBack {
            UIView.transition(with: self.previewLayerBackgroundView, duration: 0.3, options: [.transitionFlipFromRight], animations: nil, completion: { _ in
                // replace camera preview with new one
                self.previewLayerBackgroundView.layer.replaceSublayer(self.cameraPreviewLayer!, with: newVideoLayer)
                self.cameraPreviewLayer = newVideoLayer
            })
        } else {
            UIView.transition(with: self.previewLayerBackgroundView, duration: 0.3, options: [.transitionFlipFromLeft], animations: nil, completion: { _ in
                // replace camera preview with new one
                self.previewLayerBackgroundView.layer.replaceSublayer(self.cameraPreviewLayer!, with: newVideoLayer)
                self.cameraPreviewLayer = newVideoLayer
            })
        }
    }
    
    @objc func uploadBarButtonItem(_ sender: UIBarButtonItem) {
        if connect {
            guard let image = imageView.image else { return }
            if image == UIImage(systemName: "photo") {
                let alert: UIAlertController = UIAlertController(title: "アップロードできません", message: "アップロードする画像を撮影してください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                GeneralPurpose.AIV(VC: self, view: view, status: "start")
                guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }
                guard let uid = userId else { return }
                guard let roomId = roomIdString else { return }
                guard let listId = listIdString else { return }
                guard let memoId = memoIdString else { return }
                let imageRef = Storage.storage().reference().child("/\(uid)/\(roomId)/\(listId)/\(memoId).jpg")
                imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print(error)
                    } else {
                        imageRef.downloadURL { (url, error) in
                            guard let downloadURL = url else { return }
                            let imageUrl = downloadURL.absoluteString
                            self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["imageUrl": imageUrl])
                            GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                            self.dismiss(animated: true)
                        }
                    }
                }
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    @objc func cancelBarButtonItem(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
//
