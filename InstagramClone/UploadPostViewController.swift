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

class UploadPostViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate {

    @IBOutlet weak var postPhoto: UIImageView!
    @IBOutlet weak var postComment: UITextView!
    
    // Firebase realtime db
    lazy var database = Database.database()
    lazy var storage = Storage.storage()
    
    let uid = Auth.auth().currentUser!.uid
    var fullURL = ""
    var thumbURL = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        openPicture()

        // Do any additional setup after loading the view.
    }
    func openPicture() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
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



