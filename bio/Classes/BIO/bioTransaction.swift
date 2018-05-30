//
//  bioTransaction.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

class bioTransaction : NSObject {
	
	var version: UInt32 = 1
	var lock_time: UInt32 = 0
	
	var Input: [bioTransactionInput] = []
	var Output: [bioTransactionOutput] = []
	
	var Timestamp: Int? = nil
	var Block: String? = nil
	
	var Change: Wallet? = nil
	
	override init() {
		super.init()
		self.Change = Wallet()
	}
	
	func addOutput(address: String, amount: Double) -> Void {
		let value = BigInteger("\(Int(amount * pow(10, 8)))")
		let script: [UInt8] = bioAddress.spendToScript(address)
		Output.append(bioTransactionOutput(script, value, UInt64(amount * pow(10, 8))))
	}
	
	func addInput(_ tx: UnspentTransaction) -> Void {
		Input.append(bioTransactionInput(tx.address, tx.txid, tx.N, tx.Script, lock_time))
	}
	
	func addChange(amount summa: Double) -> Void {
		Change!.initialize(NSUUID().uuidString)
		addOutput(address: Change!.Address!, amount: summa)
	}
	
	func transactionHash(_ input: bioTransactionInput) -> Data {
		//Клонируем текущую транзакцию
		let tx = clone()
		
		//Во всем входы кроме переданного обнуляем Script
		for i in tx.Input {
			if i.outPoint.Hash != input.outPoint.Hash {
				i.Script = []
			} else {
				i.Script = input.Script.map { $0 }
			}
		}
		//Сериализуем
		var data = tx.serialize()
		//Добавляем в конец Int32(1) в виде 4-х байт
		data.append(contentsOf: Convert.toByteArray(UInt32(1)))
		//Считаем SHA256 от полученного массива
		let hash = Crypto.sha256(data)
		//Результат хешрования и возвращаем
		return Crypto.sha256(hash)
	}
	
	func deterministicK(_ address: Address, _ hash: Data, _ badrs: Int) -> BigInteger {
		let x = address.privateKey as Data
		let curve = EllipticCurve()
		let N = curve.N
		var v: Data = Data([UInt8](repeating: 1, count: 32))
		var k: Data = Data([UInt8](repeating: 0, count: 32))
		var vv = v
		vv.append(contentsOf: [0])
		vv.append(contentsOf: x)
		vv.append(contentsOf: hash)
		k = Crypto.hmac_sha256(vv, k)
		v = Crypto.hmac_sha256(v, k)
		vv = v
		vv.append(contentsOf: [1])
		vv.append(contentsOf: x)
		vv.append(contentsOf: hash)
		k = Crypto.hmac_sha256(vv, k)
		v = Crypto.hmac_sha256(v, k)
		v = Crypto.hmac_sha256(v, k)
		var KBigInt: BigInteger = BigInteger(Data(v))
		var i = 0
		while KBigInt.compareTo(N!) >= 0 || KBigInt.compareTo(BigInteger(0)) <= 0 || i < badrs {
			vv = v
			vv.append(contentsOf: [0])
			k = Crypto.hmac_sha256(vv, k)
			v = Crypto.hmac_sha256(v, k)
			v = Crypto.hmac_sha256(v, k)
			KBigInt = BigInteger(Data(v))
			i += 1
		}
		return KBigInt
	}
	
	func transactionSign(_ input: bioTransactionInput, _ address: Address) -> Data {
		let hash = transactionHash(input)
		let curve = EllipticCurve()
		let key = address.privateKey as Data
		let priv = BigInteger(key)
		let n = curve.N
		let e = BigInteger(hash)
		var badrs = 0
		var r: BigInteger = BigInteger(0)
		var s: BigInteger = BigInteger(0)
		repeat {
			let k = deterministicK(address, hash, badrs)
			let G = curve.G
			let Q = G!.multiply(k)
			r = Q.getX().toBigInteger().mod(n!)
			s = k.modInverse(n!).multiply(e.add(priv.multiply(r))).mod(n!)
			badrs += 1
		} while (r.compareTo(BigInteger(0)) <= 0 || s.compareTo(BigInteger(0)) <= 0)
		let halfn = n!.shiftRight(1)
		if s.compareTo(halfn) > 0 {
			s = n!.subtract(s)
		}
		var sig = serializeSign(r, s)
		sig.append(1)
		return sig
	}
	
	func serializeSign(_ r: BigInteger, _ s: BigInteger) -> Data {
		let rBa = r.toByteArraySigned()
		let sBa = s.toByteArraySigned()
		
		var sequence: Data = Data([UInt8]())
		sequence.append(UInt8(0x02))
		sequence.append(contentsOf: [UInt8(rBa.count)])
		sequence.append(contentsOf: rBa)
		sequence.append(contentsOf: [0x02])
		sequence.append(contentsOf: [UInt8(sBa.count)])
		sequence.append(contentsOf: sBa)
		sequence.insert(UInt8(sequence.count), at: 0)
		sequence.insert(UInt8(0x30), at: 0)
		return sequence
	}
	
	func signInput(_ input: bioTransactionInput, _ address: Address) -> Void {
		//Вычисляем подпись (Script)
		let key = (address.publicKey as Data)
		let signature = transactionSign(input, address)
		var script: [UInt8] = [UInt8]()
		var cnt = signature.count
		if cnt < 76 {
			script.append(UInt8(cnt))
		} else {
			if cnt < 0xff {
				script.append(76)
				script.append(UInt8(cnt))
			} else {
				if cnt < 0xffff {
					script.append(77)
					script.append(UInt8(cnt & 0xff))
					script.append(UInt8((cnt >> 8) & 0xff))
				} else {
					script.append(78)
					script.append(UInt8(cnt & 0xff))
					script.append(UInt8((cnt >> 8) & 0xff))
					script.append(UInt8((cnt >> 16) & 0xff))
					script.append(UInt8((cnt >> 24) & 0xff))
				}
			}
		}
		script.append(contentsOf: signature)
		cnt = key.count
		if cnt < 76 {
			script.append(UInt8(cnt))
		} else {
			if cnt < 0xff {
				script.append(76)
				script.append(UInt8(cnt))
			} else {
				if cnt < 0xffff {
					script.append(77)
					script.append(UInt8(cnt & 0xff))
					script.append(UInt8((cnt >> 8) & 0xff))
				} else {
					script.append(78)
					script.append(UInt8(cnt & 0xff))
					script.append(UInt8((cnt >> 8) & 0xff))
					script.append(UInt8((cnt >> 16) & 0xff))
					script.append(UInt8((cnt >> 24) & 0xff))
				}
			}
		}
		script.append(contentsOf: key)
		input.Script = script
	}

	func sign(_ addresses: [Address]) -> Data {
		for i in Input {
			let addr = addresses.filter { $0.address == i.outPoint.Address }
			signInput(i, addr.first!)
		}
		return serialize()
	}
	
	func serialize() -> Data {
		var data = [UInt8]()
		data.append(contentsOf: Convert.toByteArray(version))
		
		let time = Convert.toByteArray(UInt32(Date().timeIntervalSince1970)-60)
		
		for n in time {
			data.append(n);
		}
		
		data.append(contentsOf: Convert.toVarIntByteArray(UInt64(Input.count)))
		for i in Input {
			data.append(contentsOf: i.outPoint.Hash.hexa2Bytes.reversed())
			data.append(contentsOf: Convert.toByteArray(UInt32(i.outPoint.Index)))
			data.append(contentsOf: Convert.toVarIntByteArray(UInt64(i.Script.count)))
			if i.Script.count > 0 {
				data.append(contentsOf: i.Script)
			}
			data.append(contentsOf: Convert.toByteArray(UInt32(i.Sequence)))
		}
		
		data.append(contentsOf: Convert.toVarIntByteArray(UInt64(Output.count)))
		for o in Output {
			data.append(contentsOf: Convert.toByteArray(o.Satoshi))
			data.append(contentsOf: Convert.toVarIntByteArray(UInt64(o.ScriptedAddress.count)))
			data.append(contentsOf: o.ScriptedAddress)
		}
		
		data.append(contentsOf: Convert.toByteArray(UInt32(lock_time)))
		
		return Data(data)
	}
	
	func clone() -> bioTransaction {
		let retVal: bioTransaction = bioTransaction()
		retVal.version = version
		retVal.lock_time = lock_time
		retVal.Input = []
		for i in Input {
			retVal.Input.append(bioTransactionInput(i.outPoint.Address, i.outPoint.Hash, i.outPoint.Index, i.Script, lock_time))
		}
		retVal.Output = []
		for o in Output {
			retVal.Output.append(bioTransactionOutput(o.ScriptedAddress, o.Amount, o.Satoshi))
		}
		retVal.Timestamp = Timestamp
		retVal.Block = Block
		retVal.Change?.Address = Change?.Address
		retVal.Change?.PrivateKey = Change?.PrivateKey
		retVal.Change?.PublicKey = Change?.PublicKey
		retVal.Change?.WIF = Change?.WIF
		return retVal
	}
}
