//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

protocol modifyTracksQueue: class {
    func addToQueue(track: Track)
    func removeFromQueue(track: Track)
}

class AddSongViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, modifyTracksQueue {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var trackTableView: UITableView!
    
    var party = Party()
    private var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.trackTableView.reloadData()
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
            }
        }
    }
    private var tracksQueue = [Track]()
    private let APIManager = RestApiManager()
    private var indicator = UIActivityIndicatorView()
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
    weak var delegate: updateTracksQueue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        customizeNavigationBar()
        setDelegates()
        initializeActivityIndicator()
        adjustTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customizeTextField()
    }
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    func customizeNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(AddSongViewController.goBack))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    func setDelegates() {
        self.searchTracksField.delegate = self
        self.trackTableView.delegate   = self
        self.trackTableView.dataSource = self
    }
    
    func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    func adjustTableView() {
        trackTableView.backgroundColor = .clear
        trackTableView.separatorColor  = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        trackTableView.tableFooterView = UIView()
        trackTableView.allowsSelection = false
    }
    
    func customizeTextField() {
        searchTracksField.attributedPlaceholder = NSAttributedString(string: "Search Tracks", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        searchTracksField.layer.borderWidth = 1.5
        
        searchTracksField.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchSongsField.resignFirstResponder()
        if !(searchSongsField.text?.isEmpty)! {
            fetchResults(forQuery: searchSongsField.text!)
        }
        return true
    }
    
    func fetchResults(forQuery query: String) {
        indicator.startAnimating()
        if party.musicService == .appleMusic {
            APIManager.makeHTTPRequestToApple(withString: query)
        } else {
            APIManager.makeHTTPRequestToSpotify(withString: query)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroup.wait()
            self.tracksList = self.APIManager.tracksList
            if self.tracksList.count == 0 {
                DispatchQueue.main.async {
                    self.displayNoTracksFoundLabel()
                }
            } else {
                DispatchQueue.main.async {
                    self.removeNoTracksFoundLabel()
                }
            }
        }
    }
    
    func displayNoTracksFoundLabel() {
        noTracksFoundLabel.text = "No Tracks Found"
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = self.view.center
        self.view.addSubview(noTracksFoundLabel)
    }
    
    func removeNoTracksFoundLabel() {
        self.noTracksFoundLabel.removeFromSuperview()
    }
    
    func addToQueue(track: Track) {
        self.delegate?.addToQueue(track: track)
    }
    
    func removeFromQueue(track: Track) {
        self.delegate?.removeFromQueue(track: track)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    func goBack() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksList.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackTableViewCell
        
        
        cell.track = tracksList[indexPath.row]
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist

        if let unwrappedArtwork = tracksList[indexPath.row].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        }
        cell.delegate = self
        
        if (self.delegate?.tracksQueue(hasTrack: tracksList[indexPath.row]))! {
            cell.addButton.setTitle("✓", for: .normal)
        } else {
            cell.addButton.setTitle("+", for: .normal)
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    

}
