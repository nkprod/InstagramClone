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
    @IBOutlet var readonlyWarningLabel: UILabel!
     let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)]
     let attributes2 = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)]
     var agreed = false

     lazy var disclaimer: MDCAlertController = {
       let alertController = MDCAlertController(title: nil, message: "I understand FriendlyPix is an application aimed at showcasing the Firebase platform capabilities, and should not be used with private or sensitive information. All FriendlyPix data and inactive accounts are regularly removed. I agree to the Terms of Service and Privacy Policy.")

       let acceptAction = MDCAlertAction(title: "I agree", emphasis: .high) { action in
         self.agreed = true
       }
       alertController.addAction(acceptAction)
       let termsAction = MDCAlertAction(title: "Terms") { action in
         UIApplication.shared.open(URL(string: "https://friendly-pix.com/terms")!,
                                   options: [:], completionHandler: { completion in
           self.present(alertController, animated: true, completion: nil)
         })
       }
       alertController.addAction(termsAction)
       let policyAction = MDCAlertAction(title: "Privacy") { action in
         UIApplication.shared.open(URL(string: "https://www.google.com/policies/privacy")!,
                                   options: [:], completionHandler: { completion in
           self.present(alertController, animated: true, completion: nil)
         })
       }
       alertController.addAction(policyAction)
       let colorScheme = MDCSemanticColorScheme()
       MDCAlertColorThemer.applySemanticColorScheme(colorScheme, to: alertController)
       return alertController
     }()

     override func viewDidAppear(_ animated: Bool) {
       super.viewDidAppear(animated)
       if (AppDelegate.euroZone) {
         readonlyWarningLabel.isHidden = false
       }
       if !agreed {
         self.present(disclaimer, animated: true, completion: nil)
       }
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
