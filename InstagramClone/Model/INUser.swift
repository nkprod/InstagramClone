//
//  User.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.

import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class INUser {
  var uid: String
  var fullname: String
  var profilePictureURL: URL?

  init(snapshot: DataSnapshot) {
    self.uid = snapshot.key
    let value = snapshot.value as! [String: Any]
    self.fullname = value["full_name"] as? String ?? ""
    guard let profile_picture = value["profile_picture"] as? String,
      let profilePictureURL = URL(string: profile_picture) else { return }
    self.profilePictureURL = profilePictureURL
  }

  init(dictionary: [String: String]) {
    self.uid = dictionary["uid"]!
    self.fullname = dictionary["full_name"] ?? ""
    guard let profile_picture = dictionary["profile_picture"],
      let profilePictureURL = URL(string: profile_picture) else { return }
    self.profilePictureURL = profilePictureURL
  }

  private init(user: FirebaseAuth.User) {
    self.uid = user.uid
    self.fullname = user.displayName ?? ""
    self.profilePictureURL = user.photoURL
  }

  static func currentUser() -> INUser {
    return INUser(user: Auth.auth().currentUser!)
  }

  func author() -> [String: String] {
    return ["uid": uid, "full_name": fullname, "profile_picture": profilePictureURL?.absoluteString ?? ""]
  }
}

extension INUser: Equatable {
    static func ==(lhs: INUser, rhs: INUser) -> Bool {
        return lhs.uid == rhs.uid
    }
    static func ==(lhs: INUser, rhs: User ) -> Bool {
        return lhs.uid == rhs.uid
    }

}

