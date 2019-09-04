//
//  ViewController.swift
//  Camera
//
//  Created by Rizwan on 16/06/17.
//  Copyright © 2017 Rizwan. All rights reserved.
//

import UIKit
import AVFoundation



class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    // @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var lbl_seconds: UILabel!
    @IBOutlet weak var captureButton: KYShutterButton!
    @IBOutlet weak var btn_close: UIButton!
    
    fileprivate var session: AVCaptureSession?
    fileprivate var device: AVCaptureDevice?
    fileprivate var input: AVCaptureDeviceInput?
    fileprivate var output: AVCaptureMetadataOutput?
    fileprivate var prevLayer: AVCaptureVideoPreviewLayer?
    fileprivate var movieOutput = AVCaptureMovieFileOutput()
    fileprivate var counterTime:Timer?
    fileprivate let seconds:Int = 29
    fileprivate var countTime:Int = 0
    @IBOutlet weak var btn_Flash: UIButton!
    @IBOutlet weak var btn_camera: UIButton!
    @IBOutlet weak var view_recordMode: UIView!
    
    weak var interactiveTransition: BubbleInteractiveTransition?
    var watermark = TAVideoWaterMarker()
    
    enum FlashMode{
        case on
        case off
    }
    
    enum Counter{
        case start
        case reset
        case finished
    }
    
    fileprivate var counter: Counter = .start{
        
        didSet{
            
            switch counter {
                
            case .start, .reset:
                countTime = seconds
                self.lbl_seconds.text = "\(countTime)"
            case .finished:
                break
            }
            
        }
        
    }
    
    fileprivate var flashMode: FlashMode = .on
    
    @objc func update() {
        if(countTime > 0) {
            DispatchQueue.main.async {
                self.countTime -= 1
                self.lbl_seconds.text = "\(self.countTime)"
            }
        }else{
            //Stop Video Recording, if reached to zero, user allowed maximum 30 sec
            self.onTapVideoRecord(self.captureButton)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        self.cameraInitialize()
    }

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func microphoneIsEnabled() -> Bool{
        var accessMicrophone:Bool?
        AppPermission.isMicrophoneAccess(completion: {permission in
            if permission {
                accessMicrophone = true
            }else{
                DispatchQueue.main.async {
                    self.blockNoCameraPermission(title: "Microphone Access")
                    accessMicrophone = false
                }
            }
        })
        
        return accessMicrophone ?? false
    }
    
    
    //Mark: initialize
    func cameraInitialize(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        
        counter = .start
        self.view_recordMode.isHidden = true
        
    }
    
    //Mark: App enter to forceground
    @objc func appWillEnterForeground() {
        self.session?.startRunning()
    }
    
    //Mark: App enter to background
    @objc func appDidEnterBackground() {
        //...
        counterTime?.invalidate()
        counter = .reset
        movieOutput.stopRecording()
        self.session?.stopRunning()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        prevLayer?.frame.size = previewView.frame.size
        
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            AppPermission.isCameraAccess(completion: { permission in
                if permission {
                    if self.microphoneIsEnabled(){
                        if self.session == nil {
                            self.createSession()
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        self.blockNoCameraPermission(title: "All Camera Access")
                    }
                }
            })
        }else{
            print("device not found")
        }
        
    }
    
    func setupInputOutput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: device!)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            session?.addInput(captureDeviceInput)
            session?.addInput(audioDeviceInput)
            
            movieOutput = AVCaptureMovieFileOutput()
            //session?.addOutput(movieOutput)
        } catch {
            print(error)
        }
    }
    
    //Mark: Create session
    func createSession() {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error)
        }
        
        if input != nil{
            // session?.addInput(input)
            self.setupInputOutput()
        }
        
        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        prevLayer?.frame.size = previewView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        prevLayer?.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        
        previewView.layer.addSublayer(prevLayer!)
        
        
        //Add File Output
        _ = movieOutput.connection(with: .video)
     /*   if movieOutput.availableVideoCodecTypes.contains(.h264) {
            // Use the H.264 codec to encode the video.
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
        }*/
        
        if self.session?.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) ?? false
        {
            self.session?.sessionPreset = AVCaptureSession.Preset.hd1280x720
        }
 
        else {
            // Handle the failure.
        }
        
        self.session?.addOutput(self.movieOutput)
        session?.startRunning()
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera, ], mediaType: .video, position: position)
        
        if let device = deviceDiscoverySession.devices.first {
            return device
        }
        return nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.prevLayer?.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self.prevLayer?.frame.size = self.previewView.frame.size
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    @IBAction func switchCameraSide(sender: AnyObject) {
        if let sess = session {
            let currentCameraInput: AVCaptureInput = sess.inputs[0]
            sess.removeInput(currentCameraInput)
            var newCamera: AVCaptureDevice
            if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
                newCamera = self.cameraWithPosition(position: .front)!
                self.btn_Flash.isHidden = true
            } else {
                newCamera = self.cameraWithPosition(position: .back)!
                self.btn_Flash.isHidden = false
            }
            
            var newVideoInput: AVCaptureDeviceInput?
            do{
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            }
            catch{
                print(error)
            }
            
            if let inputs = session?.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    session?.removeInput(input)
                }
            }
            
            if let newVideoInput = newVideoInput{
                session?.addInput(newVideoInput)
            }
        }
    }
    
    //Mark: Video recording and save to app directory
    func recordVideoAction() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            self.session?.stopRunning()
        } else {
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mp4")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }
    
    //MARK: Record Button
    @IBAction func onTapVideoRecord(_ sender: KYShutterButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
        switch sender.buttonState {
        case .normal:
            counterTime =  Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(update), userInfo: nil, repeats: true)
            sender.buttonState = .recording
            self.recordVideoAction()
            self.recordModeActivated(isEnabled: true)
            
        case .recording:
            counterTime?.invalidate()
            self.recordVideoAction()
            sender.buttonState = .normal
            self.recordModeActivated(isEnabled: false)
        }
        }
        
    }
    
    //video start to recording all other buttons are hidden
    fileprivate func recordModeActivated(isEnabled:Bool){
        self.btn_close.isHidden = isEnabled
        self.view_recordMode.isHidden = !isEnabled
        self.btn_camera.isHidden = isEnabled
        self.btn_Flash.isHidden = isEnabled
        
    }
    
    
    @IBAction func turnFlashToggleAction(_ sender: Any) {
        
        switch flashMode {
        case .on:
            self.toggleTorch(on: true)
        case .off:
            self.toggleTorch(on: false)
        }
        
        flashMode = flashMode == .on ? .off: .on
    }
    
    
    //Flash on Off
    //MARK: FLASH UITLITY METHODS
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func dismissView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
         interactiveTransition?.finish()
    }
    
    //Mark: Video convert to landscape mode
    func mixVideoWithText(outputURL: URL) {
        let videoAsset = AVURLAsset(url: outputURL, options: nil)
        let mixComposition = AVMutableComposition()
        
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let clipVideoTrack = videoAsset.tracks(withMediaType: .video)[0]
        let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipAudioTrack = videoAsset.tracks(withMediaType: .audio)[0]
        //If you need audio as well add the Asset Track for audio here
        
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: clipVideoTrack, at: .zero)
        } catch {
        }
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: clipAudioTrack, at: .zero)
        } catch {
        }
        
        compositionVideoTrack?.preferredTransform = videoAsset.tracks(withMediaType: .video)[0].preferredTransform
        let sizeOfVideo = clipVideoTrack.naturalSize
        
        //TextLayer defines the text they want to add in Video
        //Text of watermark
        let textOfvideo = CATextLayer()
        textOfvideo.string = "text" //text is shows the text that you want add in video.
        textOfvideo.font = UIFont(name: "Airal", size: 12)
        textOfvideo.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height / 6)
        textOfvideo.alignmentMode = .center
        textOfvideo.foregroundColor = UIColor.red.cgColor
        
        //Image of watermark
        let myImage = UIImage(named: "Logo")
        let layerCa = CALayer()
        layerCa.contents = myImage?.cgImage
        layerCa.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        layerCa.opacity = 1.0
        
        let optionalLayer = CALayer()
        optionalLayer.addSublayer(textOfvideo)
        optionalLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        optionalLayer.masksToBounds = true
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(optionalLayer)
        parentLayer.addSublayer(layerCa)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = sizeOfVideo
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: mixComposition.duration)
        let videoTrack = mixComposition.tracks(withMediaType: .video)[0]
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let destinationPath = documentsDirectory + ("/utput_\(dateFormatter.string(from: Date())).mov")
        
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.videoComposition = videoComposition
        
        exportSession?.outputURL = URL(fileURLWithPath: destinationPath)
        exportSession?.outputFileType = .mov
        exportSession?.exportAsynchronously(completionHandler: {
            switch exportSession?.status {
            case .completed?:
                print("Export OK")
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(destinationPath) {
                    UISaveVideoAtPathToSavedPhotosAlbum(destinationPath, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)), nil)
                }
            case .failed?:
                if let error = exportSession?.error {
                    print("AVAssetExportSessionStatusFailed: \(error)")
                }
            case .cancelled?:
                print("Export Cancelled")
            default:
                break
            }
        })
    }
    
    @objc func video(_ videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if error != nil {
            if let error = error {
                print("Finished saving video with error: \(error)")
            }
        }
    }
    
}//End Loop

extension ViewController : AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            
            self.view.activityStartAnimating(activityColor: UIColor.white, backgroundColor: UIColor.black.withAlphaComponent(0.5))
            
            print("Size of video \(self.sizePerMB(url: outputFileURL))")
       /*   let asset = AVAsset(url: outputFileURL)
           watermark.watermark(video: asset, imageName:"Logo", watermarkText: "", saveToLibrary: true, watermarkPosition: .Default){ (status, exporter, outputURL) in
            DispatchQueue.main.async {
                
                self.view.activityStopAnimating()
                UISaveVideoAtPathToSavedPhotosAlbum(exporter?.outputURL?.path ?? "" , nil, nil, nil)
                let preView = PreviewVideoViewController(nibName: "PreviewVideoViewController", bundle: nil)
                preView.videoPath = exporter?.outputURL
                preView.deletage = self
                self.present(preView, animated: false, completion: nil)
            }
            
            }
 
            
           // self.mixVideoWithText(outputURL: outputFileURL)
        */
 
            
           let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
            
            compressVideo(inputURL: outputFileURL, outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    return
                }
                
                switch session.status {
                case .unknown:
                    print("unkown")
                    break
                case .waiting:
                    print("waiting")
                    break
                case .exporting:
                    print("exporting")
                    break
                case .completed:
                    print("completed")
                    DispatchQueue.main.async {
    
                    self.view.activityStopAnimating()
                    UISaveVideoAtPathToSavedPhotosAlbum(exportSession?.outputURL?.path ?? "" , nil, nil, nil)
                    let preView = PreviewVideoViewController(nibName: "PreviewVideoViewController", bundle: nil)
                    preView.videoPath = exportSession?.outputURL
                    preView.deletage = self
                    self.present(preView, animated: false, completion: nil)
                    }
                    guard let compressedData = NSData(contentsOf: compressedURL) else {
                        return
                    }
                    
                    print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
                case .failed:
                    print("Failed")
                    break
                case .cancelled:
                    print("cancelled")
                    break
                }
            }
            

            // UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path , nil, nil, nil)
        
        }
        // print("error save \(String(describing: error))  === success \(outputFileURL) == ")
    }
    
    private func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset640x480) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    func sizePerMB(url: URL?) -> Double {
        guard let filePath = url?.path else {
            return 0.0
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / 1000000.0
            }
        } catch {
            print("Error: \(error)")
        }
        return 0.0
    }
    
}

extension ViewController : CameraViewDelegate{
    func retake() {
        counter = .reset
        self.captureButton.buttonState = .normal
        self.recordModeActivated(isEnabled: false)
        self.session?.startRunning()
    }
    
}

