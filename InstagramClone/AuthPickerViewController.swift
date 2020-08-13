//
//  AuthPickerViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import FirebaseUI
import MaterialComponents.MDCTypography

class AuthPickerViewController: FUIAuthPickerViewController {

    
    @IBAction func signupPressed(_ sender: UIButton) {
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "SignupViewController")
        present(vc, animated: true)
    }
    
    @IBAction func loginPressed(_ sender: Any) {
    }
    
     override func viewDidAppear(_ animated: Bool) {
       super.viewDidAppear(animated)
        
       // configureUI()
//       if (AppDelegate.euroZone) {
//         readonlyWarningLabel.isHidden = false
//       }
//       if !agreed {
//         self.present(disclaimer, animated: true, completion: nil)
//       }
     }
    func configureUI() {
        
        //configureNaviagtionController()
//
//        view.backgroundColor = .backgroundColor
//        //view.addSubview(uberTitleLabel)
//        //uberTitleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 40)
//        //uberTitleLabel.centerX(inView: view)
//
//        let stackView = UIStackView(arrangedSubviews: [emailContainerView,
//                                                        passwordContainerView,
//                                                         loginButton])
//        stackView.axis = .vertical
//        stackView.distribution = .fillEqually
//        stackView.spacing = 16
//
//        view.addSubview(stackView)
//
//        stackView.anchorItem(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
    }

}
