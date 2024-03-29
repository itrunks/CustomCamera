//
//  Watermark.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 28/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import Photos
import SpriteKit

enum TAWatermarkPosition {
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
    case Default
}

class TAVideoWaterMarker: NSObject {
    
    
    func watermark(video videoAsset:AVAsset, watermarkText text : String, saveToLibrary flag : Bool, watermarkPosition position : TAWatermarkPosition, completion : ((_ status : AVAssetExportSession.Status?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        self.watermark(video: videoAsset, watermarkText: text, imageName: nil, saveToLibrary: flag, watermarkPosition: position) { (status, session, outputURL) -> () in
            completion!(status, session, outputURL)
        }
    }
    
    func watermark(video videoAsset:AVAsset, imageName name : String, watermarkText text : String , saveToLibrary flag : Bool, watermarkPosition position : TAWatermarkPosition, completion : ((_ status : AVAssetExportSession.Status?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        self.watermark(video: videoAsset, watermarkText: text, imageName: name, saveToLibrary: flag, watermarkPosition: position) { (status, session, outputURL) -> () in
            completion!(status, session, outputURL)
        }
    }
    
    private func watermark(video videoAsset:AVAsset, watermarkText text : String!, imageName name : String!, saveToLibrary flag : Bool, watermarkPosition position : TAWatermarkPosition, completion : ((_ status : AVAssetExportSession.Status?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            let mixComposition = AVMutableComposition()
            
            let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            
            if videoAsset.tracks(withMediaType: AVMediaType.video).count == 0
                
            {
                completion!(nil, nil, nil)
                return
            }
            
            let clipVideoTrack =  videoAsset.tracks(withMediaType: AVMediaType.video)[0]
            
            self.addAudioTrack(composition: mixComposition, videoAsset: videoAsset as! AVURLAsset)
            
            
            do {
                try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: clipVideoTrack, at: CMTime.zero)
            }
            catch {
                print(error.localizedDescription)
            }
            
            let videoSize = clipVideoTrack.naturalSize //CGSize(width: 375, height: 300)
            
            print("videoSize--\(videoSize)")
            let parentLayer = CALayer()
            
            let videoLayer = CALayer()
            
            parentLayer.frame = CGRect(x: 0, y: 0, width:videoSize.width , height: videoSize.height)
            videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            //videoLayer.backgroundColor = UIColor.red.cgColor
            parentLayer.addSublayer(videoLayer)
            
            if name != nil {
                let watermarkImage = UIImage(named: name)
                let imageLayer = CALayer()
                imageLayer.backgroundColor = UIColor.purple.cgColor
                imageLayer.contents = watermarkImage?.cgImage
                
                var xPosition : CGFloat = 0.0
                var yPosition : CGFloat = 0.0
                let imageSize : CGFloat = 57.0
                
                switch (position) {
                case .TopLeft:
                    xPosition = 0
                    yPosition = 0
                    break
                case .TopRight:
                    xPosition = videoSize.width - imageSize - 30
                    yPosition = 30
                    break
                case .BottomLeft:
                    xPosition = 0
                    yPosition = videoSize.height - imageSize
                    break
                case .BottomRight, .Default:
                    xPosition = videoSize.width - imageSize
                    yPosition = videoSize.height - imageSize
                    break
                }
                
                
                imageLayer.frame = CGRect(x: xPosition, y: yPosition, width: imageSize, height: imageSize)
                imageLayer.opacity = 0.65
                parentLayer.addSublayer(imageLayer)
                
                
                
                if text != nil {
                    let titleLayer = CATextLayer()
                    titleLayer.backgroundColor = UIColor.clear.cgColor
                    titleLayer.string = text
                    titleLayer.font = "Helvetica" as CFTypeRef
                    titleLayer.fontSize = 20
                    titleLayer.alignmentMode = CATextLayerAlignmentMode.right
                    titleLayer.frame = CGRect(x: 0, y: 10, width: 50, height: 57)
                    titleLayer.foregroundColor = UIColor.red.cgColor
                    parentLayer.addSublayer(titleLayer)
                }
            }
            
            let videoComp = AVMutableVideoComposition()
            videoComp.renderSize = videoSize
            videoComp.frameDuration = CMTimeMake(value: 1, timescale: 30)//(value: 1, timescale: 1)
            videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: mixComposition.duration)
            instruction.backgroundColor = UIColor.gray.cgColor
            _ = mixComposition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
            
            let layerInstruction = self.videoCompositionInstructionForTrack(track: compositionVideoTrack!, asset: videoAsset)
            
            instruction.layerInstructions = [layerInstruction]
            videoComp.instructions = [instruction]
            
            
            
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let destinationPath = documentsDirectory + ("/utput_\(dateFormatter.string(from: Date())).mov")
            
            
            let url = URL(fileURLWithPath:destinationPath)
            
            
       
            AVAssetExportSession.determineCompatibility(ofExportPreset: AVAssetExportPreset640x480, with: videoAsset, outputFileType: AVFileType.mov, completionHandler: {
                (isCompatible) in
                if !isCompatible {
                    print("Format not compatible.")
                    return
                }else{
                    print("compatible")
                }
            })

            
            let exporter:AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetLowQuality)!
            exporter.videoComposition = videoComp
            exporter.outputURL =  url
            exporter.outputFileType = AVFileType.mov
            exporter.shouldOptimizeForNetworkUse = true
            //exporter.fileLengthLimit = 1048576 * 10 //10 MB
            exporter.exportAsynchronously() {
                switch exporter.status {
                case  .failed:
                    print("failedd \(exporter.error ?? " ff" as! Error)")
                    //completion
                    break
                case .cancelled:
                    print("cancelledd \(exporter.error ?? " cc" as! Error)")
                    //completion(url: nil)
                    break
                default:
                    print("complete")
                    completion!(exporter.status, exporter, exporter.outputURL)
                }
            }
            
        }
    }
    
   private func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetLowQuality) else {
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
    
    private func addAudioTrack(composition: AVMutableComposition, videoAsset: AVURLAsset) {
        let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        let audioTracks = videoAsset.tracks(withMediaType: AVMediaType.audio)
        for audioTrack in audioTracks {
            try! compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
        }
    }
    
    
    private func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / 375
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),
                                     at: CMTime.zero)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: 0))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = UIScreen.main.bounds
                let yFix = 375 + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: CGFloat(yFix))
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: CMTime.zero)
            
        }
        
        return instruction
    }
}


