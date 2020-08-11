//
//  Post.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class Post {
  var postID: String
  var postDate: Date
  var thumbURL: URL
  var fullURL: URL
  var author: INUser
  var text: String
  var comments: [Comment]
  var isLiked = false
  var mine = false
  var likeCount = 0

  convenience init(snapshot: DataSnapshot, andComments comments: [Comment], andLikes likes: [String: Any]?) {
    self.init(id: snapshot.key, value: snapshot.value as! [String : Any], andComments: comments, andLikes: likes)
  }

  init(id: String, value: [String: Any], andComments comments: [Comment], andLikes likes: [String: Any]?) {
    self.postID = id
    self.text = value["text"] as! String
    let timestamp = value["timestamp"] as! Double
    self.postDate = Date(timeIntervalSince1970: (timestamp / 1_000.0))
    let author = value["author"] as! [String: String]
    self.author = INUser(dictionary: author)
    self.thumbURL = URL(string: value["thumb_url"] as! String)!
    self.fullURL = URL(string: value["full_url"] as! String)!
    self.comments = comments
    if let likes = likes {
      likeCount = likes.count
      if let uid = Auth.auth().currentUser?.uid {
        isLiked = (likes.index(forKey: uid) != nil)
      }
    }
    self.mine = self.author == Auth.auth().currentUser!
  }
}

extension Post: Equatable {
  static func ==(lhs: Post, rhs: Post) -> Bool {
    return lhs.postID == rhs.postID
  }
}
