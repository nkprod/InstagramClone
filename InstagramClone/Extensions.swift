//
//  Extensions.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/11/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import Foundation
import SDWebImage
import Firebase
import MaterialComponents

extension UIImage {
  var circle: UIImage? {
    let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
    //let square = CGSize(width: 36, height: 36)
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
    imageView.contentMode = .scaleAspectFill
    imageView.image = self
    imageView.layer.cornerRadius = square.width / 2
    imageView.layer.masksToBounds = true
    UIGraphicsBeginImageContext(imageView.bounds.size)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    imageView.layer.render(in: context)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result
  }

  func resizeImage(_ dimension: CGFloat) -> UIImage {
    var width: CGFloat
    var height: CGFloat
    var newImage: UIImage

    let size = self.size
    let aspectRatio = size.width / size.height

    if aspectRatio > 1 {                            // Landscape image
      width = dimension
      height = dimension / aspectRatio
    } else {                                        // Portrait image
      height = dimension
      width = dimension * aspectRatio
    }

    if #available(iOS 10.0, *) {
      let renderFormat = UIGraphicsImageRendererFormat.default()
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
      newImage = renderer.image { _ in
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      }
    } else {
      UIGraphicsBeginImageContext(CGSize(width: width, height: height))
      self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
    }
    return newImage
  }

  func resizeImage(_ dimension: CGFloat, with quality: CGFloat) -> Data? {
    return resizeImage(dimension).jpegData(compressionQuality: quality)
  }

  static func circleImage(with url: URL, to imageView: UIImageView) {
    let urlString = url.absoluteString
    let trace = Performance.startTrace(name: "load_profile_pic")
    if let image = SDImageCache.shared.imageFromCache(forKey: urlString) {
      trace?.incrementMetric("cache", by: 1)
      trace?.stop()
      imageView.image = image
      return
    }
    SDWebImageDownloader.shared.downloadImage(with: url,
                                                options: .highPriority, progress: nil) { image, _, error, _ in
      trace?.incrementMetric("download", by: 1)
      trace?.stop()

      if let error = error {
        print(error)
        return
      }
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared.store(circleImage, forKey: urlString, completion: nil)
        imageView.image = circleImage
      }
    }
  }

  static func circleButton(with url: URL, to button: UIBarButtonItem) {
    let urlString = url.absoluteString
    let trace = Performance.startTrace(name: "load_profile_pic")
    if let image = SDImageCache.shared.imageFromCache(forKey: urlString) {
      trace?.incrementMetric("cache", by: 1)
      trace?.stop()
      button.image = image.resizeImage(36).withRenderingMode(.alwaysOriginal)
      return
    }
    SDWebImageDownloader.shared.downloadImage(with: url, options: .highPriority, progress: nil) { image, _, _, _ in
      trace?.incrementMetric("download", by: 1)
      trace?.stop()
      if let image = image {
        let circleImage = image.circle
        button.tintColor = .red
        SDImageCache.shared.store(circleImage, forKey: urlString, completion: nil)
        button.image = circleImage?.resizeImage(36).withRenderingMode(.alwaysOriginal)
      }
    }
  }
}

extension Date {

  func timeAgo() -> String {

    let interval = Calendar.current.dateComponents([.year, .day, .hour, .minute, .second], from: self, to: Date())

    if let year = interval.year, year > 0 {
      return DateFormatter.localizedString(from: self, dateStyle: .long, timeStyle: .none)
    } else if let day = interval.day, day > 6 {
      let format = DateFormatter.dateFormat(fromTemplate: "MMMMd", options: 0, locale: NSLocale.current)
      let formatter = DateFormatter()
      formatter.dateFormat = format
      return formatter.string(from: self)
    } else if let day = interval.day, day > 0 {
      return day == 1 ? "\(day)" + " " + "day ago" :
        "\(day)" + " " + "days ago"
    } else if let hour = interval.hour, hour > 0 {
      return hour == 1 ? "\(hour)" + " " + "hour ago" :
        "\(hour)" + " " + "hours ago"
    } else if let minute = interval.minute, minute > 0 {
      return minute == 1 ? "\(minute)" + " " + "minute ago" :
        "\(minute)" + " " + "minutes ago"
    } else if let second = interval.second, second > 0 {
      return second == 1 ? "\(second)" + " " + "second ago" :
        "\(second)" + " " + "seconds ago"
    } else {
      return "just now"
    }
  }
}

extension MDCSelfSizingStereoCell {

  static let attributes = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body2)]
  static let attributes2 = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)]

  func populateContent(from: INUser, text: String, date: Date, index: Int) {
    let attrText = NSMutableAttributedString(string: from.fullname , attributes: MDCSelfSizingStereoCell.attributes)
    attrText.append(NSAttributedString(string: " " + text, attributes: MDCSelfSizingStereoCell.attributes2))
    attrText.addAttribute(.paragraphStyle, value: MDCSelfSizingStereoCell.paragraphStyle, range: NSMakeRange(0, attrText.length))
    titleLabel.attributedText = attrText
    titleLabel.accessibilityLabel = "\(from.fullname) said, \(text)"
    if let profilePictureURL = from.profilePictureURL {
      UIImage.circleImage(with: profilePictureURL, to: leadingImageView)
      leadingImageView.accessibilityLabel = from.fullname
      leadingImageView.accessibilityHint = "Double-tap to open profile."
    }
    leadingImageView.tag = index
    titleLabel.tag = index
    detailLabel.text = date.timeAgo()
  }


  static let paragraphStyle = { () -> NSMutableParagraphStyle in
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 2
    return style
  }()
}

extension UIColor {
    func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor.init(red: red/255, green: green/255, blue: blue/255, alpha: 1.0)
    }
    
    static let backgroundColor = UIColor().rgb(red: 25, green: 25, blue: 25)
    static let mainBlueTint = UIColor().rgb(red: 17, green: 154, blue: 237)
}

extension UIView {
    func anchorItem(top: NSLayoutYAxisAnchor? = nil,
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

    func centerItemInX(inView view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    func centerItemInY(inView view: UIView, leftAnchor: NSLayoutXAxisAnchor? = nil,
                 paddingLeft: CGFloat = 0, constant: CGFloat = 0) {

        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
//
//        if let left = leftAnchor {
//            anchor(left: left, paddingLeft: paddingLeft)
//        }
    }

    func instantiateView(image: UIImage, textField: UITextField? = nil, segmentedControl:  UISegmentedControl? = nil) -> UIView {
        let view = UIView()

        let imageView = UIImageView()
        imageView.image = image
        imageView.alpha = 0.87
        view.addSubview(imageView)


        if let textField = textField{
            imageView.centerItemInY(inView: view)
            imageView.anchorItem(left: view.leftAnchor, paddingLeft: 8, width: 24, height: 24)
            view.addSubview(textField)
            textField.centerItemInY(inView: view)
            textField.anchorItem(left: imageView.rightAnchor, bottom: view.bottomAnchor,right: view.rightAnchor, paddingLeft: 8, paddingBottom: 8)
        }

        if let sc = segmentedControl{
            imageView.anchorItem(top: view.topAnchor, left: view.leftAnchor,paddingTop: -8, paddingLeft: 8, width: 24, height: 24)
            view.addSubview(sc)
            sc.anchorItem(top:imageView.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop:8, paddingLeft: 8, paddingRight: 8)
            sc.centerItemInY(inView: view, constant: 8)
        }

        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        view.addSubview(separatorView)
        separatorView.anchorItem(left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingLeft: 8, height: 2.75 )
        return view
    }


}

extension UITextField {
    func textField(withPlaceholder placeholder: String, isSecureTextEntry: Bool) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.keyboardAppearance = .dark
        textField.isSecureTextEntry = isSecureTextEntry
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        return textField
    }
}
