//
//  CameraPermissionViewController.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 29/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit

class CameraPermissionViewController: UIViewController {
    
    var disabledTitle:String?
    private var parentVC = ViewController()
    @IBOutlet weak var btn_settingAccess: UIButton!
    @IBOutlet weak var btn_close: UIButton!
    @IBOutlet weak var lbl_description: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.commonInit()
    }
    
    private func commonInit(){
        self.lbl_description.text = "Allow \(Bundle.main.appName ?? "Trioangle") access to your camera and microphone to take record video within the app"
         self.btn_settingAccess.setTitle(self.disabledTitle ??  "Setting", for: .normal)
        
        parentVC = self.parent as! ViewController
        self.btn_close.addTarget(self.parentVC, action: #selector(self.parentVC.dismissView(_:)), for: .touchDown)
    }

    @IBAction func navigationToSetting(_ sender: Any) {
       self.navigationToAppSetting()
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
