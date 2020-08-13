//
//  ChatViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

    var john: Person?
    var unit4A: Apartment?
    override func viewDidLoad() {
        super.viewDidLoad()
        john = Person(name: "John Appleseed")
        unit4A = Apartment(unit: "4A")
        //john!.apartment = unit4A
        //unit4A!.tenant = john
        
    }
    deinit(){
        print("About to Deinitialize")
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
