//
//  TextView + Placeholder.swift
//  InstagramClone
//
//  Created by Nulrybek Karshyga on 8/12/20.
//  Copyright © 2020 Nulrybek Karshyga. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class TextViewWithPlaceHolderEnabled: UITextView {
    
    @IBInspectable var placeHolderTxt: String = ""
    @IBInspectable var placeHolderTxtColor: UIColor = .black
 
    var showingPlaceHolder: Bool = true

    override var text: String! {
        get {
            if showingPlaceHolder {
                return "   "
            } else { return super.text }
        }
        set { super.text = newValue }
    }
    
    override func resignFirstResponder() -> Bool {
        if text.isEmpty {
            showPlaceHolderText()
        }
        return super.resignFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        if showingPlaceHolder {
            text = nil
            showingPlaceHolder = false
            self.textColor = nil
        }
        return super.becomeFirstResponder()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if text.isEmpty {
            showPlaceHolderText()
        }
    }
    
    private func showPlaceHolderText() {
        showingPlaceHolder = true
        textColor = self.placeHolderTxtColor
        text = self.placeHolderTxt
    }
}




