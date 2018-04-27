//
//  PINTextField.swift
//  bio
//
//  Created by Иван Алексеев on 23.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class PINTextField: UITextField {
	
	override func deleteBackward() {
		let shouldDismiss = self.text!.count == 0
		
		super.deleteBackward()
		
		if (shouldDismiss) {
			let _ = self.delegate?.textField!(self, shouldChangeCharactersIn: NSRange.init(location: 0, length: 0), replacementString: "")
		}
	}
}
