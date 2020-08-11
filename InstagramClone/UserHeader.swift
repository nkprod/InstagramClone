//
//  UserHeader.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import Foundation
import MaterialComponents

class UserHeader: MDCBaseCell {

    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var followLabel: UILabel!
    
    @IBOutlet weak var followSwitch: UISwitch!
    
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!

    
    @IBOutlet weak var postsLabel: UILabel!
}
