//
//  FeedDetailView.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import Foundation

class FeedDetailView: UIViewController {

    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    var imageURL: URL? = nil
    var comment: String? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let imageURL = imageURL else { return }
        postImageView.load(url: imageURL)
        commentTextView.text = comment
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func dismissPressed(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
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

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
