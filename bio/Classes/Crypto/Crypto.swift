//
//  Crypto.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import CommonCrypto

class Crypto {
	
	static func sha256(_ data: Data) -> Data {
		var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
		data.withUnsafeBytes {
			_ = CC_SHA256($0, CC_LONG(data.count), &hash)
		}
		return Data(bytes: hash)
	}

	static func hmac_sha256(_ data: Data, _ key: Data) -> Data {
		var cHMAC = [CUnsignedChar](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), Array(key), Int(key.count), Array(data), Int(data.count), &cHMAC)
		return Data(cHMAC)
	}

	static func md5(_ string: String) -> Data {
		let messageData = string.data(using:.utf8)!
		var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
		
		_ = digestData.withUnsafeMutableBytes {digestBytes in
			messageData.withUnsafeBytes {messageBytes in
				CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
			}
		}
		
		return digestData
	}

}
