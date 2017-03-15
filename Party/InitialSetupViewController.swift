//
//  InitialSetupViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/9/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

extension UIView {
    func addBlur(withAlpha alpha: CGFloat, withStyle style: UIBlurEffectStyle) {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false
        blurView.alpha = alpha
        insertSubview(blurView, at: 0)
    }
    
    func makeBorder() {
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1).cgColor
        layer.cornerRadius = 30
    }
    
    func removeBorder() {
        layer.borderWidth = 0
    }
}

class InitialSetupViewController: UIViewController {
    
    @IBOutlet weak var createPartyButton: setupButton!
    @IBOutlet weak var joinPartyButton: setupButton!
        
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
}

