//
//  ProfileViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/10/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class ProfileViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    
    
    @IBOutlet weak var userPostsTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
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
    var postIDs = [String: Bool]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfile()
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.black.cgColor
        
        // Do any additional setup after loading the view.
    }
    func loadData() {
        
        query = postsRef
        loadFeed()
        //listenDeletes()
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
                self.userPostsTableView.reloadData()
                
                
                //self.listenPost(post)
                //self.collectionView?.insertItems(at: lastIndex)
            })
        })
    }
    
//    func loadProfile1(){
//        let userID = Auth.auth().currentUser?.uid
//        let postRef = database.reference(withPath: "poeple/\(userID)")
//        ref = postRef.observe(DataEventType.value, with: { (snapshot) in
//          let postDict = snapshot.value as? [String : AnyObject] ?? [:]
//          print(snapshot)
//          print(userID)
//        })
//    }
    
    
    
    
    
    func loadProfile(){
        let userID = Auth.auth().currentUser?.uid
        database.reference(withPath: "people/\(userID)/posts").observeSingleEvent(of: .value, with: { (snapshot) in
            for i in snapshot.children {
                let val = (i as! DataSnapshot).value as? NSDictionary
                guard let author = val?["author"] else { return }
                guard let uid = val?["uid"] as? String else { return }
                
                
                guard let post = val?["posts"] else { return }
                let authorDict: [String: String] = author as! [String : String]
                let postsDict: [String: Bool] = post as! [String: Bool]
                self.nameLabel.text = authorDict["full_name"]
                //implement dispatch group
                self.profileImageView.load(url: URL(string: authorDict["profile_picture"]!)!)
                self.postIDs = postsDict
            }
            
//            guard let author = val["author"] else { return }
//            guard let post = val["posts"] else { return }
//            let authorDict: [String: String] = author as! [String : String]
//            let postsDict: [String: Bool] = post as! [String: Bool]
//            self.nameLabel.text = authorDict["full_name"]
//            //implement dispatch group
//            self.profileImageView.load(url: URL(string: authorDict["profile_picture"]!)!)
//            self.postIDs = postsDict
            //Get user value
//            for i in snapshot.children{
//                if
//                let val = (i as! DataSnapshot).value as? NSDictionary
//                guard let author = val?["author"] else { return }
//                guard let post = val?["posts"] else { return }
//                let authorDict: [String: String] = author as! [String : String]
//                let postsDict: [String: Bool] = post as! [String: Bool]
//                self.nameLabel.text = authorDict["full_name"]
//                //implement dispatch group
//                self.profileImageView.load(url: URL(string: authorDict["profile_picture"]!)!)
//                self.postIDs = postsDict
//            }
            //self.loadData()
        }) { (error) in
            print(error.localizedDescription)
        }
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
