//
//  JukeboxViewController.swift
//  GildtApp
//
//  Created by Jeroen Besse on 14/11/2018.
//  Copyright © 2018 Gildt. All rights reserved.
//

import Foundation
import UIKit

class JukeboxViewController: GenericTableViewController<SongRequestTableViewCell, (songRequest: SongRequest, row: Int)> {
    
    override func getCellId() -> String {
        return "SongRequestTableViewCell"
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var plusButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Jukebox"
        
        setupAddButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setupAddButton() {
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addSongButtonTouched))
        plusButton.isUserInteractionEnabled = true
        plusButton.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func getItems() {
        JukeboxAPIService.getSongRequests()
            .responseData(completionHandler: { [weak self] (response) in
                guard let jsonData = response.data else { return }
                
                let decoder = JSONDecoder()
                let data = try? decoder.decode([SongRequest].self, from: jsonData)
                
                DispatchQueue.main.async {
                    if data != nil {
                        self?.reloadSongRequests(newData: data!)
                    }
                }
            })
    }
    
    func reloadSongRequests(newData: [SongRequest]) {
        var i = 1
        for song in newData {
            items.append((song, i))
            i += 1
        }
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.refreshControl?.alpha = 0
            self.refreshControl?.endRefreshing()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.refreshControl?.alpha = 1
        })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let song = items[row]
        JukeboxAPIService.upvoteSong(songId: song.songRequest.id)
            .responseData(completionHandler: { [weak self] (response) in
                guard let jsonData = response.data else { return }
                
                let decoder = JSONDecoder()
                let data = try? decoder.decode(SongRequest.self, from: jsonData)
                
                DispatchQueue.main.async {
                    if data != nil {
                        self?.changeUpvote(indexPath: indexPath)
                    }
                }
            })
    }
    
    func changeUpvote(indexPath: IndexPath) {
        getItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func titleTextFieldDidEnd(_ sender: Any) {
        titleTextField.endEditing(true)
        artistTextField.becomeFirstResponder()
    }

    @IBAction func artistTextFieldDidEnd(_ sender: Any) {
        addSong()
        artistTextField.endEditing(true)
    }
    
    @objc func addSongButtonTouched() {
        addSong()
    }
    
    func addSong() {
        let title = titleTextField.text
        let artist = artistTextField.text
        //check if nil!!??
        if let title = title, let artist = artist {
            let song = NewSong(title: title, artist: artist)
            JukeboxAPIService.addSong(song: song)
                .response(completionHandler: { [weak self] (response) in
                    
                    guard let jsonData = response.data else { return }
                    
                    let decoder = JSONDecoder()
                    let songRequest = try? decoder.decode(SongRequest.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        if let songRequest = songRequest {
                            self?.successfullyAddedSong(song: songRequest)
                        }
                    }
                })
        }
    }
    
    func successfullyAddedSong(song: SongRequest) {
        //songRequests.append(song)
        tableView.reloadData()
        titleTextField.text = ""
        artistTextField.text = ""
        //make beautifull animation highlight thingy
    }
}
