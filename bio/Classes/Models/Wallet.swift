//
//  Wallet.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import CoreData
import CommonCrypto

public class Wallet : NSObject {
	
	private let KeyTypePublic: UInt8 = 0x3f
	private let KeyTypePrivate: UInt8 = 0x80
	private let KeyTypeMultisign: UInt8 = 0x28
	
	public let Ticker: String = "SIB"
	public let URIScheme: String = "sibcoin:"
	
	private let OperationReturnMax: Int8 = 40
	
	public let Compressed: Bool = true
	
	public var PrivateKey: Data?
	public var PublicKey: Data?
	public var Address: String?
	public var WIF: String?
	
	override init() {
		super.init()
	}
	
	init(privateKey: Data?) {
		super.init()
		PrivateKey = privateKey
		PublicKey = generatePublicKey(PrivateKey!)
		Address = bioAddress.forKey(PublicKey!)
		WIF = bioAddress.wifFromPrivateKey(PrivateKey!)
	}

	private func sha256(_ data : Data) -> Data {
		var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
		data.withUnsafeBytes {
			_ = CC_SHA256($0, CC_LONG(data.count), &hash)
		}
		return Data(bytes: hash)
	}
	
	private func generatePublicKey(_ key: Data) -> Data {
		let privateKeyBigInteger: BigInteger = BigInteger(key)
		let curve: EllipticCurve = EllipticCurve()
		let curvePt: PointFP = curve.G!.multiply(privateKeyBigInteger)
		let x = curvePt.getX().toBigInteger()
		let y = curvePt.getY().toBigInteger()
		
		if Compressed {
			var a = EllipticCurve.integerToBytes(x, 32)
			if y.isEven() {
				a.insert(0x02, at: 0)
				return Data(a)
			} else {
				a.insert(0x03, at: 0)
				return Data(a)
			}
		} else {
			return Data(EllipticCurve.integerToBytes(x, 32) + EllipticCurve.integerToBytes(y, 32))
		}
	}
	
	public func initialize(_ secret: String) -> Void {
		let sourceForPrivateKey: String = "SIBPrivateKey\(3571 * secret.lengthOfBytes(using: String.Encoding.ascii))\(secret)NETTRASHSIB"
		let sourceForPrivateKeyData: Data = sourceForPrivateKey.data(using: String.Encoding.utf8)!
		PrivateKey = sha256(sourceForPrivateKeyData)
		PublicKey = generatePublicKey(PrivateKey!)
		Address = bioAddress.forKey(PublicKey!)
		WIF = bioAddress.wifFromPrivateKey(PrivateKey!)
	}
}
