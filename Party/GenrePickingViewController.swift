//
//  GenrePickingViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/21/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class GenrePickingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: changeSelectedGenresList?
    @IBOutlet weak var genresTableView: UITableView!
    var party = Party()
    var genres = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.genresTableView.reloadData()
            }
        }
    }
    let APIManager = RestApiManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpDelegates()
        adjustTableView()
        populateGenres()

        // Do any additional setup after loading the view.
    }
    
    func setUpDelegates() {
        genresTableView.delegate = self
        genresTableView.dataSource = self
    }

    private func adjustTableView() {
        genresTableView.allowsMultipleSelection = true
        genresTableView.rowHeight = 70
        genresTableView.separatorColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        genresTableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    }
    
    private func populateGenres() {
        APIManager.requestGenresFromApple()
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroupForGenreFetch.wait()
            self.genres = self.APIManager.genresList.sorted {
                $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
            }
            self.selectPreviouslySelectedGenres()
        }
    }
    
    private func selectPreviouslySelectedGenres() {
        DispatchQueue.main.async {
            for genresSelected in self.party.genres {
                self.genresTableView.selectRow(at: IndexPath(row: self.genres.index(of: genresSelected)!, section: 0), animated: true, scrollPosition: .none)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genre", for: indexPath)
        
        cell.textLabel?.text = genres[indexPath.row]
        cell.textLabel?.textColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        cell.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        cell.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        
        if party.genres.contains(genres[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        party.genres.append(genres[indexPath.row])
        delegate?.addToGenresList(withGenre: genres[indexPath.row])

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        party.genres.remove(at: party.genres.index(of: genres[indexPath.row])!)
        delegate?.removeFromGenresList(withGenre: genres[indexPath.row])
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor(colorLiteralRed: 58/255, green: 32/255, blue: 15/255, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        }
    }
    

    
    // MARK: - Navigation
    
    @IBAction func goBack(_ sender: setupButton) {
        dismiss(animated: true, completion: nil)
    }
    

}
