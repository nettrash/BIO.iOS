//
//  StringExtensions.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
	
	var hexa2Bytes: [UInt8] {
		let hexa = Array(self)
		return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0..<$0.advanced(by: 2)]), radix: 16) }
	}
	
	func luhnCheck() -> Bool {
		var sum = 0
		let reversedCharacters = self.reversed().map { String($0) }
		for (idx, element) in reversedCharacters.enumerated() {
			guard let digit = Int(element) else { return false }
			switch ((idx % 2 == 1), digit) {
			case (true, 9): sum += 9
			case (true, 0...8): sum += (digit * 2) % 9
			default: sum += digit
			}
		}
		return sum % 10 == 0
	}
	
	func aesEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
		if let keyData = key.data(using: String.Encoding.utf8),
			let data = self.data(using: String.Encoding.utf8),
			let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {
			
			
			let keyLength              = size_t(kCCKeySizeAES128)
			let operation: CCOperation = UInt32(kCCEncrypt)
			let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
			let options:   CCOptions   = UInt32(options)
			
			
			
			var numBytesEncrypted :size_t = 0
			
			let cryptStatus = CCCrypt(operation,
									  algoritm,
									  options,
									  (keyData as NSData).bytes, keyLength,
									  iv,
									  (data as NSData).bytes, data.count,
									  cryptData.mutableBytes, cryptData.length,
									  &numBytesEncrypted)
			
			if UInt32(cryptStatus) == UInt32(kCCSuccess) {
				cryptData.length = Int(numBytesEncrypted)
				let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
				return base64cryptString
			}
			else {
				return nil
			}
		}
		return nil
	}
	
	func aesEncrypt(key:Data, iv:Data, options:Int = kCCOptionPKCS7Padding) -> String? {
		let keyData = key
		if	let data = self.data(using: String.Encoding.utf8),
			let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {
			
			
			let keyLength              = size_t(kCCKeySizeAES128)
			let operation: CCOperation = UInt32(kCCEncrypt)
			let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
			let options:   CCOptions   = UInt32(options)
			
			
			
			var numBytesEncrypted :size_t = 0
			
			let cryptStatus = CCCrypt(operation,
									  algoritm,
									  options,
									  (keyData as NSData).bytes, keyLength,
									  (iv as NSData).bytes,
									  (data as NSData).bytes, data.count,
									  cryptData.mutableBytes, cryptData.length,
									  &numBytesEncrypted)
			
			if UInt32(cryptStatus) == UInt32(kCCSuccess) {
				cryptData.length = Int(numBytesEncrypted)
				let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
				return base64cryptString
			}
			else {
				return nil
			}
		}
		return nil
	}

	func aesDecrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
		if let keyData = key.data(using: String.Encoding.utf8),
			let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
			let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {
			
			let keyLength              = size_t(kCCKeySizeAES128)
			let operation: CCOperation = UInt32(kCCDecrypt)
			let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
			let options:   CCOptions   = UInt32(options)
			
			var numBytesEncrypted :size_t = 0
			
			let cryptStatus = CCCrypt(operation,
									  algoritm,
									  options,
									  (keyData as NSData).bytes, keyLength,
									  iv,
									  data.bytes, data.length,
									  cryptData.mutableBytes, cryptData.length,
									  &numBytesEncrypted)
			
			if UInt32(cryptStatus) == UInt32(kCCSuccess) {
				cryptData.length = Int(numBytesEncrypted)
				let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
				return unencryptedMessage
			}
			else {
				return nil
			}
		}
		return nil
	}
	
	func aesDecrypt(key:Data, iv:Data, options:Int = kCCOptionPKCS7Padding) -> String? {
		let keyData = key
		if	let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
			let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {
			
			let keyLength              = size_t(kCCKeySizeAES128)
			let operation: CCOperation = UInt32(kCCDecrypt)
			let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
			let options:   CCOptions   = UInt32(options)
			
			var numBytesEncrypted :size_t = 0
			
			let cryptStatus = CCCrypt(operation,
									  algoritm,
									  options,
									  (keyData as NSData).bytes, keyLength,
									  (iv as NSData).bytes,
									  data.bytes, data.length,
									  cryptData.mutableBytes, cryptData.length,
									  &numBytesEncrypted)
			
			if UInt32(cryptStatus) == UInt32(kCCSuccess) {
				cryptData.length = Int(numBytesEncrypted)
				let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
				return unencryptedMessage
			}
			else {
				return nil
			}
		}
		return nil
	}

	var digits: String {
		return components(separatedBy: CharacterSet.decimalDigits.inverted)
			.joined()
	}


}

