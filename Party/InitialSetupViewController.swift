//
//  InitialSetupViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/9/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class InitialSetupViewController: UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
    }
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(name: "Helvetica", size: 20)!]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

