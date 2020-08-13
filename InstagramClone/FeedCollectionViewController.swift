//
//  FeedCollectionViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseUI
import MaterialComponents
import Lightbox



private let reuseIdentifier = "cell"

class FeedCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, CardCollectionViewCellDelegate {

    
    func showLightbox(_ index: Int) {
      let lightboxImages = posts.map {
        return LightboxImage(imageURL: $0.fullURL, text: "\($0.author.fullname): \($0.text)")
      }

      LightboxConfig.InfoLabel.textAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
      let lightbox = LightboxController(images: lightboxImages, startIndex: index)
      lightbox.dynamicBackground = true
      lightbox.dismissalDelegate = self

      self.present(lightbox, animated: true, completion: nil)
    }
    func showProfile(_ profile: INUser) {
      performSegue(withIdentifier: "account", sender: profile)
    }

    func showTaggedPhotos(_ hashtag: String) {
      performSegue(withIdentifier: "hashtag", sender: hashtag)
    }

    func viewComments(_ post: Post) {
      //performSegue(withIdentifier: "comment", sender: post)
        print("Comments opened .. ")
    }

    func toogleLike(_ post: Post, label: UILabel) {
      let postLike = database.reference(withPath: "likes/\(post.postID)/\(uid)")
      if post.isLiked {
        postLike.removeValue { error, _ in
          if let error = error {
            print(error.localizedDescription)
            return
          }
        }
      } else {
        postLike.setValue(ServerValue.timestamp()) { error, _ in
          if let error = error {
            print(error.localizedDescription)
            return
          }
        }
      }
    }

    func optionPost(_ post: Post, _ button: UIButton, completion: (() -> Swift.Void)? = nil) {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      if post.author.uid != uid {
        alert.addAction(UIAlertAction(title: "Report", style: .destructive , handler:{ _ in
          let alertController = MDCAlertController.init(title: "Report Post?", message: nil)
          let cancelAction = MDCAlertAction(title: "Cancel", handler: nil)
          let reportAction = MDCAlertAction(title: "Report") { _ in
            self.database.reference(withPath: "postFlags/\(post.postID)/\(self.uid)").setValue(true)
          }
          alertController.addAction(reportAction)
          alertController.addAction(cancelAction)
          self.present(alertController, animated: true, completion: nil)
        }))
      } else {
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ _ in
          let alertController = MDCAlertController.init(title: "Delete Post?", message: nil)
          let cancelAction = MDCAlertAction(title: "Cancel", handler: nil)
          let deleteAction = MDCAlertAction(title: "Delete") { _ in
            let postID = post.postID
            let update = [ "people/\(self.uid)/posts/\(postID)": NSNull(),
                           "comments/\(postID)": NSNull(),
                           "likes/\(postID)": NSNull(),
                           "posts/\(postID)": NSNull(),
                           "feed/\(self.uid)/\(postID)": NSNull()]
            self.ref.updateChildValues(update) { error, reference in
              if let error = error {
                print(error.localizedDescription)
                return
              }
              if let completion = completion {
                completion()
              }
            }
            let storage = Storage.storage()
            storage.reference(forURL: post.fullURL.absoluteString).delete()
            storage.reference(forURL: post.thumbURL.absoluteString).delete()
          }
          alertController.addAction(deleteAction)
          alertController.addAction(cancelAction)
          self.present(alertController, animated: true, completion: nil)
        }))
      }
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
      alert.popoverPresentationController?.sourceView = button
      alert.popoverPresentationController?.sourceRect = button.bounds
      present(alert, animated:true, completion:nil)
    }
    //ref to user
    var currentUser: User!
    lazy var uid = currentUser.uid
    var followingRef: DatabaseReference?
    
    //db setup
    lazy var database = Database.database()
    lazy var ref = self.database.reference()
    lazy var postsRef = self.database.reference(withPath: "posts")
    lazy var commentsRef = self.database.reference(withPath: "comments")
    lazy var likesRef = self.database.reference(withPath: "likes")
    
    var query: DatabaseReference!
    var posts = [Post]()
    var loadingPostCount = 0
    var nextEntry: String?
    var observers = [DatabaseQuery]()
    
    // limit for the post retirieval
    static let postsPerLoad: Int = 3
    static let postsLimit: UInt = 4
    
    //setup for posts
    var newPost = false
    var followChanged = false
    var isFirstOpen = true
    var showFeed = true
    
    //cell setup
    var sizingCell: UserFeedCollectionViewCell!
    
    
    
    
    //auth window
    lazy var authViewController: UINavigationController = {
      let controller = FUIAuth.defaultAuthUI()!.authViewController()
      controller.navigationBar.isHidden = true
      return controller
    }()

    
    //if there is no posts for the user show label
    let emptyHomeLabel: UILabel = {
      let messageLabel = UILabel()
      messageLabel.text = "This feed will be populated as you follow more people."
      messageLabel.textColor = UIColor.black
      messageLabel.numberOfLines = 0
      messageLabel.textAlignment = .center
      messageLabel.font = UIFont.preferredFont(forTextStyle: .title3)
      messageLabel.sizeToFit()
      return messageLabel
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "UserProfileCardCollectionViewCell", bundle: nil)
        guard let collectionView = collectionView else {
          return
        }
        collectionView.register(nib, forCellWithReuseIdentifier: "cell")
        sizingCell = Bundle.main.loadNibNamed("UserProfileCardCollectionViewCell", owner: self, options: nil)?[0]
          as? UserFeedCollectionViewCell

        let cellFrame = CGRect(x: 0, y: 0, width: collectionView.bounds.width,
                               height: collectionView.bounds.height)
        sizingCell.frame = cellFrame

        if #available(iOS 10.0, *) {
          let refreshControl = UIRefreshControl()
          refreshControl.addTarget(self,
                                   action: #selector(refreshOptions(sender:)),
                                   for: .valueChanged)
          collectionView.refreshControl = refreshControl
        }
//        let firebaseAuth = Auth.auth()
//        do {
//          try firebaseAuth.signOut()
//        } catch let signOutError as NSError {
//          print ("Error signing out: %@", signOutError)
//        }
    }

    
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)

        if let currentUser = Auth.auth().currentUser  {
          self.currentUser = currentUser
          //bottomBarView.floatingButton.isEnabled = !currentUser.isAnonymous
          //Crashlytics.crashlytics().setUserID(uid)
          self.followingRef = database.reference(withPath: "people/\(uid)/following")
        } else {
          self.present(authViewController, animated: true, completion: nil)
          return
        }
      if newPost {
        reloadFeed()
        newPost = false
        return
      }
      if !showFeed && followChanged {
        reloadFeed()
        followChanged = false
        return
      }
      loadData()
    }
    
    func loadData(){
        if showFeed {
          query = postsRef
          loadFeed()
          //listenDeletes()
        } else {
          query = database.reference(withPath: "feed/\(uid)")
          // Make sure the home feed is updated with followed users's new posts.
          // Only after the feed creation is complete, start fetching the posts.
          //updateHomeFeeds()
        }
    }
    
      func loadFeed() {
      if observers.isEmpty && !posts.isEmpty {
        for post in posts {
          postsRef.child(post.postID).observeSingleEvent(of: .value, with: {
            if $0.exists() && !self.blocked {
              self.updatePost(post, postSnapshot: $0)
              //self.listenPost(post)
            } else {
              if let index = self.posts.firstIndex(where: {$0.postID == post.postID}) {
                self.posts.remove(at: index)
                self.loadingPostCount -= 1
                self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
                if self.posts.isEmpty {
                  self.collectionView?.backgroundView = self.emptyHomeLabel
                }
              }
            }
          })
        }
      } else {
        var query = self.query?.queryOrderedByKey()
        if let queryEnding = nextEntry {
          query = query?.queryEnding(atValue: queryEnding)
        }
        loadingPostCount = posts.count + FeedCollectionViewController.postsPerLoad
        query?.queryLimited(toLast: FeedCollectionViewController.postsLimit).observeSingleEvent(of: .value, with: { snapshot in
          if let reversed = snapshot.children.allObjects as? [DataSnapshot], !reversed.isEmpty {
            self.collectionView?.backgroundView = nil
            self.nextEntry = reversed[0].key
            var results = [Int: DataSnapshot]()
            let myGroup = DispatchGroup()
            let extraElement = reversed.count > FeedCollectionViewController.postsPerLoad ? 1 : 0
            self.collectionView?.performBatchUpdates({
              for index in stride(from: reversed.count - 1, through: extraElement, by: -1) {
                let item = reversed[index]
                if self.showFeed {
                  self.loadPost(item)
                } else {
                  myGroup.enter()
                  let current = reversed.count - 1 - index
                  self.postsRef.child(item.key).observeSingleEvent(of: .value) {
                    results[current] = $0
                    myGroup.leave()
                  }
                }
              }
              myGroup.notify(queue: .main) {
                if !self.showFeed {
                  for index in 0..<(reversed.count - extraElement) {
                    if let snapshot = results[index] {
                      if snapshot.exists() {
                        self.loadPost(snapshot)
                      } else {
                        self.loadingPostCount -= 1
                        self.database.reference(withPath: "feed/\(self.uid)/\(snapshot.key)").removeValue()
                      }
                    }
                  }
                }
              }
            }, completion: nil)
          } else if self.posts.isEmpty && !self.showFeed {
                self.collectionView?.backgroundView = self.emptyHomeLabel
          }
        })
      }
    }
    let blocked = false
    func loadPost(_ postSnapshot: DataSnapshot) {
      let postId = postSnapshot.key
      commentsRef.child(postId).observeSingleEvent(of: .value, with: { commentsSnapshot in
        var commentsArray = [Comment]()
        let enumerator = commentsSnapshot.children
        while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
            if !self.blocked {
            let comment = Comment(snapshot: commentSnapshot)
            commentsArray.append(comment)
          }
        }
        self.likesRef.child(postId).observeSingleEvent(of: .value, with: { snapshot in
          let likes = snapshot.value as? [String: Any]
          let post = Post(snapshot: postSnapshot, andComments: commentsArray, andLikes: likes)
          self.posts.append(post)
          let last = self.posts.count - 1
          let lastIndex = [IndexPath(item: last, section: 0)]
          //self.listenPost(post)
          self.collectionView?.insertItems(at: lastIndex)
        })
      })
    }
    
    
    func updatePost(_ post: Post, postSnapshot: DataSnapshot) {
      let postId = postSnapshot.key
      commentsRef.child(postId).observeSingleEvent(of: .value, with: { commentsSnapshot in
        var commentsArray = [Comment]()
        let enumerator = commentsSnapshot.children
        while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
          let comment = Comment(snapshot: commentSnapshot)
          commentsArray.append(comment)
        }
        if post.comments != commentsArray {
          post.comments = commentsArray
          if let index = self.posts.firstIndex(where: {$0.postID == post.postID}) {
            self.collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
            self.collectionViewLayout.invalidateLayout()
          }
        }
      })
    }
    
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      followingRef?.removeAllObservers()
      postsRef.removeAllObservers()
      for observer in observers {
        observer.removeAllObservers()
      }
      observers = [DatabaseQuery]()
    }
    

    @IBAction func logoutPressed(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
        self.present(authViewController, animated: true, completion: nil)

    }
    
    
    
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
      reloadFeed()
      sender.endRefreshing()
    }
    
    private func reloadFeed() {
      followingRef?.removeAllObservers()
      postsRef.removeAllObservers()
      for observer in observers {
        observer.removeAllObservers()
      }
      observers = [DatabaseQuery]()
      posts = [Post]()
      loadingPostCount = 0
      nextEntry = nil
      cleanCollectionView()
      loadData()
    }
    
    
    
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return posts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? UserFeedCollectionViewCell {
          let post = posts[indexPath.item]
          cell.populateContent(post: post, index: indexPath.item, isDryRun: false)
          cell.delegate = self
          cell.cornerRadius = 8
          //cell.setShadowElevation(ShadowElevation(rawValue: 6), for: .selected)
          cell.setShadowColor(UIColor.black, for: .highlighted)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      let post = posts[indexPath.item]
      sizingCell.populateContent(post: post, index: indexPath.item, isDryRun: true)

      sizingCell.setNeedsUpdateConstraints()
      sizingCell.updateConstraintsIfNeeded()
      sizingCell.contentView.setNeedsLayout()
      sizingCell.contentView.layoutIfNeeded()

      var fittingSize = UIView.layoutFittingCompressedSize
      fittingSize.width = sizingCell.frame.width

      return sizingCell.contentView.systemLayoutSizeFitting(fittingSize)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      isFirstOpen = false
      guard let identifier = segue.identifier else { return }
      switch identifier {
      case "account":
        if let accountViewController = segue.destination as? ProfileCollectionViewController, let profile = sender as? INUser {
          accountViewController.profile = profile
        }
//      case "comment":
//        if let commentViewController = segue.destination as? FPCommentViewController, let post = sender as? INUser {
//          commentViewController.post = post
//        }
//      case "upload":
//        if let viewController = segue.destination as? FPUploadViewController, let image = sender as? INUser {
//          viewController.image = image
//          newPost = true
//        }
//      case "hashtag":
//        if let viewController = segue.destination as? FPHashTagViewController, let hashtag = sender as? INUser {
//          viewController.hashtag = hashtag
//        }
      default:
        break
      }
    }

}

extension FeedCollectionViewController: LightboxControllerDismissalDelegate {
  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    self.collectionView?.scrollToItem(at: IndexPath.init(item: controller.currentPage, section: 0), at: .top, animated: false)
  }
}
