//
//  EnterAmountViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class EnterAmountViewController: BaseViewController, UITextFieldDelegate {
	
	public var amount: Decimal?
	public var otherTitle: String?
	
	@IBOutlet var tfAmount: UITextField!
	@IBOutlet var lblTitle: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		lblTitle.text = otherTitle
		tfAmount.becomeFirstResponder()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	@IBAction func closeClick(_ sender: Any?) -> Void {
		performSegue(withIdentifier: unwindIdentifiers["enter-other-amount"]!, sender: self)
	}
	
	@IBAction func setAmount(_ sender: Any?) -> Void {
		amount = Decimal.init(string: tfAmount.text!.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
		performSegue(withIdentifier: unwindIdentifiers["enter-other-amount"]!, sender: self)
	}
	
	// UITextFieldDelegate
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return true
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		return true
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
		
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return true;
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		setAmount(nil)
		return true
	}
	
}
