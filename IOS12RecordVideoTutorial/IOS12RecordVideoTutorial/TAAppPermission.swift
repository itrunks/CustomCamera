//
//  TAAppPermission.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 29/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import UserNotifications
import AVFoundation

struct AppPermission {
    
    static func isCameraAccess(completion: @escaping (Bool) -> ()){
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Denied, request permission from settings")
            completion(false)
        case .restricted:
            print("Restricted, device owner must approve")
            completion(false)
        case .authorized:
            print("Authorized, proceed")
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                    completion(true)
                } else {
                    print("Permission denied")
                    completion(false)
                }
            }
        @unknown default:
            print ("fatal error")
            completion(false)
        }
    }
    
    static func isMicrophoneAccess(completion: @escaping (Bool) -> ()){
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            print("Permission granted")
             completion(true)
        case AVAudioSessionRecordPermission.denied:
            print("Pemission denied")
             completion(false)
        case AVAudioSessionRecordPermission.undetermined:
            print("Request permission here")
            AVCaptureDevice.requestAccess(for: .audio) { success in
                if success {
                    print("Permission granted, proceed")
                    completion(true)
                } else {
                    print("Permission denied")
                    completion(false)
                }
            }

        @unknown default:
            print ("fatal error")
            completion(false)
        }
    }
    
}
