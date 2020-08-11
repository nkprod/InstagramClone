//
//  ViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import Lightbox
import FirebaseAuth
import FirebaseDatabase
import ImagePicker
import FirebaseStorage
import MaterialComponents


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FPCardCollectionViewCellDelegate {
    
    var currentUser: User!
    lazy var uid = currentUser.uid
    
    
    func showProfile(_ profile: INUser) {
        performSegue(withIdentifier: "account", sender: profile)
    }
    
    func showTaggedPhotos(_ hashtag: String) {
        performSegue(withIdentifier: "hashtag", sender: hashtag)
    }
    
    func showLightbox(_ index: Int) {
      let lightboxImages = posts.map {
        return LightboxImage(imageURL: $0.fullURL, text: "\($0.author.fullname): \($0.text)")
      }
    }
    
      func viewComments(_ post: Post) {
      performSegue(withIdentifier: "comment", sender: post)
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
    

    
    @IBOutlet weak var feedTableView: UITableView!
    var handle: AuthStateDidChangeListenerHandle?
    var data = [(description: Any, comment: Any)]()
    var query: DatabaseReference!
    lazy var database = Database.database()
    lazy var ref = self.database.reference()
    lazy var postsRef = self.database.reference(withPath: "posts")
    lazy var commentsRef = self.database.reference(withPath: "comments")
    lazy var likesRef = self.database.reference(withPath: "likes")
    var observers = [DatabaseQuery]()
    var posts = [Post]()
    static let postsPerLoad: Int = 3
    static let postsLimit: UInt = 4
    var loadingPostCount : Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        feedTableView.delegate = self
        feedTableView.dataSource = self
        self.feedTableView.reloadData()
        //reloadFeed()
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
//            if let user = user {
//              let uid = user.uid
//              let email = user.email
//              let photoURL = user.photoURL
//            }
        }
    }
    
    
    @IBAction func addPost(_ sender: Any) {
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "UploadPostViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func logoutPressed(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
//        let st = UIStoryboard.init(name: "Main", bundle: nil)
//        let vc = st.instantiateViewController(withIdentifier: "LoginViewController")
//        present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = posts[indexPath.row].author.uid 
        cell?.detailTextLabel?.text = posts[indexPath.row].text
        cell?.imageView?.load(url: posts[indexPath.row].thumbURL)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "FeedDetailView") as! FeedDetailView
        vc.imageURL = posts[indexPath.row].thumbURL
        vc.comment = posts[indexPath.row].text
        self.present(vc, animated: true, completion: nil)
    }
    
    func loadData() {
        query = postsRef
        loadFeed()
        //listenDeletes()
    }
    
    
    // read data
//    func loadFeed(){
//        let userID = Auth.auth().currentUser?.uid
//        ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
//          // Get user value
//            for i in snapshot.children{
//                let val = (i as! DataSnapshot).value as? NSDictionary
//                guard let author = val?["author"] else { return }
//                guard let comment = val?["text"] else { return }
//                let post: (description: Any, comment: Any) = (author,comment)
//                self.data.append(post)
//                self.feedTableView.reloadData()
//            }
//          }) { (error) in
//            print(error.localizedDescription)
//        }
//    }
    
    func loadFeed(){
        var query = self.query?.queryOrderedByKey()
        loadingPostCount = posts.count + ViewController.postsPerLoad
        query?.queryLimited(toLast: UInt(ViewController.postsPerLoad)).observeSingleEvent(of: .value, with: { snapshot in
            if let reversed = snapshot.children.allObjects as? [DataSnapshot], !reversed.isEmpty {

//              self.nextEntry = reversed[0].key
              var results = [Int: DataSnapshot]()
              let myGroup = DispatchGroup()
              let extraElement = reversed.count > ViewController.postsPerLoad ? 1 : 0
              for index in stride(from: reversed.count - 1, through: extraElement, by: -1) {
                let item = reversed[index]
                self.loadPost(item)
                }
//              self.collectionView?.performBatchUpdates({

//
//                  if self.showFeed {
//                    self.loadPost(item)
//                  } else {
//                    myGroup.enter()
//                    let current = reversed.count - 1 - index
//                    self.postsRef.child(item.key).observeSingleEvent(of: .value) {
//                      results[current] = $0
//                      myGroup.leave()
//                    }
//                  }
//                }
//                myGroup.notify(queue: .main) {
//                  if !self.showFeed {
//                    for index in 0..<(reversed.count - extraElement) {
//                      if let snapshot = results[index] {
//                        if snapshot.exists() {
//                          self.loadPost(snapshot)
//                        } else {
//                          self.loadingPostCount -= 1
//                          self.database.reference(withPath: "feed/\(self.uid)/\(snapshot.key)").removeValue()
//                        }
//                      }
//                    }
//                  }
//                }
//              }, completion: nil)
                
                
                
            }
        })
        
    }
    
    func loadPost(_ postSnapshot: DataSnapshot) {
      let postId = postSnapshot.key
      commentsRef.child(postId).observeSingleEvent(of: .value, with: { commentsSnapshot in
        var commentsArray = [Comment]()
        let enumerator = commentsSnapshot.children
        while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
            let comment = Comment(snapshot: commentSnapshot)
            commentsArray.append(comment)
        }
        self.likesRef.child(postId).observeSingleEvent(of: .value, with: { snapshot in
          let likes = snapshot.value as? [String: Any]
          let post = Post(snapshot: postSnapshot, andComments: commentsArray, andLikes: likes)
          self.posts.append(post)
          self.feedTableView.reloadData()
          

          //self.listenPost(post)
          //self.collectionView?.insertItems(at: lastIndex)
        })
      })
    }
    
}


extension UICollectionViewController {
  var feedViewController: ViewController {
    return navigationController?.viewControllers[0] as! ViewController
  }

  internal func cleanCollectionView() {
    if collectionView!.numberOfItems(inSection: 0) > 0 {
      collectionView!.reloadSections([0])
    }
  }
}

extension UIViewController {
  func displaySpinner() -> UIView {
    let spinnerView = UIView.init(frame: view.bounds)
    spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    let ai = UIActivityIndicatorView.init(style: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center

    DispatchQueue.main.async {
      spinnerView.addSubview(ai)
      self.view.addSubview(spinnerView)
    }
    return spinnerView
  }

  func removeSpinner(_ spinner: UIView) {
    DispatchQueue.main.async {
      spinner.removeFromSuperview()
    }
  }
}
