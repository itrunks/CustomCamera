//
//  HomeViewController.swift
//  IOS12RecordVideoTutorial
//
//  Created by trioangle on 29/08/19.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit


class HomeViewController: UIViewController, UIViewControllerTransitioningDelegate  {
    @IBOutlet weak var transitionButton: UIButton!
    
    let transition = BubbleTransition()
    let interactiveTransition = BubbleInteractiveTransition()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }

    @IBAction func navigationToNext(_ sender: UIButton) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller:ViewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .custom
        controller.interactiveTransition = interactiveTransition
        interactiveTransition.attach(to: controller)
        self.present(controller, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ViewController {
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
            controller.interactiveTransition = interactiveTransition
            interactiveTransition.attach(to: controller)
        }
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = transitionButton.center
        transition.bubbleColor = transitionButton.backgroundColor ?? .black
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = transitionButton.center
        transition.bubbleColor = transitionButton.backgroundColor ?? .black
        return transition
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }

}
