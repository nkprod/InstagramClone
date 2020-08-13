//
//  UploadPostViewController.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import IQKeyboardManager

class UploadPostViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITabBarControllerDelegate {
    
    var keyboardHeight: CGFloat = 0.0
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var postPhoto: UIImageView!
    @IBOutlet weak var postComment: UITextView!
    
    // Firebase realtime db
    lazy var database = Database.database()
    lazy var storage = Storage.storage()
    
    lazy var uid = Auth.auth().currentUser!.uid
    var fullURL = ""
    var thumbURL = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        customizeTextView()
        self.tabBarController?.delegate = self
        openPicture()
        
        // Do any additional setup after loading the view.
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
      let isModalTab = viewController == self
      
      if isModalTab {
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        let cameraVC = st.instantiateViewController(withIdentifier: "UploadPostViewController")
        present(cameraVC, animated: true)
      }
    }
    
    func customizeTextView(){
        self.addKeyboardNotification()
        postComment.layer.borderColor = UIColor.darkGray.cgColor
        postComment.layer.borderWidth = 1.5
        postComment.layer.cornerRadius = 10
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, self.keyboardHeight <= 0.0 {
            self.keyboardHeight = 150.0 //(Add 45 if your keyboard have toolBar if not then remove it)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.textViewBottomConstraint.constant = self.keyboardHeight
        }, completion: { (success) in
        })
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3, animations: {
            self.textViewBottomConstraint.constant = 10.0
        }, completion: { (success) in
        })
    }
    
    deinit {
        self.removeKeyboardNotification()
    }
    
    func openPicture() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    // setup for textview resizing
    fileprivate func addKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    fileprivate func removeKeyboardNotification() {
        IQKeyboardManager.shared().isEnabled = true
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    

    
    @IBAction func postPressed(_ sender: Any) {
        guard let image = postPhoto.image else { return }
        let postRef = database.reference(withPath: "posts").childByAutoId()
        guard let postId = postRef.key else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.1) else { return }
        guard let thumbnailImageData = image.jpegData(compressionQuality: 0.05) else { return }
        let fullRef = storage.reference(withPath: "\(self.uid)/full/\(postId)/jpeg")
        let thumbRef = storage.reference(withPath: "\(self.uid)/thumb/\(postId)/jpeg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        //let message = MDCSnackbarMessage()
        let myGroup = DispatchGroup()
        myGroup.enter()
        fullRef.putData(imageData, metadata: nil) { fullmetadata, error in
          if let error = error {
            //message.text = "Error uploading image"
            //MDCSnackbarManager.show(message)
            //self.button.isEnabled = true
            print("Error uploading image: \(error.localizedDescription)")
            return
          }

          fullRef.downloadURL(completion: { (url, error) in
            if let error = error {
              print(error.localizedDescription)
              return
            }
            if let url = url?.absoluteString {
              self.fullURL = url
            }
            myGroup.leave()
          })
        }
        myGroup.enter()
        thumbRef.putData(thumbnailImageData, metadata: metadata) { thumbmetadata, error in
          if let error = error {
            print("Error uploading thumbnail: \(error.localizedDescription)")
            return
          }
          thumbRef.downloadURL(completion: { (url, error) in
            if let error = error {
              print(error.localizedDescription)
              return
            }
            if let url = url?.absoluteString {
              self.thumbURL = url
            }
            myGroup.leave()
          })
        }

        myGroup.notify(queue: .main) {

          let data = ["full_url": self.fullURL, "full_storage_uri": fullRef.fullPath,
                      "thumb_url": self.thumbURL, "thumb_storage_uri": thumbRef.fullPath,
                      "text": self.postComment.text ?? "", "client": "ios",
                      "author": INUser.currentUser().author(), "timestamp": ServerValue.timestamp()] as [String: Any]
          postRef.setValue(data)
          postRef.root.updateChildValues(["people/\(self.uid)/posts/\(postId)": true, "feed/\(self.uid)/\(postId)": true])
          self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        postPhoto.image = image
    }
    
    
}





