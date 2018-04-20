//
//  bitpayInvoice.swift
//  sib-lite
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class bitpayInvoice {
	
	public var sourceJson: String?
	
	public var url: URL?
	public var posData: String?
	public var status: String?
	public var btcPrice: Double?
	public var btcDue: Double?
	public var price: Double?
	public var currency: String?
	public var itemDesc: String?
	public var orderId: String?
	public var invoiceTime: Date?
	public var expirationTime: Date?
	public var currentTime: Date?
	public var id: String?
	public var lowFeeDetected: Bool?
	public var amountPaid: Double?
	public var btcPaid: Double?
	public var rate: Double?
	public var exceptionStatus: Bool?
	public var redirectURL: URL?
	public var refundAddressRequestPending: Bool?
	public var buyerProvidedEmail: String?
	public var buyerProvidedInfo: bitpayBuyerProvidedInfo?
	public var addresses: [String:String]?
	public var paymentSubtotals: [String:Double]?
	public var paymentTotals: [String:Double]?
	public var bitcoinAddress: String?
	public var exchangeRates: bitpayExchangeRates?
	public var minerFees: bitpayMinerFees?
	public var buyerPaidBtcMinerFee: Double?
	public var supportedTransactionCurrencies: bitpaySupportedTransactionCurrencies?
	public var exRates: [String:Double]?
	public var paymentUrls: [String:String]?
	public var paymentCodes: bitpayPaymentCodes?
	public var token: String?
	
	init() {
		
	}
	
	init(_ jsonData: String) {
		parse(jsonData)
	}
	
	init(url: URL, completion: @escaping (Error?) -> ()) {
		let urlRequest: URLRequest = URLRequest(url: url)
		let session = URLSession.shared
		let task = session.dataTask(with: urlRequest) {
			(data, response, error) -> Void in
			
			if error == nil {
				let json = String(data: data!, encoding: .utf8)
				self.parse(json!)
			}
			completion(error)
		}
		task.resume()
	}

	func parse(_ jsonData: String) -> Void {
		sourceJson = jsonData
		
		let json = try? JSONSerialization.jsonObject(with: jsonData.data(using: String.Encoding.utf8)!, options: [])
		if let jsonRoot = json as? [String:Any] {
			if let json = jsonRoot["data"] as? [String:Any] {
				url = URL(string: json["url"] as? String ?? "")
				posData = json["posData"] as? String
				status = json["status"] as? String
				btcPrice = (Decimal(string: json["btcPrice"] as? String ?? "") as NSDecimalNumber?)?.doubleValue
				btcDue = (Decimal(string: json["btcDue"] as? String ?? "") as NSDecimalNumber?)?.doubleValue
				price = json["price"] as? Double
				currency = json["currency"] as? String
				itemDesc = json["itemDesc"] as? String
				orderId = json["orderId"] as? String
				if let invoiceTimeInterval = json["invoiceTime"] as? Double {
					invoiceTime = Date(timeIntervalSince1970: invoiceTimeInterval / 1000.0)
				}
				if let exoirationTimeInterval = json["expirationTime"] as? Double {
					expirationTime = Date(timeIntervalSince1970: exoirationTimeInterval / 1000.0)
				}
				if let currentTimeInterval = json["currentTime"] as? Double {
					currentTime = Date(timeIntervalSince1970: currentTimeInterval / 1000.0)
				}
				id = json["id"] as? String
				lowFeeDetected = json["lowFeeDetected"] as? Bool
				amountPaid = json["amountPaid"] as? Double
				btcPaid = (Decimal(string: json["btcPaid"] as? String ?? "") as NSDecimalNumber?)?.doubleValue
				rate = json["rate"] as? Double
				exceptionStatus = json["exceptionStatus"] as? Bool
				redirectURL = URL(string: json["redirectURL"] as? String ?? "")
				refundAddressRequestPending = json["refundAddressRequestPending"] as? Bool
				buyerProvidedEmail = json["buyerProvidedEmail"] as? String
				if let buyerProvidedInfoSource = json["buyerProvidedInfo"] as? [String:String] {
					buyerProvidedInfo = bitpayBuyerProvidedInfo()
					buyerProvidedInfo?.emailAddress = buyerProvidedInfoSource["emailAddress"]
					buyerProvidedInfo?.selectedTransactionCurrency = buyerProvidedInfoSource["selectedTransactionCurrency"]
				}
				addresses = json["addresses"] as? [String:String]
				paymentSubtotals = json["paymentSubtotals"] as? [String:Double]
				paymentTotals = json["paymentTotals"] as? [String:Double]
				bitcoinAddress = json["bitcoinAddress"] as? String
				if let exchangeRatesSource = json["exchangeRates"] as? [String:[String:Double]] {
					exchangeRates = bitpayExchangeRates()
					exchangeRates?.BTC = exchangeRatesSource["BTC"]
				}
				if let minerFeesSource = json["minerFees"] as? [String:[String:UInt64]] {
					minerFees = bitpayMinerFees()
					minerFees?.BTC = bitpayMinerFee()
					let btcFee = minerFeesSource["BTC"]
					minerFees?.BTC?.totalFee = btcFee?["totalFee"]
					minerFees?.BTC?.satoshisPerByte = btcFee?["satoshisPerByte"]
				}
				buyerPaidBtcMinerFee = (Decimal(string: json["buyerPaidBtcMinerFee"] as? String ?? "") as NSDecimalNumber?)?.doubleValue
				if let supportedTransactionCurrenciesSource = json["supportedTransactionCurrencies"] as? [String:[String:Any]] {
					supportedTransactionCurrencies = bitpaySupportedTransactionCurrencies()
					if let btcSource = supportedTransactionCurrenciesSource["BTC"] {
						supportedTransactionCurrencies?.BTC = bitpaySupportedTransactionCurrencyInfo()
						supportedTransactionCurrencies?.BTC?.enabled = btcSource["enabled"] as? Bool
					}
				}
				exRates = json["exRates"] as? [String:Double]
				paymentUrls = json["paymentUrls"] as? [String:String]
				if let paymentCodesSource = json["paymentCodes"] as? [String:[String:String]] {
					paymentCodes = bitpayPaymentCodes()
					paymentCodes?.BTC = paymentCodesSource["BTC"]
				}
				token = json["token"] as? String
			}
		}
	}
	
	func isValid() -> Bool {
		return
			posData != nil && status != nil && id != nil
	}
	
	func isExpired() -> Bool {
		return
			status?.lowercased() == "expired" ||
			expirationTime ?? Date() <= Date()
	}
	
	func isAvailibleForProcess() -> Bool {
		return
			isValid() &&
			!isExpired() &&
			supportedTransactionCurrencies?.BTC?.enabled ?? false == true &&
			buyerProvidedInfo?.selectedTransactionCurrency?.uppercased() ?? "" == "BTC"
	}
	
	static func canParse(url: String) -> Bool {
		return url.lowercased().range(of: "bitpay") != nil
	}
	
	func showErrorInfo(_ vc: UIViewController) -> Void {
		var msg = "";
		if !isValid() {
			msg = "BitPay Invoice is invalid"
		} else {
			if isExpired() {
				msg = "\(invoiceInformation())"
			}
		}
		let alert = UIAlertController.init(title: "BitPay Invoice", message: msg, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
		vc.present(alert, animated: true, completion: nil)

	}

	func showErrorInfo(_ vc: UIViewController, _ msg: String) -> Void {
		var s = msg;
		if !isValid() {
			s = "BitPay Invoice is invalid"
		} else {
			if isExpired() {
				s = "\(invoiceInformation())\n\(msg)"
			}
		}
		let alert = UIAlertController.init(title: "BitPay Invoice", message: s, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
		vc.present(alert, animated: true, completion: nil)
		
	}

	func showInfo(_ vc: UIViewController, _ msg: String, _ pay: @escaping () -> (), _ cancel: @escaping () -> ()) -> Void {
		let alert = UIAlertController.init(title: "BitPay Invoice", message: "\(invoiceInformation())\n\(msg)", preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("OtherCryptoTransferDo", comment: "Исполнить"), style: UIAlertActionStyle.default, handler: { _ in alert.dismiss(animated: true, completion: nil); pay(); }))
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil); cancel(); }))
		vc.present(alert, animated: true, completion: nil)
		
	}

	func invoiceInformation() -> String {
		return
"""
		
\(itemDesc ?? "")
		
\(String(format: "%.2f", price!)) \(currency!)
\(String(format: "%.8f", btcDue!)) BTC

1 BTC = \(String(format: "%.2f", rate!)) \(currency!)

\(status!.uppercased())
		
"""
	}
}
