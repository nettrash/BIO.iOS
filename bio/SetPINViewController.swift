//
//  SetPINViewController.swift
//  bio
//
//  Created by Иван Алексеев on 23.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class SetPINViewController : BaseViewController, UITextFieldDelegate {
	
	var PIN0: String = ""
	var PIN1: String = ""
	
	@IBOutlet var tfPIN0: UITextField!
	@IBOutlet var tfPIN1: UITextField!
	@IBOutlet var tfPIN2: UITextField!
	@IBOutlet var tfPIN3: UITextField!
	@IBOutlet var lblMode: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		for v in self.view.subviews {
			if (v is UITextField) {
				v.layer.cornerRadius = 4
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		setupSetPIN()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupSetPIN() -> Void {
		PIN0 = ""
		PIN1 = ""
		lblMode.text = NSLocalizedString("setPIN0", comment: "setPIN0")
		tfPIN0.text = ""
		tfPIN1.text = ""
		tfPIN2.text = ""
		tfPIN3.text = ""
		tfPIN0.becomeFirstResponder()
	}
	
	// UITextFieldDelegate
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
		
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let textFieldText: NSString = (textField.text ?? "") as NSString
		let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
		if string == "" && txtAfterUpdate == "" && textField.text == "" {
			//Backspace
			if textField == self.tfPIN1 { PIN0 = ""; self.tfPIN0.text = ""; self.tfPIN0.becomeFirstResponder() }
			if textField == self.tfPIN2 { PIN0 = String(PIN0[String.Index(encodedOffset: 0)]); self.tfPIN1.text = ""; self.tfPIN1.becomeFirstResponder() }
			if textField == self.tfPIN3 { PIN0 = PIN0.substring(to: String.Index(encodedOffset: 2)); self.tfPIN2.text = ""; self.tfPIN2.becomeFirstResponder() }
			return false
		}
		if txtAfterUpdate.count != 1 { return false }
		if textField == tfPIN0 {
			if PIN0.count < 4 {
				tfPIN0.text = "0"
				PIN0 = PIN0 + txtAfterUpdate
			} else {
				tfPIN0.text = "1"
				PIN1 = PIN1 + txtAfterUpdate
			}
			tfPIN1.becomeFirstResponder()
			return false
		}
		if textField == tfPIN1 {
			if PIN0.count < 4 {
				tfPIN1.text = "0"
				PIN0 = PIN0 + txtAfterUpdate
			} else {
				tfPIN1.text = "1"
				PIN1 = PIN1 + txtAfterUpdate
			}
			tfPIN2.becomeFirstResponder()
			return false
		}
		if textField == tfPIN2 {
			if PIN0.count < 4 {
				tfPIN2.text = "0"
				PIN0 = PIN0 + txtAfterUpdate
			} else {
				tfPIN2.text = "1"
				PIN1 = PIN1 + txtAfterUpdate
			}
			tfPIN3.becomeFirstResponder()
			return false
		}
		if textField == tfPIN3 {
			if PIN1 == "" {
				tfPIN3.text = "0"
				PIN0 = PIN0 + txtAfterUpdate
				lblMode.text = NSLocalizedString("setPIN1", comment: "setPIN1")
				tfPIN0.text = ""
				tfPIN1.text = ""
				tfPIN2.text = ""
				tfPIN3.text = ""
				tfPIN0.becomeFirstResponder()
			} else {
				tfPIN3.text = "1"
				PIN1 = PIN1 + txtAfterUpdate
				if PIN0 == PIN1 {
					performSegue(withIdentifier: unwindIdentifiers["create-wallet"]!, sender: self)
				} else {
					setupSetPIN()
				}
			}
			return false
		}
		return false
	}
	
	override public func processUrlCommand() -> Void {
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return false
	}
	
}
