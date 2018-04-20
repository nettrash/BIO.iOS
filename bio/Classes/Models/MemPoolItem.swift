//
//  MemPoolItem.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class MemPoolItem: NSObject {
	
	var address: String?
	var txid: String?
	var N: Int?
	var value: Int64?
	var seconds: Int64?
	var prev_txid: String?
	var prev_N: Int?
	var isInput: Bool = false
	
	func getAmount(_ dimension: BalanceDimension) -> String {
		var amount: Double = Double(value ?? 0) / pow(10,8)
		if amount < 0 { amount = -amount }
		switch dimension {
		case .BIO:
			return String(format: "%.2f", amount)
		case .mBIO:
			return String(format: "%.2f", amount * 1000)
		case .µBIO:
			return String(format: "%.2f", amount * 1000 * 1000)
		case .bioshi:
			return String(format: "%.0f", amount * 1000 * 1000 * 100)
		}
	}
	
	func getSeconds() -> String {
		return NSLocalizedString("InMemoryPool", comment: "in memory")
	}
}
