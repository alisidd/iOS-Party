//
//  PlaylistSubcategorySelectionViewController.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/11/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift
import NVActivityIndicatorView
import MediaPlayer

class PlaylistSubcategorySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badge: BadgeSwift!
    
    @IBOutlet weak var optionsTable: UITableView!
    
    var musicService: MusicService!
    
    var activityIndicator: NVActivityIndicatorView!
    var playlistType: PlaylistType!
    
    var fetcher: Fetcher!
    var optionsDict = [String: [Option]]()
    
    var orderedOptionsDictKeys: [String] {
        return optionsDict.keys.sorted()
    }
    
    func setBadge(to count: Int) {
        badge.isHidden = count == 0
        badge.text = String(count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustViews()
        customizeTableView()
        initializeVariables()
        
        setDelegates()
        setOptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeBadge()
    }
    
    private func adjustViews() {
        switch playlistType {
        case .some(.albums): titleLabel.text = "Albums"
        case .some(.artists): titleLabel.text = "Artists"
        case .some(.playlists): titleLabel.text = "Playlists"
        default: break
        }
    }
    
    private func customizeTableView() {
        edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        
        optionsTable.sectionIndexColor = .gray
        optionsTable.sectionIndexBackgroundColor = AppConstants.black
    }
    
    private func initializeVariables() {
        fetcher = (musicService == .spotify) ? SpotifyFetcher() : AppleMusicFetcher()
        
        let rect = CGRect(x: view.center.x - 20, y: view.center.x - 20, width: 40, height: 40)
        activityIndicator = NVActivityIndicatorView(frame: rect, type: .ballClipRotateMultiple, color: .white, padding: 0)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
    }
    
    private func setDelegates() {
        optionsTable.delegate = self
        optionsTable.dataSource = self
    }
    
    private func setOptions() {
        let completionHandler: ([String: [Option]]) -> (Void) = { [weak self] (optionsDict) in
            DispatchQueue.main.async {
                self?.optionsDict = optionsDict
                self?.activityIndicator.stopAnimating()
                self?.optionsTable.reloadData()
            }
        }
        
        switch playlistType {
        case .some(.albums): fetcher.getUserAlbums(completionHandler: completionHandler)
        case .some(.artists): fetcher.getUserArtists(completionHandler: completionHandler)
        case .some(.playlists): fetcher.getUserPlaylists(completionHandler: completionHandler)
        default: break
        }
    }
    
    private func initializeBadge() {
        let controller = tabBarController! as! AddTracksTabBarController
        setBadge(to: controller.tracksSelected.count + controller.libraryTracksSelected.count)
    }
    
    // MARK - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return optionsDict.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionsDict[orderedOptionsDictKeys[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = orderedOptionsDictKeys[indexPath.section]
        
        performSegue(withIdentifier: "Show Tracks", sender: (optionsDict[section]![indexPath.row].tracks, optionsDict[section]![indexPath.row].name))
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = AppConstants.darkerBlack
        
        let label = UILabel(frame: CGRect(x: 30, y: view.center.y + 13, width: 40, height: 15))
        label.text = orderedOptionsDictKeys[section]
        label.font = UIFont(name: "AvenirNext-Bold", size: 20)
        label.textColor = .white
        
        view.addSubview(label)
        
        return view
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return orderedOptionsDictKeys
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Option", for: indexPath) as! PlaylistSubcategoryTableViewCell
        
        let section = orderedOptionsDictKeys[indexPath.section]
        let row = optionsDict[section]![indexPath.row]
        
        cell.optionLabel.text = row.name
        cell.backgroundColor = .clear
        
        return cell
    }

    // MARK: - Navigation

    @IBAction func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? UserTracksViewController,
            let (tracks, playlistName) = sender as? ([Track], String) {
            controller.musicService = musicService
            controller.playlistType = playlistType
            controller.playlistName = playlistName
            controller.intermediateTracksList = tracks
        }
    }

}
