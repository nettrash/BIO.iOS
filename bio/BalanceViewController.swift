//
//  BalanceViewController.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit
import CardIO

class BalanceViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, ModelRootDelegate, CardIOPaymentViewControllerDelegate, UITextFieldDelegate {
	
	let app = UIApplication.shared.delegate as! AppDelegate
	
	var historyItemsCount: Int = 0
	
	@IBOutlet var lblBalance: UILabel!
	@IBOutlet var scDimension: UISegmentedControl!
	@IBOutlet var btnAction: UIButton!
	@IBOutlet var imgActionInfo: UIImageView!
	@IBOutlet var imgVertical: UIImageView!
	@IBOutlet var btnAddAddress: UIButton!
	@IBOutlet var btnRequisites: UIButton!
	@IBOutlet var btnBuy: UIButton!
	@IBOutlet var tblHistory: UITableView!
	@IBOutlet var tblRate: UITableView!
	@IBOutlet var lblNoOps: UILabel!
	@IBOutlet var vBuy: UIView!
	@IBOutlet var vSell: UIView!
	@IBOutlet var tfCardNumber_Buy: UITextField!
	@IBOutlet var tfCardNumber_Sell: UITextField!
	@IBOutlet var tfAmount_Sell: UITextField!
	@IBOutlet var tfAmount_Buy: UITextField!
	@IBOutlet var tfExp_Buy: UITextField!
	@IBOutlet var tfCVV_Buy: UITextField!
	@IBOutlet var btnBIOSell: UIButton!
	@IBOutlet var btnBIOBuy: UIButton!
	@IBOutlet var vWait: UIView!
	@IBOutlet var lblSellRate: UILabel!
	@IBOutlet var lblBuyRate: UILabel!
	@IBOutlet var btnSettings: UIButton!
	
	var refreshControl: UIRefreshControl!
	var refreshControlRates: UIRefreshControl!
	
	var selectedSegmentIndex = 0
	
	//Sell
	var amountSell: Double = 0
	
	//Buy
	var amountBuy: Double = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.vWait.isHidden = true
		
		self.lblNoOps.isHidden = true
		self.tblHistory.isHidden = false
		self.tblRate.isHidden = true
		self.vBuy.isHidden = true
		self.vSell.isHidden = true
		
		self.roundCorners(self.vBuy)
		self.roundCorners(self.vSell)
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		refreshControl.tintColor = UIColor.white
		tblHistory.addSubview(refreshControl)
		
		refreshControlRates = UIRefreshControl()
		refreshControlRates.addTarget(self, action: #selector(refreshRates), for: .valueChanged)
		refreshControlRates.tintColor = UIColor.white
		tblRate.addSubview(refreshControlRates)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		historyItemsCount = 0
		selectedSegmentIndex = self.scDimension.selectedSegmentIndex
		
		DispatchQueue.main.async {
			self.app.model!.delegate = self
			self.prepareActionMenu()
			self.segmentControlValueChanged(self)
			if self.app.model!.buyOpKey != "" {
				self.app.model!.checkBuyOp()
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
			self.app.checkAvailableUpdate()
		})
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			if self.view.frame.origin.y == 0 {
				self.view.frame.origin.y -= keyboardSize.height / 2
			}
		}
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
			if self.view.frame.origin.y != 0 {
				self.view.frame.origin.y = 0//+= keyboardSize.height / 2
			}
		}
	}
	
	@objc func refresh(sender:AnyObject?) {
		DispatchQueue.main.async {
			self.app.model!.refresh()
		}
	}
	
	@objc func refreshRates(sender:AnyObject?) {
		DispatchQueue.main.async {
			self.app.model!.refreshRates()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		imgActionInfo.alpha = 1.0
		/*if segue.identifier == "add-address" {
			let dst = segue.destination as! AddAddressViewController
			dst.availibleCancel = true;
			dst.unwindIdentifiers["add-address"] = "unwindSegueToBalance"
		}*/
		if segue.identifier == "receive-bio" {
			let dst = segue.destination as! ReceiveViewController
			dst.unwindIdentifiers["receive-bio"] = "unwindSegueToBalance"
		}
		if segue.identifier == "history-bio" {
			let dst = segue.destination as! HistoryViewController
			dst.unwindIdentifiers["history-bio"] = "unwindSegueToBalance"
		}
		if segue.identifier == "send-bio" {
			let dst = segue.destination as! SendViewController
			dst.unwindIdentifiers["send-bio"] = "unwindSegueToBalance"
			if sender is URLComponents {
				let components = sender as! URLComponents
				dst.components = components
			}
		}
		if segue.identifier == "3ds-auth" {
			let dst = segue.destination as! WebViewController
			dst.unwindIdentifiers["3ds-auth"] = "unwindSegueToBalance"
		}
		if segue.identifier == "settings-bio" {
			let dst = segue.destination as! SettingsViewController
			dst.unwindIdentifiers["settings-bio"] = "unwindSegueToBalance"
			if sender is URL {
				let url = sender as! URL
				dst.fileUrl = url
			}
		}
	}
	
	@IBAction func unwindToBalance(unwindSegue: UIStoryboardSegue) {
		/*if (unwindSegue.source is AddAddressViewController) {
			//let src = unwindSegue.source as! AddAddressViewController
			//app.model!.add(src.textFieldAddress.text!)
		}*/
		if (unwindSegue.source is ReceiveViewController) {
			//let src = unwindSegue.source as! ReceiveViewController
			//app.model!.add(src.textFieldAddress.text!)
		}
		if (unwindSegue.source is SendViewController) {
			//let src = unwindSegue.source as! SendViewController
			//app.model!.add(src.textFieldAddress.text!)
		}
		if (unwindSegue.source is HistoryViewController) {
			//let src = unwindSegue.source as! HistoryViewController
			//app.model!.add(src.textFieldAddress.text!)
		}
		if (unwindSegue.source is WebViewController) {
			//let src = unwindSegue.source as! WebViewController
		}
		if (unwindSegue.source is ScanViewController) {
			//let src = unwindSegue.source as! ScanViewController
		}
	}
	
	@IBAction func addAddress(_ sender: Any?) {
		performSegue(withIdentifier: "add-address", sender: self)
	}
	
	@IBAction func receiveBIO(_ sender: Any?) {
		performSegue(withIdentifier: "receive-bio", sender: self)
	}
	
	@IBAction func sendBIO(_ sender: Any?) {
		performSegue(withIdentifier: "send-bio", sender: self)
	}
	
	@IBAction func historyBIO(_ sender: Any?) {
		performSegue(withIdentifier: "history-bio", sender: self)
	}
	
	@IBAction func settingsBIO(_ sender: Any?) {
		performSegue(withIdentifier: "settings-bio", sender: self)
	}
	
	@IBAction func scanCad(_ sender: Any?) {
		let ciopvc = CardIOPaymentViewController.init(paymentDelegate: self)!
		ciopvc.disableManualEntryButtons = true
		ciopvc.useCardIOLogo = true
		ciopvc.scanExpiry = true
		ciopvc.suppressScanConfirmation = true
		ciopvc.suppressScannedCardImage = true
		present(ciopvc, animated: true, completion: nil)
	}
	
	@IBAction func segmentControlValueChanged(_ sender: Any?) {
		self.view.endEditing(true)
		self.lblNoOps.isHidden = historyItemsCount > 0 || self.scDimension.selectedSegmentIndex > 0
		if scDimension.selectedSegmentIndex > selectedSegmentIndex {
			flipRight = true
		} else {
			flipRight = false
		}
		selectedSegmentIndex = scDimension.selectedSegmentIndex
		switch scDimension.selectedSegmentIndex {
		case 0:
			if !self.app.model!.isHistoryRefresh && sender != nil {
				self.tblHistory.setContentOffset(CGPoint(x: 0, y: -self.refreshControl!.frame.size.height - self.view.safeAreaInsets.bottom), animated: true)
				refresh(sender: nil)
			}
			if !tblRate.isHidden {
				flip(tblRate, tblHistory)
			}
			if !vBuy.isHidden {
				flip(vBuy, tblHistory)
			}
			if !vSell.isHidden {
				flip(vSell, tblHistory)
			}
		case 1:
			//Курсы
			if !self.app.model!.isCurrentRatesRefresh {
				self.tblRate.setContentOffset(CGPoint(x: 0, y: -self.refreshControlRates!.frame.size.height - self.view.safeAreaInsets.bottom), animated: true)
				self.app.model!.refreshRates()
			}
			if !tblHistory.isHidden {
				flip(tblHistory, tblRate)
			}
			if !vBuy.isHidden {
				flip(vBuy, tblRate)
			}
			if !vSell.isHidden {
				flip(vSell, tblRate)
			}
		case 2:
			//Купить
			self.lblBuyRate.text = "...";
			self.app.model!.buyRate = 0
			self.app.model!.getBuyRate(app.model!.currency.rawValue)
			updateBuyAmount(tfAmount_Buy.text ?? "")
			if !tblHistory.isHidden {
				flip(tblHistory, vBuy)
			}
			if !tblRate.isHidden {
				flip(tblRate, vBuy)
			}
			if !vSell.isHidden {
				flip(vSell, vBuy)
			}
		case 3:
			//Продать
			self.lblSellRate.text = "...";
			self.app.model!.sellRate = 0
			self.app.model!.getSellRate(app.model!.currency.rawValue)
			updateSellAmount(tfAmount_Sell.text ?? "")
			if !tblHistory.isHidden {
				flip(tblHistory, vSell)
			}
			if !tblRate.isHidden {
				flip(tblRate, vSell)
			}
			if !vBuy.isHidden {
				flip(vBuy, vSell)
			}
		default:
			if !tblRate.isHidden {
				flip(tblRate, tblHistory)
			}
			if !vBuy.isHidden {
				flip(vBuy, tblHistory)
			}
			if !vSell.isHidden {
				flip(vSell, tblHistory)
			}
			refreshBalanceView()
		}
	}
	
	func setButtonText(_ btn: UIButton!, _ text: String!) -> Void {
		UIView.performWithoutAnimation {
			btn.setTitle(text, for: .application)
			btn.setTitle(text, for: .disabled)
			btn.setTitle(text, for: .focused)
			btn.setTitle(text, for: .highlighted)
			btn.setTitle(text, for: .normal)
			btn.setTitle(text, for: .reserved)
			btn.setTitle(text, for: .selected)
			btn.layoutIfNeeded()
		}
	}
	
	func refreshBalanceView() {
		switch app.model!.Dimension {
		case .BIO:
			lblBalance.text = String(format: "%.2f", app.model!.Balance)
		case .mBIO:
			lblBalance.text = String(format: "%.2f", app.model!.Balance * 1000)
		case .µBIO:
			lblBalance.text = String(format: "%.2f", app.model!.Balance * 1000 * 1000)
		case .bioshi:
			lblBalance.text = String(format: "%.0f", app.model!.Balance * 1000 * 1000 * 100)
		}
	}
	
	@IBAction func refreshBalanceClick(_ sender: Any?) {
		DispatchQueue.main.async {
			self.app.model!.refresh()
		}
	}
	
	@IBAction func toggleMenu(_ sender: Any?) {
		UIView.animate(withDuration: 0.25, animations: { () -> Void in
			self.btnAction.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.25)
		}, completion: { (_ success: Bool) -> Void in
			UIView.animate(withDuration: 0.20, animations: { () -> Void in
				self.btnAction.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.50)
			}, completion: { (_ success: Bool) -> Void in
				UIView.animate(withDuration: 0.15, animations: { () -> Void in
					self.btnAction.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 1)
					self.btnAddAddress.alpha = self.btnAddAddress.alpha == 0 ? 1 : 0
					self.imgVertical.alpha = self.imgVertical.alpha == 0 ? self.btnAddAddress.alpha : 0
				}, completion: { (_ success: Bool) -> Void in
					UIView.animate(withDuration: 0.10, animations: { () -> Void in
						self.btnAction.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 1.50)
						self.btnRequisites.alpha = self.btnRequisites.alpha == 0 ? 1 : 0
					}, completion: { (_ success: Bool) -> Void in
						UIView.animate(withDuration: 0.05, animations: { () -> Void in
							self.btnAction.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2)
							self.imgActionInfo.alpha = self.imgActionInfo.alpha == 0 ? 1 : 0
							self.btnBuy.alpha = self.btnBuy.alpha == 0 ? 1 : 0
							self.imgVertical.alpha = self.imgVertical.alpha == 0 ? self.btnAddAddress.alpha : self.imgVertical.alpha
							self.btnSettings.alpha = self.imgVertical.alpha
							if self.btnRequisites.frame.origin.y < self.tblHistory.frame.origin.y + 157 {
								if self.imgVertical.alpha == 0 {
									self.tblHistory.isHidden = self.scDimension.selectedSegmentIndex != 0
									self.tblRate.isHidden = self.scDimension.selectedSegmentIndex != 1
									self.vBuy.isHidden = self.scDimension.selectedSegmentIndex != 2
									self.vSell.isHidden = self.scDimension.selectedSegmentIndex != 3
								} else {
									self.tblHistory.isHidden = true
									self.tblRate.isHidden = true
									self.vBuy.isHidden = true
									self.vSell.isHidden = true
								}
							}
						}, completion: { (_ success: Bool) -> Void in
							
						})
					})
				})
			})
		})
	}
	
	@IBAction func btnBIOSellClick(_ sender: Any?) -> Void {
		self.view.endEditing(true)
		amountSell = Double(self.tfAmount_Sell.text!.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)) ?? 0
		if self.tfCardNumber_Sell.text!.count > 0 && self.tfCardNumber_Sell.text!.luhnCheck() && app.model!.Balance > amountSell && amountSell > 0 && amountSell * app.model!.sellRate >= 50 {
			app.model!.sell(app.model!.currency.rawValue, amountSell, amountSell * app.model!.sellRate, self.tfCardNumber_Sell.text!)
			self.tfCardNumber_Sell.text = ""
			self.tfAmount_Sell.text = ""
			amountSell = 0
			self.tfCardNumber_Sell.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7)
			self.tfAmount_Sell.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7)
			setButtonText(self.btnBIOSell, NSLocalizedString("EmptySellButtonText", comment: "EmptySellButtonText"))
		} else {
			let alert = UIAlertController.init(title: NSLocalizedString("ErrorStartSell", comment: "Ошибка"), message: NSLocalizedString("ErrorStartSellMessage", comment: "Ошибка"), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	@IBAction func btnBIOBuyClick(_ sender: Any?) -> Void {
		self.view.endEditing(true)
		amountBuy = Double(self.tfAmount_Buy.text!.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)) ?? 0
		if self.tfCardNumber_Buy.text!.count > 0 && self.tfCardNumber_Buy.text!.luhnCheck() && amountBuy > 0 {
			app.model!.buy(app.model!.currency.rawValue, amountBuy, amountBuy * Double(1) / app.model!.buyRate, self.tfCardNumber_Buy.text!, self.tfExp_Buy.text!, self.tfCVV_Buy.text!)
			self.tfCardNumber_Buy.text = ""
			self.tfAmount_Buy.text = ""
			self.tfExp_Buy.text = ""
			self.tfCVV_Buy.text = ""
			amountBuy = 0
			self.tfCardNumber_Buy.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7)
			self.tfAmount_Buy.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7)
			setButtonText(self.btnBIOBuy, NSLocalizedString("EmptyBuyButtonText", comment: "EmptyBuyButtonText"))
		} else {
			let alert = UIAlertController.init(title: NSLocalizedString("ErrorStartSell", comment: "Ошибка"), message: NSLocalizedString("ErrorStartSellMessage", comment: "Ошибка"), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	private func prepareActionMenu() {
		btnAddAddress.alpha = 0
		btnRequisites.alpha = 0
		btnBuy.alpha = 0
		btnSettings.alpha = 0
		imgVertical.alpha = 0
		self.tblHistory.isHidden = self.scDimension.selectedSegmentIndex != 0
		self.tblRate.isHidden = self.scDimension.selectedSegmentIndex != 1
		self.vBuy.isHidden = self.scDimension.selectedSegmentIndex != 2
		self.vSell.isHidden = self.scDimension.selectedSegmentIndex != 3
		/*
		self.btnAddAddress.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -0.5)
		self.btnRequisites.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -0.25)
		
		let actionFrame = self.btnAction.frame
		
		var frameAdd = self.btnAddAddress.frame
		frameAdd.origin = CGPoint(x: actionFrame.origin.x, y: actionFrame.origin.y - 48)
		self.btnAddAddress.frame = frameAdd
		
		var frameReq = self.btnRequisites.frame
		frameReq.origin = CGPoint(x: 100, y: 100)//(x: actionFrame.origin.x + 48, y: actionFrame.origin.y - 48)
		self.btnRequisites.frame = frameReq
		
		var frameBuy = self.btnBuy.frame
		frameBuy.origin = CGPoint(x: actionFrame.origin.x + 48, y: actionFrame.origin.y)
		self.btnBuy.frame = frameBuy*/
	}
	
	//UITaleViewDataSourceDelegate
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1;
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableView == tblHistory ? historyItemsCount : app.model!.CurrentRates.Items.count
	}
	
	private func _historyCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row < app.model!.MemoryPool.Items.count {
			let item = app.model!.MemoryPool.Items.sorted(by: { (_ a: MemPoolItem, _ b: MemPoolItem) -> Bool in
				a.seconds ?? 0 > b.seconds ?? 0
			})[indexPath.row]
			if item.isInput {
				let cell = tableView.dequeueReusableCell(withIdentifier: "MemPoolIn", for: indexPath)
				
				cell.detailTextLabel?.text = "+ " + item.getAmount(app.model!.Dimension)
				cell.textLabel?.text = item.getSeconds()
				
				return cell
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "MemPoolOut", for: indexPath)
				
				cell.detailTextLabel?.text = "- " + item.getAmount(app.model!.Dimension)
				cell.textLabel?.text = item.getSeconds()
				
				return cell
			}
		}
		let item = app.model!.HistoryItems.Items.sorted(by: { (_ a: HistoryItem, _ b: HistoryItem) -> Bool in
			a.date > b.date
		})[indexPath.row-app.model!.MemoryPool.Items.count]
		switch item.type {
		case .Incoming:
			let cell = tableView.dequeueReusableCell(withIdentifier: "IncomingTransaction", for: indexPath)
			
			cell.detailTextLabel?.text = "+ " + item.getAmount(app.model!.Dimension)
			cell.textLabel?.text = item.getDate()
			
			return cell
		case .Outgoing:
			let cell = tableView.dequeueReusableCell(withIdentifier: "OutgoingTransaction", for: indexPath)
			
			cell.detailTextLabel?.text = "- " + item.getAmount(app.model!.Dimension)
			cell.textLabel?.text = item.getDate()
			
			return cell
		case .Unknown:
			let cell = tableView.dequeueReusableCell(withIdentifier: "UnknownTransaction", for: indexPath)
			
			cell.detailTextLabel?.text = "? " + item.getAmount(app.model!.Dimension)
			cell.textLabel?.text = item.getDate()
			
			return cell
		}
	}
	
	private func _rateCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
		let item = app.model!.CurrentRates.Items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "RateInfo", for: indexPath)
		cell.textLabel?.text = "1 BIO"
		cell.detailTextLabel?.text = "~ " + (item.Currency! == "RUB" ? String(format: "%.2f", item.Rate!) : String(format: "%.8f", item.Rate!)) + " " + item.Currency!
		return cell
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if tableView == tblHistory {
			return _historyCell(tableView, indexPath)
		}
		
		if tableView == tblRate {
			return _rateCell(tableView, indexPath)
		}
		
		return UITableViewCell()
	}
	
	//UITableViewDelegate
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if tableView == tblRate { return 40 }
		return 44
	}
	
	//ModelRootDelegate
	func startBalanceUpdate() {
		DispatchQueue.main.async {
			self.lblNoOps.isHidden = true
		}
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.35, animations: { () -> Void in
				self.lblBalance.alpha = 0.4
				self.lblBalance.font = self.lblBalance.font.withSize(18)
				UIView.transition(with: self.lblBalance,
								  duration: 0.35,
								  options: UIViewAnimationOptions.transitionFlipFromTop,
								  animations: { [weak self] in
									self?.lblBalance.text = NSLocalizedString("reloadBalance", comment: "")
					}, completion: nil)
			}, completion: { (_ success: Bool) -> Void in })
		}
	}
	
	func stopBalanceUpdate(error: String?) {
		if error != nil { showError(error: error!) }
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.35, animations: { () -> Void in
				self.lblBalance.alpha = 1
				self.lblBalance.font = self.lblBalance.font.withSize(56)
				UIView.transition(with: self.lblBalance,
								  duration: 0.35,
								  options: UIViewAnimationOptions.transitionFlipFromBottom,
								  animations: { [weak self] in
									self?.refreshBalanceView()
									self?.processUrlCommand()
					}, completion: nil)
			}, completion: { (_ success: Bool) -> Void in })
		}
	}
	
	func startHistoryUpdate() {
		DispatchQueue.main.async {
			self.app.model!.HistoryItems.Items = []
			self.historyItemsCount = 0
			self.tblHistory.reloadData()
			self.refreshControl.beginRefreshing()
		}
	}
	
	func stopHistoryUpdate() {
		DispatchQueue.main.sync {
			self.vWait.isHidden = true
		}
		DispatchQueue.main.async {
			self.scDimension.selectedSegmentIndex = 0
			self.segmentControlValueChanged(nil)
			self.refreshControl.endRefreshing()
			self.historyItemsCount = self.app.model!.HistoryItems.Items.count + self.app.model!.MemoryPool.Items.count
			if self.historyItemsCount > 3 { self.historyItemsCount = 3 }
			self.tblHistory.reloadData()
			self.lblNoOps.isHidden = self.historyItemsCount > 0 || self.scDimension.selectedSegmentIndex > 0
		}
	}
	
	func unspetData(_ unspent: Unspent) {
		
	}
	
	func broadcastTransactionResult(_ result: Bool, _ txid: String?, _ message: String?) {
		//		DispatchQueue.main.sync { self.vWait.isHidden = true }
		if result {
			let alert = UIAlertController.init(title: NSLocalizedString("SuccessSend", comment: "Успех"), message: NSLocalizedString("SuccessSendMessage", comment: "Success") + txid!, preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: nil))
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("Share", comment: "Поделться"), style: UIAlertActionStyle.default, handler: { _ in self.shareText(txid!) }))
			self.present(alert, animated: true, completion: nil)
			
		} else {
			//Добавить удаление последнего адреса Change
			let alert = UIAlertController.init(title: NSLocalizedString("ErrorSend", comment: "Ошибка"), message: NSLocalizedString("ErrorSendMessage", comment: "Ошибка") + (message ?? ""), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func startCurrentRatesUpdate() {
		DispatchQueue.main.async {
			self.app.model!.HistoryItems.Items = [];
			self.tblRate.reloadData()
			self.refreshControlRates.beginRefreshing()
		}
	}
	
	func stopCurrentRatesUpdate() {
		DispatchQueue.main.async {
			self.refreshControlRates.endRefreshing()
			self.tblRate.reloadData()
		}
	}
	
	func sellStart() {
		DispatchQueue.main.sync { self.vWait.isHidden = false }
	}
	
	func sellComplete() {
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
			self.app.model!.refresh()
		})
	}
	
	func updateSellRate() {
		DispatchQueue.main.sync {
			self.lblSellRate.text = " 1 BIO ~ \(String(format: "%.2f", app.model!.sellRate)) " + app.model!.currency.symbol() + " \n " + NSLocalizedString(app.model!.currency.rawValue+"Commission", comment: "commission text")
			updateSellAmount(self.tfAmount_Sell.text ?? "")
		}
	}
	
	func buyStart() {
		app.model!.buyRedirectUrl = ""
		app.model!.buyState = ""
		app.model!.buyOpKey = ""
		DispatchQueue.main.sync { self.vWait.isHidden = false }
	}
	
	func buyComplete() {
		if app.model!.buyState == "Redirect" && app.model!.buyRedirectUrl != "" {
			DispatchQueue.main.async {
				self.performSegue(withIdentifier: "3ds-auth", sender: self.app.model!.buyRedirectUrl)
			}
			return
		}
		checkOpComplete(app.model!.buyState)
	}
	
	func updateBuyRate() {
		DispatchQueue.main.sync {
			self.lblBuyRate.text = " 1 BIO ~ \(String(format: "%.2f", Double(1) / app.model!.buyRate)) " + app.model!.currency.symbol()
			updateBuyAmount(self.tfAmount_Buy.text ?? "")
		}
	}
	
	func checkOpComplete(_ process: String) {
		switch process {
		case "ERROR":
			let alert = UIAlertController.init(title: NSLocalizedString("CheckOpErrorTitle", comment: ""), message: NSLocalizedString("CheckOpErrorMessage", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
				self.app.model!.buyOpKey = ""
				self.app.model!.buyState = ""
				self.app.model!.refresh()
			})
			break;
		case "Done":
			let alert = UIAlertController.init(title: NSLocalizedString("CheckOpDoneTitle", comment: ""), message: NSLocalizedString("CheckOpDoneMessage", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
				self.app.model!.buyOpKey = ""
				self.app.model!.buyState = ""
				self.app.model!.refresh()
			})
			break;
		case "Cancel":
			let alert = UIAlertController.init(title: NSLocalizedString("CheckOpCancelTitle", comment: ""), message: NSLocalizedString("CheckOpCancelMessage", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
				self.app.model!.buyOpKey = ""
				self.app.model!.buyState = ""
				self.app.model!.refresh()
			})
			break;
		default:
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
				self.app.model!.checkBuyOp()
			})
			break;
		}
	}
	
	func newBitPayAddressComplete(_ address: String?) {
		
	}
	
	func payInvoiceError(_ error: String?) {
		if error != nil { showError(error: error!) }
	}
	
	func payInvoiceComplete(_ txid: String?, _ btctxid: String?, _ message: String?) {
		
	}
	
	override func processUrlCommand() {
		if app.needToProcessURL {
			if (app.openUrl != nil) {
				let components = URLComponents(url: app.openUrl!, resolvingAgainstBaseURL: true)
				if components?.scheme?.lowercased() == "biocoin" {
					app.needToProcessURL = false
					performSegue(withIdentifier: "send-bio", sender: components)
				}
				if components?.scheme?.lowercased() == "file" {
					app.needToProcessURL = false
					performSegue(withIdentifier: "settings-bio", sender: app.openUrl!)
				}
			}
		}
	}
	
	//CardIOPaymentViewControllerDelegate
	func userDidCancel(_ paymentViewController: CardIOPaymentViewController) -> Void {
		paymentViewController.dismiss(animated: true, completion: nil)
	}
	
	/// This method will be called when there is a successful scan (or manual entry). You MUST dismiss paymentViewController.
	/// @param cardInfo The results of the scan.
	/// @param paymentViewController The active CardIOPaymentViewController.
	func userDidProvide (_ cardInfo: CardIOCreditCardInfo, in paymentViewController: CardIOPaymentViewController) -> Void {
		if !(self.tfCardNumber_Buy.superview?.isHidden ?? true) {
			self.tfCardNumber_Buy.text = cardInfo.cardNumber
			self.tfExp_Buy.text = String(format: "%02i", cardInfo.expiryMonth) + String(format: "%02i", cardInfo.expiryYear > 2000 ? cardInfo.expiryYear - 2000 : cardInfo.expiryYear)
			if self.tfExp_Buy.text != "" {
				paymentViewController.dismiss(animated: true, completion: {() -> Void in self.tfCVV_Buy.becomeFirstResponder()})
			} else {
				paymentViewController.dismiss(animated: true, completion: {() -> Void in self.tfExp_Buy.becomeFirstResponder()})
			}
		}
		if !(self.tfCardNumber_Sell.superview?.isHidden ?? true) {
			self.tfCardNumber_Sell.text = cardInfo.cardNumber
			if self.tfCardNumber_Sell.text!.luhnCheck() {
				self.tfCardNumber_Sell.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.8)
			} else {
				self.tfCardNumber_Sell.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.8)
			}
			paymentViewController.dismiss(animated: true, completion: {() -> Void in self.tfAmount_Sell.becomeFirstResponder()})
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
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
		
	}
	
	func updateBuyAmount(_ txt: String) {
		if txt == "" || self.app.model!.buyRate == 0 {
			setButtonText(self.btnBIOBuy, NSLocalizedString("EmptyBuyButtonText", comment: "EmptyBuyButtonText"))
			return
		}
		amountBuy = Double(txt.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)) ?? 0
		if amountBuy < 1 {
			tfAmount_Buy.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.7)
		} else {
			tfAmount_Buy.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.7)
		}
		
		setButtonText(self.btnBIOBuy, NSLocalizedString("BuyButtonText", comment: "BuyButtonText") + String(format: "%.2f", amountBuy * Double(1)/app.model!.buyRate) + " " + app.model!.currency.symbol())
	}
	
	func updateSellAmount(_ txt: String) {
		if txt == "" || self.app.model!.sellRate == 0 {
			setButtonText(self.btnBIOSell, NSLocalizedString("EmptySellButtonText", comment: "EmptySellButtonText"))
			return
		}
		amountSell = Double(txt.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)) ?? 0
		if app.model!.Balance < amountSell {
			tfAmount_Sell.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.7)
		} else {
			tfAmount_Sell.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.7)
		}
		
		setButtonText(self.btnBIOSell, NSLocalizedString("SellButtonText", comment: "SellButtonText") + String(format: "%.2f", amountSell * app.model!.sellRate) + " " + app.model!.currency.symbol())
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let textFieldText: NSString = (textField.text ?? "") as NSString
		var txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
		var txtChange = string
		if textField == tfCardNumber_Sell || textField == tfCardNumber_Buy || textField == tfExp_Buy || textField == tfCVV_Buy {
			txtAfterUpdate = txtAfterUpdate.digits
			txtChange = string.digits
		}
		
		if txtAfterUpdate == "" {
			textField.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7)
			if textField == self.tfAmount_Sell {
				setButtonText(self.btnBIOSell, NSLocalizedString("EmptySellButtonText", comment: "EmptySellButtonText"))
			}
			if textField == self.tfAmount_Buy {
				setButtonText(self.btnBIOBuy, NSLocalizedString("EmptyBuyButtonText", comment: "EmptyBuyButtonText"))
			}
			return true
		}
		
		if textField == self.tfCardNumber_Sell {
			if (txtAfterUpdate.luhnCheck() && txtAfterUpdate.count > 13) {
				textField.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.7)
				textField.text = txtAfterUpdate
				if txtAfterUpdate.count == 16 {
					self.tfAmount_Sell.becomeFirstResponder()
				}
				return false
			} else {
				textField.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.7)
			}
		}
		
		if textField == self.tfCardNumber_Buy {
			if (txtAfterUpdate.luhnCheck() && txtAfterUpdate.count > 13) {
				textField.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.7)
				textField.text = txtAfterUpdate
				if txtAfterUpdate.count == 16 {
					self.tfExp_Buy.becomeFirstResponder()
				}
				return false
			} else {
				textField.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.7)
			}
		}
		
		if textField == self.tfAmount_Sell {
			updateSellAmount(txtAfterUpdate)
		}
		
		if textField == self.tfAmount_Buy {
			updateBuyAmount(txtAfterUpdate)
		}
		
		if textField == self.tfExp_Buy {
			if (txtAfterUpdate.count == 4) {
				textField.text = txtAfterUpdate
				self.tfCVV_Buy.becomeFirstResponder()
				return false
			}
		}
		
		if textField == self.tfCVV_Buy {
			if (txtAfterUpdate.count == 3) {
				textField.text = txtAfterUpdate
				self.tfAmount_Buy.becomeFirstResponder()
				return false
			}
		}
		
		textField.text = txtAfterUpdate;
		DispatchQueue.main.async {
			let position = textField.position(from: textField.beginningOfDocument, offset: range.lowerBound+txtChange.count)!
			textField.selectedTextRange = textField.textRange(from: position, to: position)
		}
		return false
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return true
	}
	
	// Swipes
	func doSwipe(_ delta: Int) {
		self.scDimension.selectedSegmentIndex += delta
		if self.scDimension.selectedSegmentIndex < 0 { self.scDimension.selectedSegmentIndex = 0 }
		if self.scDimension.selectedSegmentIndex >= self.scDimension.numberOfSegments { self.scDimension.selectedSegmentIndex = self.scDimension.numberOfSegments - 1 }
		segmentControlValueChanged(self)
	}
	
	@IBAction public func swipeLeft(_ sender: Any?) {
		doSwipe(1);
	}
	
	@IBAction public func swipeRight(_ sender: Any?) {
		doSwipe(-1);
	}
}

