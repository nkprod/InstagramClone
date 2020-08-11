//
//  UserProfileViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import Lightbox
import MaterialComponents

class UserProfileViewController: UIViewController {

    fileprivate let feedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical 
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(feedCollectionView)
        configureCollectionView()
        // Do any additional setup after loading the view.
    }
    
    func configureCollectionView(){
        feedCollectionView.backgroundColor = .white
        feedCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        feedCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true
        feedCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        feedCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        feedCollectionView.delegate = self
        feedCollectionView.dataSource = self
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UserProfileViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
          return CGSize(width: collectionView.bounds.size.width, height: 112)
        }
        let height = MDCCeil(((collectionView.bounds.width) - 14) * 0.325)
        return CGSize(width: height, height: height)    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "header", for: indexPath)
        cell.backgroundColor = .red
        return cell
    }
    
    
}
