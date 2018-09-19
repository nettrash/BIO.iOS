//
//  CreateWalletViewController.swift
//  bio
//
//  Created by Иван Алексеев on 23.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit

class CreateWalletViewController: BaseViewController, UITextFieldDelegate {
	
	@IBOutlet var textFieldSecret: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		textFieldSecret.text = NSUUID().uuidString
		textFieldSecret.becomeFirstResponder()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func createClick(_ sender: Any?) -> Void {
		registerWallet()
	}
	
	func registerWallet() -> Void {
		let app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
		app.model!.BIO!.initialize(textFieldSecret.text!)
		performSegue(withIdentifier: "create-pin", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "create-pin") {
			let dst = segue.destination as! SetPINViewController
			dst.unwindIdentifiers = self.unwindIdentifiers
		}
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
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		//let textFieldText: NSString = (textField.text ?? "") as NSString
		//let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
		
		return true;
	}
	
	override public func processUrlCommand() -> Void {
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		
		registerWallet()
		
		//		if (sibAddress.verify(textField.text)) {
		//			performSegue(withIdentifier: unwindIdentifiers["create-wallet"]!, sender: self)
		//		}
		
		return false
	}
	
}
