//
//  GenrePickingTableViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/18/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

protocol changeSelectedGenresList: class {
    func addToGenresList(withGenre genre: String)
    func removeFromGenresList(withGenre genre: String)
}

class GenrePickingTableViewController: UITableViewController {
    
    var genres = ["Rock", "Pop", "Hip Hop", "Country", "Alternative"]
    var selectedGenres = [String]()
    weak var delegate: changeSelectedGenresList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        
        adjustTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectRows()
    }
    
    func adjustTableView() {
        tableView.allowsMultipleSelection = true
        tableView.rowHeight = 70
        tableView.separatorColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    }
    
    func selectRows() {
        for genre in selectedGenres {
            let index = genres.index(of: genre)!
            let rowToSelect = IndexPath(item: index, section: 0)
            
            if let cell = tableView.cellForRow(at: rowToSelect) {
                cell.accessoryType = .checkmark
                cell.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
            }
            tableView.selectRow(at: rowToSelect, animated: false, scrollPosition: UITableViewScrollPosition.none)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genre", for: indexPath)

        cell.textLabel?.text = genres[indexPath.row]
        cell.textLabel?.textColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        cell.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        }
        
        delegate?.addToGenresList(withGenre: genres[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
        
        delegate?.removeFromGenresList(withGenre: genres[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor(colorLiteralRed: 58/255, green: 32/255, blue: 15/255, alpha: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        }
    }

    @IBAction func goBack(_ sender: setupButton) {
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
