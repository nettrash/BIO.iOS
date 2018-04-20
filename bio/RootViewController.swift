//
//  RootViewController.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit

class RootViewController: BaseViewController {
	
	var Checked: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		let app = UIApplication.shared.delegate as! AppDelegate
		if (app.model!.Addresses.count < 1) {
			performSegue(withIdentifier: "create-wallet", sender: self)
		} else {
			if app.model!.existsPIN() && !Checked {
				performSegue(withIdentifier: "check-pin", sender: self)
			} else {
				Checked = false
				performSegue(withIdentifier: "balance", sender: self)
			}
		}
	}
	
	override public func processUrlCommand() -> Void {
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "create-wallet") {
			let dst = segue.destination as! CreateWalletViewController
			dst.unwindIdentifiers["create-wallet"] = "unwindSegueToRoot"
		}
		if (segue.identifier == "check-pin") {
			let dst = segue.destination as! CheckPINViewController
			dst.unwindIdentifiers["check-pin"] = "unwindSegueToRoot"
		}
	}
	
	@IBAction func unwindToRoot(unwindSegue: UIStoryboardSegue) {
		if (unwindSegue.source is SetPINViewController) {
			let app = UIApplication.shared.delegate as! AppDelegate
			let src = unwindSegue.source as! SetPINViewController
			app.model!.storeWallet(app.model!.BIO!, true, .Incoming)
			app.model!.setPIN(src.PIN0)
		}
		if (unwindSegue.source is CheckPINViewController) {
			let src = unwindSegue.source as! CheckPINViewController
			Checked = src.Checked
		}
	}

}

