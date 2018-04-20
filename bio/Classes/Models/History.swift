//
//  TransactionHistory.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class History: NSObject {
	
	var Items: [HistoryItem] = []
	
	override init() {
		super.init()
	}
	
	func load(_ txs: [Any], addresses: [Address]) {
		let addrsIn = addresses.filter { $0.type == 0 }.map { (_ a: Address) -> String in
			a.address
		}
		let addrsChange = addresses.filter { $0.type == 1 }.map { (_ a: Address) -> String in
			a.address
		}
		Items = txs.map({ (_ t: Any) -> HistoryItem in
			
			let tx = t as? [String: Any]
			var txDate: Date = Date()
			let txAmount: Double = 0
			
			//let confirmations = tx?["Confirmations"] as? UInt32
			let transactionDate = tx?["TransactionDate"] as? String
			let transactionId = tx?["Id"] as? String
			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
			txDate = formatter.date(from: transactionDate!)!
			
			let Out = tx?["Out"] as? [Any]
			
			if (Out != nil) {
				let OutSorted = Out?.sorted(by: { (_ a: Any, _ b: Any) -> Bool in
					((a as? [String: Any])!["OrderN"] as! UInt32) < ((b as? [String: Any])!["OrderN"] as! UInt32)
					})
				
				var outInAmount: Double = 0
				var outChangeAmount: Double = 0
				var outExternalAmount: Double = 0
				var outAddressExt: String = ""
				var outAddressIn: String = ""
				
				for out in OutSorted! {
					let o = out as? [String: Any]
					let oa = o!["Addresses"] as? [String]
					let os = o!["Amount"] as? Double
					for oai in oa! {
						if addrsIn.contains(oai) {
							outInAmount += os!
							outAddressIn = oai
							continue
						}
						if addrsChange.contains(oai) {
							outChangeAmount += os!
							continue
						}
						outExternalAmount += os!
						outAddressExt = oai
					}
				}
				
				return HistoryItem(id: transactionId!, type: (outInAmount == 0 ? .Outgoing : .Incoming), date: txDate, amount: (outInAmount == 0 ? outExternalAmount : outInAmount) / Double(100000000), outAddress: outAddressExt == "" ? outAddressIn : outAddressExt)
			}
			
			//let In = tx?["In"] as? [Any]
			
			return HistoryItem(id: "", type: .Unknown, date: txDate, amount: txAmount, outAddress: "")
		})
	}
}
