//
//  Comment.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Comment {
  var commentID: String
  var text: String
  var postDate: Date
  var from: INUser

  init(snapshot: DataSnapshot) {
    self.commentID = snapshot.key
    let value = snapshot.value as! [String: Any]
    self.text = value["text"] as? String ?? ""
    let timestamp = value["timestamp"] as! Double
    self.postDate = Date(timeIntervalSince1970: timestamp / 1_000.0)
    let author = value["author"] as! [String: String]
    self.from = INUser(dictionary: author)
  }
}

extension Comment: Equatable {
  static func ==(lhs: Comment, rhs: Comment) -> Bool {
    return lhs.commentID == rhs.commentID && lhs.postDate == rhs.postDate
  }
}
