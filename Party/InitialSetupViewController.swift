//
//  InitialSetupViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/9/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

extension UIView {
    func addBlur(withAlpha alpha: CGFloat) {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false
        blurView.alpha = alpha
        insertSubview(blurView, at: 0)
    }
    
    func makeBorder() {
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 1).cgColor
        layer.cornerRadius = 10
        addBlur(withAlpha: 0.4)
    }
}

class InitialSetupViewController: UIViewController {
    
    @IBOutlet weak var createPartyButton: setupButton!
    @IBOutlet weak var joinPartyButton: setupButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImageView.addBlur(withAlpha: 1)
    }
    
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

