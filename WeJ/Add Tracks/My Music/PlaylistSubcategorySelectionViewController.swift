//
//  PlaylistSubcategorySelectionViewController.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/11/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import RKNotificationHub
import NVActivityIndicatorView
import MediaPlayer

class PlaylistSubcategorySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    private var badge: RKNotificationHub!
    private var totalTracksCount: Int {
        let controller = tabBarController! as! AddTracksTabBarController
        return controller.tracksSelected.count + controller.libraryTracksSelected.count
    }
    
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
        badge.count = Int32(count)
        badge.pop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeBadge()
        initializeVariables()
        
        setDelegates()
        adjustViews()
        adjustFontSizes()
        customizeTableView()
        
        setOptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setBadge(to: totalTracksCount)
    }
    
    private func initializeBadge() {
        badge = RKNotificationHub(view: doneButton.titleLabel)
        badge.count = Int32(totalTracksCount)
        badge.moveCircleBy(x: 51, y: 0)
        badge.scaleCircleSize(by: 0.7)
        badge.setCircleColor(AppConstants.orange, label: .white)
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
    
    private func adjustViews() {
        switch playlistType {
        case .some(.albums): titleLabel.text = NSLocalizedString("Albums", comment: "")
        case .some(.artists): titleLabel.text = NSLocalizedString("Artists", comment: "")
        case .some(.playlists): titleLabel.text = NSLocalizedString("Playlists", comment: "")
        default: break
        }
    }
    
    private func adjustFontSizes() {
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            titleLabel.changeToSmallerFont()
            doneButton.changeToSmallerFont()
        }
    }
    
    private func customizeTableView() {
        edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        
        optionsTable.sectionIndexColor = .gray
        optionsTable.sectionIndexBackgroundColor = .clear
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
        case .some(.albums): fetcher.getLibraryAlbums(completionHandler: completionHandler)
        case .some(.artists): fetcher.getLibraryArtists(completionHandler: completionHandler)
        case .some(.playlists): fetcher.getLibraryPlaylists(completionHandler: completionHandler)
        default: break
        }
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
        if let controller = segue.destination as? LibraryTracksViewController,
            let (tracks, playlistName) = sender as? ([Track], String) {
            controller.musicService = musicService
            controller.playlistType = playlistType
            controller.playlistName = playlistName
            controller.intermediateTracksList = tracks
        }
    }

}
