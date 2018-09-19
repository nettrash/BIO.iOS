//
//  SendViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class SendViewController : BaseViewController, ModelRootDelegate, UITextFieldDelegate {
	
	let app = UIApplication.shared.delegate as! AppDelegate
	
	private var _unspent: Unspent?
	private var _amount: Double?
	private var _commission: Double?
	private var _unspentAmount: Double?
	private var _address: String?
	
	private var _otherAddress: String?
	private var _otherAmount: Decimal?
	private var _otherCurrency: Currency?
	private var _otherInvoice: bitpayInvoice?
	
	private var processAction: (() -> Void)?
	
	var components: URLComponents?
	
	@IBOutlet var tfAddress: UITextField!
	@IBOutlet var tfAmount: UITextField!
	@IBOutlet var tfCommission: UITextField!
	@IBOutlet var lblBalance: UILabel!
	@IBOutlet var vWait: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let app = UIApplication.shared.delegate as! AppDelegate
		lblBalance.text = String(format: "%.2f", app.model!.Balance) + " BIO"
		vWait.isHidden = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		let app = UIApplication.shared.delegate as! AppDelegate
		app.model!.delegate = self
		parseComponents(true)
		
		if processAction != nil {
			processAction!()
		} else {
			if tfAddress.text?.count ?? 0 > 0 {
				tfAmount.becomeFirstResponder()
			} else {
				tfAddress.becomeFirstResponder()
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "scan-address") {
			let dst = segue.destination as! ScanViewController
			dst.unwindIdentifiers["scan-address"] = "unwindSegueToSend"
		}
		if (segue.identifier == "enter-other-amount") {
			let dst = segue.destination as! EnterAmountViewController
			dst.unwindIdentifiers["enter-other-amount"] = "unwindSegueToSend"
			dst.otherTitle = NSLocalizedString("OtherCryptoTransferAmountTitle", comment: "currency") + " " + (_otherCurrency?.rawValue ?? "")
		}
	}
	
	func parseComponents(_ includeOtherCrypto: Bool) -> Void {
		if components != nil {
			if components?.scheme?.lowercased() == "biocoin" {
				
				tfAddress.text = components?.host
				if components?.queryItems != nil {
					for qi in components!.queryItems! {
						switch qi.name {
						case "amount":
							tfAmount.text = qi.value ?? ""
							break;
						case "message":
							//message = qi.value
							break;
						case "IS":
							//scInstantSend.isOn = qi.value ?? "" == "1"
							break;
						default:
							break;
						}
					}
				}
				components = nil
			}
			if includeOtherCrypto && (components?.scheme?.lowercased() == "bitcoin" || components?.scheme?.lowercased() == "sibcoin") {
				var ocCurrency: Currency?
				
				switch components?.scheme?.lowercased() {
				case "bitcoin":
					ocCurrency = Currency.BTC
					break
				case "sibcoin":
					ocCurrency = Currency.SIB
					break
				default:
					break
				}
				
				let ocAddress: String? = components?.host
				var ocAmount: String = ""
				
				if components?.queryItems != nil {
					for qi in components!.queryItems! {
						switch qi.name {
						case "amount":
							ocAmount = qi.value ?? ""
							break
						default:
							break
						}
					}
				}
				components = nil
				processOtherCrypto(ocCurrency, ocAddress, Double.init(ocAmount) != nil ? Decimal.init(Double.init(ocAmount)!) : nil, nil)
			}
		}
	}
	
	@IBAction func unwindToSend(unwindSegue: UIStoryboardSegue) {
		if (unwindSegue.source is ScanViewController) {
			let dest = unwindSegue.destination as! SendViewController
			let src = unwindSegue.source as! ScanViewController
			switch src.currency {
			case .BIO:
				dest.tfAddress.text = src.address
				if src.amount ?? 0 > 0 {
					dest.tfAmount.text = "\(src.amount!)"
				}
				//dest.scInstantSend.isOn = src.instantSend
				break
			case .BTC,
				 .SIB:
				//send BIO to other crypto
				self.processAction = { self.processOtherCrypto(src.currency, src.address, src.amount, src.bitpay) }
				break
			default:
				break
			}
		}
		
		if (unwindSegue.source is EnterAmountViewController) {
			let src = unwindSegue.source as! EnterAmountViewController
			if src.amount != nil {
				_otherAmount = src.amount
				self.vWait.isHidden = false
				self.app.model!.sellRate = 0
				self.app.model!.getSellRate(_otherCurrency!.rawValue)
			}
		}
	}
	
	func processOtherCrypto(_ currency: Currency?, _ address: String?, _ amount: Decimal?, _ invoice: bitpayInvoice?) -> Void {
		self.processAction = nil
		
		//Считаем курс sellRate
		_otherCurrency = currency
		_otherAddress = address
		_otherAmount = amount
		_otherInvoice = invoice
		
		if currency == nil { return }
		
		if _otherInvoice != nil {
			if _otherInvoice!.isAvailibleForProcess() {
				self.vWait.isHidden = false
				self.app.model!.sellRate = 0
				_otherAmount = Decimal((_otherInvoice!.btcDue ?? _otherInvoice!.btcPrice)!)
				_otherAddress = _otherInvoice!.bitcoinAddress
				self.app.model!.getSellRate(currency!.rawValue)
			} else {
				_otherInvoice!.showErrorInfo(self)
			}
			return
		}
		if _otherAmount ?? 0 <= 0 {
			performSegue(withIdentifier: "enter-other-amount", sender: self)
		} else {
			self.vWait.isHidden = false
			self.app.model!.sellRate = 0
			self.app.model!.getSellRate(currency!.rawValue)
		}
	}
	
	@IBAction func closeClick(_ sender: Any?) -> Void {
		performSegue(withIdentifier: unwindIdentifiers["send-bio"]!, sender: self)
	}
	
	func checkValid() -> Bool {
		return bioAddress.verify(tfAddress.text)
	}
	
	@IBAction func sendClick(_ sender: Any?) -> Void {
		self.view.endEditing(true)
		vWait.isHidden = false
		let app = UIApplication.shared.delegate as! AppDelegate
		app.model!.delegate = self
		app.model!.getUnspentData()
	}
	
	@IBAction func scanClick(_ sender: Any?) -> Void {
		self.view.endEditing(true)
		performSegue(withIdentifier: "scan-address", sender: self)
	}
	
	func verifyData() -> Bool {
		DispatchQueue.main.sync {
			_amount = Double(tfAmount.text!.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
			_commission = Double(0)//Double(tfCommission.text!.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
			_unspentAmount = 0
			if _unspent?.Items.count ?? 0 > 0 {
				for u in _unspent!.Items {
					_unspentAmount = (_unspentAmount ?? 0) + u.amount
				}
			}
			_address = tfAddress.text
		}
		return (_amount ?? 0) > 0 && ((_amount ?? 0) + (_commission ?? 0) <= (_unspentAmount ?? 0))
	}
	
	private func _prepareTransaction() -> bioTransaction {
		let tx: bioTransaction = bioTransaction()
		//Добавляем требуемый вывод
		tx.addOutput(address: _address!, amount: _amount!)
		var spent: Double = 0
		//Добавляем непотраченные входы
		for u in _unspent!.Items {
			if spent < _amount! + _commission! {
				spent += u.amount.rounded(toPlaces: 8)
				tx.addInput(u)
			} else {
				break;
			}
		}
		if (spent - _amount! - _commission! >= 0.01) {
			tx.addChange(amount: spent - _amount! - _commission!)
		}
		print(tx.serialize().hexEncodedString())
		return tx
	}
	
	private func _sendTransaction(_ tx: bioTransaction) -> Void {
		let app = UIApplication.shared.delegate as! AppDelegate
		if tx.Change != nil && tx.Change!.PrivateKey != nil && tx.Change!.PublicKey != nil && tx.Change!.Address != nil && tx.Change!.WIF != nil {
			app.model!.storeWallet(tx.Change!, true, .Change) //В слычае неуспеха отправки надо удалять
		}
		let sign = tx.sign(app.model!.Addresses)
		print(sign.hexEncodedString())
		//Отправляем sign как rawtx
		app.model!.delegate = self
		app.model!.broadcastTransaction(sign)
	}
	
	// UITextFieldDelegate
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return textField != self.tfCommission
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		return true
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let textFieldText: NSString = (textField.text ?? "") as NSString
		let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
		
		if textField == tfAddress {
			if (bioAddress.verify(txtAfterUpdate)) {
				textField.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.8)
				textField.text = txtAfterUpdate
				tfAmount.becomeFirstResponder()
				return false
			} else {
				if bioAddress.verifyBTC(txtAfterUpdate) {
					textField.text = ""
					processOtherCrypto(.BTC, txtAfterUpdate, nil, nil)
					return false
				} else {
					if bioAddress.verifySIB(txtAfterUpdate) {
						textField.text = ""
						processOtherCrypto(.SIB, txtAfterUpdate, nil, nil)
						return false
					}
				}
				textField.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.8)
			}
		}
		
		if textField == tfAmount {
			let amount = Double(txtAfterUpdate.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
			let commission = Double(0)//Double(0.001 * (amount ?? 0))
			self.tfCommission.text = String(format: "%.4f", commission)
			if self.app.model!.Balance < (amount ?? 0) + commission {
				textField.backgroundColor = UIColor(displayP3Red: 1, green: 0.9, blue: 0.9, alpha: 0.8)
			} else {
				textField.backgroundColor = UIColor(displayP3Red: 0.9, green: 1, blue: 0.9, alpha: 0.8)
			}
		}
		
		return true;
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return checkValid()
	}
	
	//ModelRootDelegate
	
	func startBalanceUpdate() -> Void {
		
	}
	
	func stopBalanceUpdate(error: String?) -> Void {
		
	}
	
	func startHistoryUpdate() -> Void {
		
	}
	
	func stopHistoryUpdate() -> Void {
		
	}
	
	func unspetData(_ data: Unspent) -> Void {
		_unspent = data
		if (self._otherInvoice != nil) {
			//prepare signed transaction data to pay invoice
			self._commission = Double(0)//Double(0.001 * (self._amount ?? 0))
			let tx: bioTransaction = self._prepareTransaction()
			app.model!.storeWallet(tx.Change!, true, .Change) //В слычае неуспеха отправки надо удалять
			let sign = tx.sign(app.model!.Addresses)
			//pay invoice
			self.app.model!.payInvoice(self._otherInvoice!, sign, self._address!, self._amount!, self._otherAddress!, self._otherAmount!)
		} else {
			if verifyData() {
				DispatchQueue.main.sync {
					let tx: bioTransaction = self._prepareTransaction()
					print(tx.serialize().hexEncodedString())
					self._sendTransaction(tx)
					self.vWait.isHidden = false;
				}
			} else {
				DispatchQueue.main.sync {
					self.vWait.isHidden = true
					let alert = UIAlertController.init(title: NSLocalizedString("Error", comment: "Ошибка"), message: NSLocalizedString("SendAmountError", comment: "Ошибка") + String(format: "%.2f", self._unspentAmount!), preferredStyle: UIAlertController.Style.alert)
					alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertAction.Style.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
					self.present(alert, animated: true, completion: nil)
				}
			}
		}
	}
	
	func broadcastTransactionResult(_ result: Bool, _ txid: String?, _ message: String?) {
		DispatchQueue.main.async {
			self.vWait.isHidden = true
			if result {
				let alert = UIAlertController.init(title: NSLocalizedString("SuccessSend", comment: "Успех"), message: NSLocalizedString("SuccessSendMessage", comment: "Success") + txid!, preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil); self.closeClick(nil) }))
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("Share", comment: "Поделться"), style: UIAlertAction.Style.default, handler: { _ in self.shareText(txid!); alert.dismiss(animated: true, completion: nil) }))
				self.present(alert, animated: true, completion: nil)
				
			} else {
				//Добавить удаление последнего адреса Change
				let alert = UIAlertController.init(title: NSLocalizedString("ErrorSend", comment: "Ошибка"), message: NSLocalizedString("ErrorSendMessage", comment: "Ошибка") + (message ?? ""), preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
	func startCurrentRatesUpdate() {
	}
	
	func stopCurrentRatesUpdate() {
	}
	
	func sellStart() {
	}
	
	func sellComplete() {
		DispatchQueue.main.async {
			self._otherAddress = nil
			self._otherInvoice = nil
			self._otherAmount = nil
			self._otherCurrency = nil
			self._amount = nil
			self._address = nil
			self._commission = nil
			self.tfAmount.text = ""
			self.tfAddress.text = ""
		}
	}
	
	func updateSellRate() {
		DispatchQueue.main.async {
			self._amount = (self._otherAmount! as NSDecimalNumber).doubleValue / self.app.model!.sellRate
			let commission = Double(0)//Double(0.001 * (self._amount ?? 0))
			if self.app.model!.Balance < (self._amount ?? 0) + commission {
				self.vWait.isHidden = true
				
				if self._otherInvoice != nil {
					var msg: String = "\n" + NSLocalizedString("OtherCryptoTransferMessageAmountBIO", comment: "OtherCryptoTransferMessageAmountBIO") + String(format: "%.8f", self._amount!) + " BIO\n\n"
					msg += NSLocalizedString("OtherCryptoTransferMessageCommission", comment: "OtherCryptoTransferMessageCommission") + String(format: "%.8f", commission) + " BIO\n\n"
					msg += NSLocalizedString("SendAmountError", comment: "Ошибка") + String(format: "%.2f", self.app.model!.Balance) + " BIO\n"
					
					self._otherInvoice!.showErrorInfo(self, msg)
				} else {
					let alert = UIAlertController.init(title: NSLocalizedString("Error", comment: "Ошибка"), message: NSLocalizedString("SendAmountError", comment: "Ошибка") + String(format: "%.2f", self.app.model!.Balance), preferredStyle: UIAlertController.Style.alert)
					alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertAction.Style.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
					self.present(alert, animated: true, completion: nil)
				}
				return
			}
			
			if self._otherInvoice != nil {
				var msg: String = NSLocalizedString("OtherCryptoTransferMessageAmountBIO", comment: "OtherCryptoTransferMessageAmountBIO") + String(format: "%.8f", self._amount!) + " BIO\n"
				msg += NSLocalizedString("OtherCryptoTransferMessageCommission", comment: "OtherCryptoTransferMessageCommission") + String(format: "%.8f", commission) + " BIO\n"
				
				self._otherInvoice!.showInfo(self, msg, {
					
					self.app.model!.getNewAddressForOtherInvoice()
					
				}, { self.vWait.isHidden = true })
			} else {
				let title: String = NSLocalizedString("OtherCryptoTransferTitle", comment: "OtherCryptoTransferTitle") + self._otherCurrency!.rawValue
				
				var msg: String = NSLocalizedString("OtherCryptoTransferMessageAddress", comment: "OtherCryptoTransferMessageAddress") + self._otherAddress! + "\n"
				msg += NSLocalizedString("OtherCryptoTransferMessageAmount", comment: "OtherCryptoTransferMessageAmount") + String(format: "%.8f", (self._otherAmount! as NSDecimalNumber).doubleValue) + " " + self._otherCurrency!.rawValue + "\n"
				msg += NSLocalizedString("OtherCryptoTransferMessageAmountBIO", comment: "OtherCryptoTransferMessageAmountBIO") + String(format: "%.8f", self._amount!) + " BIO\n"
				msg += NSLocalizedString("OtherCryptoTransferMessageCommission", comment: "OtherCryptoTransferMessageCommission") + String(format: "%.8f", commission) + " BIO"
				
				let alert = UIAlertController.init(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("OtherCryptoTransferDo", comment: "Исполнить"), style: 	UIAlertAction.Style.default, handler: { _ in
					//Регистрируем выплату
					//Выплачиваем
					self.app.model!.sell(self._otherCurrency!.rawValue, self._amount!, (self._otherAmount! as NSDecimalNumber).doubleValue, self._otherAddress!)
					alert.dismiss(animated: true, completion: nil) }))
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertAction.Style.cancel, handler: 	{ _ in
					self.vWait.isHidden = true
					alert.dismiss(animated: true, completion: nil) }))
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
	func buyStart() {
		
	}
	
	func buyComplete() {
		
	}
	
	func buyError(error: String?) {
		
	}
	
	func updateBuyRate() {
		
	}
	
	func checkOpComplete(_ process: String) {
		
	}
	
	func newBitPayAddressComplete(_ address: String?) {
		if address != nil && bioAddress.verify(address) {
			//address for send getted
			//refresh unspent data for prepare signed transaction data
			self._address = address
			self.app.model!.getUnspentData()
		}
	}
	
	func payInvoiceError(_ error: String?) {
		DispatchQueue.main.async {
			self.vWait.isHidden = true
			if error != nil { self.showError(error: error!) }
		}
	}
	
	func payInvoiceComplete(_ txid: String?, _ btctxid: String?, _ message: String?) {
		//Сообщить о результате корректно с использованием атрибутов
		DispatchQueue.main.async {
			self.vWait.isHidden = true
			self.broadcastTransactionResult(true, txid, nil)
		}
	}
	
	override func processUrlCommand() {
		let app = UIApplication.shared.delegate as! AppDelegate
		if app.needToProcessURL {
			if (app.openUrl != nil) {
				components = URLComponents(url: app.openUrl!, resolvingAgainstBaseURL: true)
				if components?.scheme?.lowercased() == "sibcoin" ||
					components?.scheme?.lowercased() == "biocoin" ||
					components?.scheme?.lowercased() == "bitcoin" {
					app.needToProcessURL = false
					parseComponents(false)
				} else {
					super.processUrlCommand()
				}
			}
		}
	}
}

