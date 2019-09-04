//
//  UIView+Extension.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 29/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    func activityStartAnimating(activityColor: UIColor, backgroundColor: UIColor) {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.tag = 475647
        
        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.color = activityColor
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            backgroundView.addSubview(activityIndicator)
            
            self.addSubview(backgroundView)
        }
    }
    
    func activityStopAnimating() {
        if let background = viewWithTag(475647){
            DispatchQueue.main.async {
                background.removeFromSuperview()
            }
        }
        self.isUserInteractionEnabled = true
    }
    
}

extension Bundle {
    var appName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}
