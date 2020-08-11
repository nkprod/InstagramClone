//
//  SignupViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var securityPassword: UITextField!
    
    
    // Firebase realtime db
    lazy var database = Database.database()
    lazy var storage = Storage.storage()
    
    
    var fullURL = ""
    
    private let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Already have an account? ", attributes:
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
             NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Log In", attributes:
            [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
             NSAttributedString.Key.foregroundColor : UIColor.blue]))
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
        configureImageView()
        
    }
    
    
   
    @IBAction func signupPressed(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let name = nameTextField.text else { return }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if error == nil{
                
                //Upload image to the storage
                guard let image = self.profileImageView.image else { return }
                uploadProfileImage(image) {url in
                    //Save profile data to database
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = name
                    changeRequest?.photoURL = URL(string: self.fullURL)
                    changeRequest?.commitChanges { error in
                        if error == nil {
                            print("User display name changed!")
                            saveProfile(username: name, profileImageURL: URL(string: self.fullURL)!){success in
                                if success{
                                    self.navigationController?.popViewController(animated: true)
                                }
                        
                            }
                            
                        } else {
                            print(error?.localizedDescription)
                        }
                    }

                }
                //Dismiss the view
                
                
            }
        }
        
        func uploadProfileImage(_ image: UIImage, completion: @escaping ((_ url: String?)->())) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let profileImageRef = storage.reference().child("user/\(uid)")

            guard let imageData = image.jpegData(compressionQuality: 0.1) else { return }
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            let myGroup = DispatchGroup()
            myGroup.enter()
            profileImageRef.putData(imageData, metadata: nil) { fullmetadata, error in
              if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
              }

              profileImageRef.downloadURL(completion: { (url, error) in
                if let error = error {
                  print(error.localizedDescription)
                  return
                }
                if let url = url?.absoluteString {
                  self.fullURL = url
                  completion(url)
                }
                myGroup.leave()
              })
            }
        }
        func saveProfile(username: String, profileImageURL: URL, completion: @escaping ((_ success: Bool)->())){
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let dataBaseRef = database.reference().child("people/\(uid)/author")
            let authorDict = ["full_name": username, "profile_picture": profileImageURL.absoluteString, "uid": "\(uid)"]
            let user  = INUser(dictionary: authorDict)
            dataBaseRef.setValue(authorDict) {error, ref in
                completion(error == nil)
            }
            
        }
    }

    
    @objc func handleShowLogin(){
        self.navigationController?.popViewController(animated: true)
    }
    
    func configureImageView(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.black.cgColor
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        profileImageView.image = image
        
        
    }
    


}


extension UIView {
    func anchor(top: NSLayoutYAxisAnchor? = nil,
                left: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                right: NSLayoutXAxisAnchor? = nil,
                paddingTop: CGFloat = 0,
                paddingLeft: CGFloat = 0,
                paddingBottom: CGFloat = 0,
                paddingRight: CGFloat = 0,
                width: CGFloat? = nil,
                height: CGFloat? = nil) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func centerX(inView view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func centerY(inView view: UIView, leftAnchor: NSLayoutXAxisAnchor? = nil,
                 paddingLeft: CGFloat = 0, constant: CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
//
//        if let left = leftAnchor {
//            anchor(left: left, paddingLeft: paddingLeft)
//        }
    }
    

    
    
}
