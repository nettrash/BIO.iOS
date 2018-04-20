//
//  bioTransactionOutput.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

class bioTransactionOutput : NSObject {

	var Amount: BigInteger
	var ScriptedAddress: [UInt8]
	var Satoshi: UInt64
	
	init(_ script: [UInt8], _ value: BigInteger, _ satoshi: UInt64) {
		ScriptedAddress = script.map { $0 }
		Amount = value
		Satoshi = satoshi
		super.init()
	}
}
