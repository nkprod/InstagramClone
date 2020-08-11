//
//  LoginViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
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

}
