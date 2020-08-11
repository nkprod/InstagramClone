//
//  UProfileCollectionViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

private let reuseIdentifier = "Cell"

class UProfileCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout {

    //properties for db and storage
    var headerView: UserHeader!
    var profile: INUser!
    let uid = Auth.auth().currentUser!.uid
    let database = Database.database()
    let ref = Database.database().reference()
    var postIds: [String: Any]?
    var postSnapshots = [DataSnapshot]()
    var loadingPostCount = 0
    var firebaseRefs = [DatabaseReference]()
    var insets: UIEdgeInsets!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      loadData()
    }
    
    func loadData() {
//      if profile.uid == uid {
//        registerToNotificationEnabledStatusUpdate()
//      } else {
//        registerToFollowStatusUpdate()
//      }
      registerForFollowersCount()
      registerForFollowingCount()
      registerForPostsCount()
      loadUserPosts()
    }
    
    func registerToFollowStatusUpdate() {
      let followStatusRef = database.reference(withPath: "people/\(uid)/following/\(profile.uid)")
      followStatusRef.observe(.value) {
        self.headerView.followSwitch.isOn = $0.exists()
      }
      firebaseRefs.append(followStatusRef)
    }

    func registerToNotificationEnabledStatusUpdate() {
      let notificationEnabledRef  = database.reference(withPath: "people/\(uid)/notificationEnabled")
      notificationEnabledRef.observe(.value) {
        self.headerView.followSwitch.isOn = $0.exists()
      }
      firebaseRefs.append(notificationEnabledRef)
    }

    func registerForFollowersCount() {
      let followersRef = database.reference(withPath: "followers/\(profile.uid)")
      followersRef.observe(.value, with: {
        self.headerView.followersLabel.text = "\($0.childrenCount) follower\($0.childrenCount != 1 ? "s" : "")"
      })
      firebaseRefs.append(followersRef)
    }

    func registerForFollowingCount() {
      let followingRef = database.reference(withPath: "people/\(profile.uid)/following")
      followingRef.observe(.value, with: {
        self.headerView.followingLabel.text = "\($0.childrenCount) following"
      })
      firebaseRefs.append(followingRef)
    }

    func registerForPostsCount() {
      let userPostsRef = database.reference(withPath: "people/\(profile.uid)/posts")
      userPostsRef.observe(.value, with: {
        self.headerView.postsLabel.text = "\($0.childrenCount) post\($0.childrenCount != 1 ? "s" : "")"
      })
    }

    func registerForPostsDeletion() {
      let userPostsRef = database.reference(withPath: "people/\(profile.uid)/posts")
      userPostsRef.observe(.childRemoved, with: { postSnapshot in
        var index = 0
        for post in self.postSnapshots {
          if post.key == postSnapshot.key {
            self.postSnapshots.remove(at: index)
            self.loadingPostCount -= 1
            self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 1)])
            return
          }
          index += 1
        }
        self.postIds?.removeValue(forKey: postSnapshot.key)
      })
    }


    func loadUserPosts() {
      database.reference(withPath: "people/\(profile.uid)/posts").observeSingleEvent(of: .value, with: {
        if var posts = $0.value as? [String: Any] {
          if !self.postSnapshots.isEmpty {
            var index = self.postSnapshots.count - 1
            self.collectionView?.performBatchUpdates({
              for post in self.postSnapshots.reversed() {
                if posts.removeValue(forKey: post.key) == nil {
                  self.postSnapshots.remove(at: index)
                  self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 1)])
                  return
                }
                index -= 1
              }
            }, completion: nil)
            self.postIds = posts
            self.loadingPostCount = posts.count
          } else {
            self.postIds = posts
            self.loadFeed()
          }
          self.registerForPostsDeletion()
        }
      })
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
          return 1
        }
        return postSnapshots.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
          let header = collectionView.dequeueReusableCell(withReuseIdentifier: "header", for: indexPath) as! UserHeader
          header.inkColor = .clear
          headerView = header
          if profile.uid == uid {
            header.followLabel.text = "Notifications"
            header.followSwitch.accessibilityLabel = header.followSwitch.isOn ? "Notifications are on" : "Notifications are off"
            header.followSwitch.accessibilityHint = "Double-tap to \(header.followSwitch.isOn ? "disable" : "enable") notifications"
          } else {
            header.followSwitch.accessibilityHint = "Double-tap to \(header.followSwitch.isOn ? "un" : "")follow"
            header.followSwitch.accessibilityLabel = "\(header.followSwitch.isOn ? "" : "not ")following \(profile.fullname)"
          }
          header.profilePictureImageView.sd_setImage(with: profile.profilePictureURL, completed: nil)
          return header
        } else {
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
          let postSnapshot = postSnapshots[indexPath.item]
          if let value = postSnapshot.value as? [String: Any], let photoUrl = value["thumb_url"] as? String {
            let imageView = UIImageView()
            cell.backgroundView = imageView
            imageView.sd_setImage(with: URL(string: photoUrl), completed: nil)
            imageView.contentMode = .scaleAspectFill
            imageView.isAccessibilityElement = true
            imageView.accessibilityLabel = "Photo by \(profile.fullname)"
          }
          return cell
        }
    }
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.item == (loadingPostCount - 3) {
          loadFeed()
        }

    }
    
    func loadFeed() {
      loadingPostCount = postSnapshots.count + 10
      self.collectionView?.performBatchUpdates({
        for _ in 1...10 {
          if let postId = self.postIds?.popFirst()?.key {
            database.reference(withPath: "posts/\(postId)").observeSingleEvent(of: .value, with: { postSnapshot in
              self.postSnapshots.append(postSnapshot)
              self.collectionView?.insertItems(at: [IndexPath(item: self.postSnapshots.count - 1, section: 1)])
            })
          } else {
            break
          }
        }
      }, completion: nil)
    }
    
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
