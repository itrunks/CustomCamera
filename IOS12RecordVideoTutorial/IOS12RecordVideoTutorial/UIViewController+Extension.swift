//
//  UIViewController+Extension.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 29/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit
import Foundation

extension UIViewController:UIPopoverPresentationControllerDelegate {
    

    
    func showAlert(withTitle title: String?, message: String?,delay:Double? = nil,completion: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .cancel) { (isAction) in
            
            guard let completion = completion else { return }
            
            completion()
        }
        
        alert.addAction(action)
        
        if let del = delay {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + del)
            {
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func showPermissionAlert(withTitle title: String?, message: String?,delay:Double? = nil,completion: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Cancel", style: .cancel) { (isAction) in
            
            guard let completion = completion else { return }
            
            completion()
        }
        
        let actionSetting = UIAlertAction(title: "Settings", style: .default) { (isAction) in
            
            self.navigationToAppSetting()
            
        }
        
        alert.addAction(action)
        alert.addAction(actionSetting)
        
        if let del = delay {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + del)
            {
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
     func navigationToAppSetting()
    {
        guard let bundleId = Bundle.main.bundleIdentifier, let settingsUrl = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION\(bundleId)")
            else
        {
            print("Unable to open the app settings")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl)
        {
            UIApplication.shared.open(settingsUrl, options: [:]) { (completed) in
                if completed
                {
                    print("Setting opened")
                }
            }
        }
    }
    
    
    
    func confirmationAlert(withTitle title: String?, message: String?,okBtnName:String? = nil,cancelBtnName:String? = nil,okCompletion: (() -> Void)? = nil,cancelCompletion: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: okBtnName ?? "OK" , style: .default) { (isAction) in
            
            guard let completion = okCompletion else { return }
            
            completion()
        }
        
        let cancelAction = UIAlertAction(title: cancelBtnName ?? "Cancel", style: .cancel) { (isCancelAction) in
            
            guard let completion = cancelCompletion else { return }
            
            completion()
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func confirmationAlert(withTitle title: String?, message: String?,okBtnName:String? = nil,okCompletion: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: okBtnName ?? "OK", style: .default) { (isAction) in
            
            guard let completion = okCompletion else { return }
            
            completion()
        }
        
        
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension UIViewController {
    //Mark: Block camera if app hasn't camera or microphone permission
    func blockNoCameraPermission(title: String){
        let lockScreen = CameraPermissionViewController(nibName: "CameraPermissionViewController", bundle: nil)
        lockScreen.disabledTitle = title
        self.addChild(lockScreen)
        lockScreen.view.frame = self.view.frame
        self.view.addSubview(lockScreen.view)
    }
    
}

