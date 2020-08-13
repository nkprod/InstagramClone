//
//  AppDelegate.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/6/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseCore
import FirebaseUI
import MaterialComponents
import UserNotifications
import FirebaseMessaging
import IQKeyboardManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate{
    
    let mdcMessage = MDCSnackbarMessage()
    let mdcAction = MDCSnackbarMessageAction()
    var window: UIWindow?
    lazy var database = Database.database()
    var blockedRef: DatabaseReference!
    var blockingRef: DatabaseReference!
    let gcmMessageIDKey = "gcm.message_id"
    var notificationGranted = false
    private var blocked = Set<String>()
    private var blocking = Set<String>()
    static var euroZone: Bool = {
      switch Locale.current.regionCode {
      case "CH", "AT", "IT", "BE", "LV", "BG", "LT", "HR", "LX", "CY", "MT", "CZ", "NL", "DK",
           "PL", "EE", "PT", "FI", "RO", "FR", "SK", "DE", "SI", "GR", "ES", "HU", "SE", "IE", "GB":
        return true
      default:
        return false
      }
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        IQKeyboardManager.shared().isEnabled = true
        // Adopt a FUIAuthDelegate protocol to receive callback
        if let uid = Auth.auth().currentUser?.uid {
            blockedRef = database.reference(withPath: "blocked/\(uid)")
            blockingRef = database.reference(withPath: "blocking/\(uid)")
            observeBlocks()
        }
        
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, _ in
              if granted {
                if let uid = Auth.auth().currentUser?.uid {
                  self.database.reference(withPath: "people/\(uid)/notificationEnabled").setValue(true)
                } else {
                  self.notificationGranted = true
                }
              }
          })
        } else {
          let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        authUI?.shouldAutoUpgradeAnonymousUsers = true

        let providers: [FUIAuthProvider] = AppDelegate.euroZone ? [FUIAnonymousAuth()] : [FUIGoogleAuth(), FUIAnonymousAuth()]
        //  ((Auth.auth().currentUser != nil) ? [FUIGoogleAuth()] as [FUIAuthProvider] : [FUIGoogleAuth(), FUIAnonymousAuth()//, FUIFacebookAuth
        //] as [FUIAuthProvider])
        authUI?.providers = providers
        return true

    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
      guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
        return false
      }
      return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }

    @available(iOS 8.0, *)
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }

    func handleOpenUrl(_ url: URL, sourceApplication: String?) -> Bool {
      return FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false
    }
    
    func observeBlocks() {
      blockedRef.observe(.childAdded) { self.blocked.insert($0.key) }
      blockingRef.observe(.childAdded) { self.blocking.insert($0.key) }
      blockedRef.observe(.childRemoved) { self.blocked.remove($0.key) }
      blockingRef.observe(.childRemoved) { self.blocking.remove($0.key) }
    }
    

    func isBlocked(_ snapshot: DataSnapshot) -> Bool {
        let author = snapshot.childSnapshot(forPath: "author/uid").value as! String
        if blocked.contains(author) || blocking.contains(author) {
          return true
        }
        return false
      }

      func isBlocked(by person: String) -> Bool {
        return blocked.contains(person)
      }

      func isBlocking(_ person: String) -> Bool {
        return blocking.contains(person)
      }
    




    // Firebase Notification

      func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        switch error {
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue:
          print("User cancelled sign-in")
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.mergeConflict.rawValue:
          MDCSnackbarManager.show(MDCSnackbarMessage(text: "This identity is already associated with a different user account."))
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.providerError.rawValue:
          MDCSnackbarManager.show(MDCSnackbarMessage(text: "There is an error with Google Sign in."))
        case .some(let error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil:
          MDCSnackbarManager.show(MDCSnackbarMessage(text: "\(error.userInfo[NSUnderlyingErrorKey]!)"))
        case .some(let error):
          MDCSnackbarManager.show(MDCSnackbarMessage(text: error.localizedDescription))
        case .none:
          if let user = authDataResult?.user {
            signed(in: user)
          }
        }
      }

      func signOut() {
        blockedRef.removeAllObservers()
        blockingRef.removeAllObservers()
        blocked.removeAll()
        blocking.removeAll()
      }

      func signed(in user: User) {
        blockedRef = database.reference(withPath: "blocked/\(user.uid)")
        blockingRef = database.reference(withPath: "blocking/\(user.uid)")
        observeBlocks()
        let imageUrl = user.isAnonymous ? "" : user.providerData[0].photoURL?.absoluteString

        
        // If the main profile Pic is an expiring facebook profile pic URL we'll update it automatically to use the permanent graph API URL.
    //    if let url = imageUrl, url.contains("lookaside.facebook.com") || url.contains("fbcdn.net") {
    //      let facebookUID = user.providerData.first { (userinfo) -> Bool in
    //        return userinfo.providerID == "facebook.com"
    //      }?.providerID
    //      if let facebook = facebookUID {
    //        imageUrl = "https://graph.facebook.com/\(facebook)/picture?type=large"
    //      }
    //    }
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
    

    func showContent(_ content: UNNotificationContent) {
      mdcMessage.text = content.body
      mdcAction.title = content.title
      mdcMessage.duration = 10_000
      mdcAction.handler = {
        
        // MARK: Change
        guard let feed = self.window?.rootViewController?.children[0].children[0] as? FeedCollectionViewController else { return }
        let userId = content.categoryIdentifier.components(separatedBy: "/user/")[1]
        feed.showProfile(INUser(dictionary: ["uid": userId]))
      }
      mdcMessage.action = mdcAction
      MDCSnackbarManager.show(mdcMessage)
    }

    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
      return AuthPickerViewController(nibName: "AuthPickerViewController", bundle: Bundle.main, authUI: authUI)
    }
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "InstagramClone")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}



@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {

  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
    showContent(notification.request.content)
    completionHandler([])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    showContent(response.notification.request.content)
    completionHandler()
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    Database.database().reference(withPath: "/people/\(uid)/notificationTokens/\(fcmToken)").setValue(true)
  }

  // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
  // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
  func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    let data = remoteMessage.appData
    //showAlert(data)
  }
}

