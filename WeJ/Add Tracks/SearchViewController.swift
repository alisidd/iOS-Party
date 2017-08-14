//
//  SearchViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift
import NVActivityIndicatorView

class SearchViewController: UIViewController, UITextFieldDelegate {
    
    private weak var delegate: AddTracksTabBarController!
    
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var badge: BadgeSwift!
    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var trackTableView: UITableView!
    
    // MARK: - General Variables
    var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.trackTableView.reloadData()
                self.activityIndicator.stopAnimating()
                self.fetchArtworkForRestOfTracks()
            }
        }
    }
    private var fetcher: Fetcher!
    private var activityIndicator: NVActivityIndicatorView!
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 320, height: 70))
    
    func setBadge(to count: Int) {
        guard badge != nil else { return }
        badge.isHidden = count == 0
        badge.text = String(count)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVariables()
        setDelegates()
        initializeActivityIndicator()
        adjustViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeBadge()
    }
    
    private func initializeBadge() {
        let controller = tabBarController! as! AddTracksTabBarController
        setBadge(to: controller.tracksSelected.count + controller.libraryTracksSelected.count)
    }
    
    // MARK: - Functions
    
    private func initializeVariables() {
        delegate = tabBarController as? AddTracksTabBarController
    }
    
    private func setDelegates() {
        searchTracksField.delegate = self
        trackTableView.delegate    = delegate
        trackTableView.dataSource  = delegate
    }
    
    private func initializeActivityIndicator() {
        let rect = CGRect(x: view.center.x - 20, y: view.center.x - 20, width: 40, height: 40)
        activityIndicator = NVActivityIndicatorView(frame: rect, type: .ballClipRotateMultiple, color: .white, padding: 0)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    private func adjustViews() {
        navigationItem.hidesBackButton = true
        
        let placeholderText = "Search " + Party.musicService.toString()
        searchTracksField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        
        trackTableView.backgroundColor = .clear
        trackTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchTracksField.resignFirstResponder()
        if !searchTracksField.text!.isEmpty {
            trackTableView.isHidden = true
            fetchResults(forTerm: searchSongsField.text!)
        }
        return true
    }
    
    private func fetchResults(forTerm term: String) {
        fetcher = Party.musicService == .spotify ? SpotifyFetcher() : AppleMusicFetcher()
        activityIndicator.startAnimating()
        
        fetcher.searchCatalog(forTerm: term) { [weak self] in
            self?.populateTracksList()
            self?.showTableView()
            self?.scrollUp()
        }
    }
    
    private func populateTracksList() {
        tracksList = fetcher.tracksList
        DispatchQueue.main.async {
            if self.tracksList.isEmpty {
                self.displayNoTracksLabel(withText: "No Tracks Found")
            } else {
                self.removeNoTracksFoundLabel()
            }
        }
    }
    
    private func showTableView() {
        DispatchQueue.main.async {
            self.trackTableView.isHidden = false
        }
    }
    
    private func scrollUp() {
        DispatchQueue.main.async {
            if !self.tracksList.isEmpty {
                self.trackTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    private func displayNoTracksLabel(withText text: String) {
        customizeLabel(withText: text)
        view.addSubview(noTracksFoundLabel)
    }
    
    private func customizeLabel(withText text: String) {
        noTracksFoundLabel.text = text
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
        noTracksFoundLabel.lineBreakMode = .byWordWrapping
        noTracksFoundLabel.numberOfLines = 0
    }
    
    private func removeNoTracksFoundLabel() {
        noTracksFoundLabel.removeFromSuperview()
    }
    
    private func fetchArtworkForRestOfTracks() {
        let tracksCaptured = tracksList
        for track in tracksList where tracksList == tracksCaptured && track.lowResArtwork == nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                    track.lowResArtwork = image
                    self?.trackTableView.reloadData()
                }
            }
        }
    }

}
