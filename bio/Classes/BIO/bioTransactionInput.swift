//
//  bioTransactionInput.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

class bioTransactionInput : NSObject {
	
	var outPoint: bioTransactionInputOutpoint
	var Script: [UInt8]
	var Sequence: UInt64
	
	init(_ address: String, _ hash: String, _ index: UInt32, _ script: String, _ lockTime: UInt32) {
		outPoint = bioTransactionInputOutpoint(address, hash, index)
		Script = script.hexa2Bytes
		Sequence = lockTime == 0 ? 4294967295 : 0
		super.init()
	}
	
	init(_ address: String, _ hash: String, _ index: UInt32, _ script: [UInt8], _ lockTime: UInt32) {
		outPoint = bioTransactionInputOutpoint(address, hash, index)
		Script = script.map { $0 }
		Sequence = lockTime == 0 ? 4294967295 : 0
		super.init()
	}
}
