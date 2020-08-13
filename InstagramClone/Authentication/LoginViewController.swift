//
//  LoginViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseMessaging

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    lazy var database = Database.database()
    var blockedRef: DatabaseReference!
    var blockingRef: DatabaseReference!
    private var blocked = Set<String>()
    private var blocking = Set<String>()
    var notificationGranted = false
    var handle: AuthStateDidChangeListenerHandle?
    
    private let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ", attributes:
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
             NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes:
            [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
             NSAttributedString.Key.foregroundColor : UIColor.blue]))
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
   
    @IBAction func signoutPressed(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
          guard let strongSelf = self else { return }
            print("_______")
            print(authResult?.user)
//            if let user = authResult?.user {
//                let user = INUser(snapshot: user)
//            }
            print("_______")
//            let user = INUser(snapshot: authResult)
//            signed(in: user)
            if error == nil {
                let st = UIStoryboard.init(name: "Main", bundle: nil)
                let vc = st.instantiateViewController(withIdentifier: "InitialTabBarController")
                
                self?.navigationController?.pushViewController(vc, animated: true)
                print("User successfully logged in ..")
            }
            print(error?.localizedDescription)
        }
    }
    
    @objc func handleShowSignUp(){
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "SignupViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func signed(in user: User) {
        blockedRef = database.reference(withPath: "blocked/\(user.uid)")
        blockingRef = database.reference(withPath: "blocking/\(user.uid)")
        observeBlocks()
        let imageUrl = user.isAnonymous ? "" : user.providerData[0].photoURL?.absoluteString

        let displayName = user.isAnonymous ? "Anonymous" : user.providerData[0].displayName ?? ""


        var values: [String: Any] = ["profile_picture": imageUrl ?? "",
                                     "full_name": displayName]

        if !user.isAnonymous, let name = user.providerData[0].displayName, !name.isEmpty {
          values["_search_index"] = ["full_name": name.lowercased(),
                                     "reversed_full_name": name.components(separatedBy: " ")
                                      .reversed().joined(separator: "")]
        }

        if notificationGranted {
          values["notificationEnabled"] = true
          notificationGranted = false
        }
        database.reference(withPath: "people/\(user.uid)")
          .updateChildValues(values)
      }
    
    func initializeUser(){
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
          // ...
            } as! DatabaseReference
    }
    
    func observeBlocks() {
      blockedRef.observe(.childAdded) { self.blocked.insert($0.key) }
      blockingRef.observe(.childAdded) { self.blocking.insert($0.key) }
      blockedRef.observe(.childRemoved) { self.blocked.remove($0.key) }
      blockingRef.observe(.childRemoved) { self.blocking.remove($0.key) }
    }

}
