//
//  Convert.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

class Convert {
	
	static func toByteArray<T>(_ value: T) -> [UInt8] {
		var value = value
		return withUnsafeBytes(of: &value) { Array($0) }
	}
	
	static func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
		return value.withUnsafeBytes {
			$0.baseAddress!.load(as: T.self)
		}
	}
	
	static func toVarIntByteArray(_ value: UInt64) -> [UInt8] {
		if value < 253 {
			return toByteArray(UInt8(value))
		}
		if value < 65536 {
			var retVal: [UInt8] = [253]
			retVal.append(contentsOf: toByteArray(UInt16(value)))
			return retVal
		}
		if value < 4294967296 {
			var retVal: [UInt8] = [254]
			retVal.append(contentsOf: toByteArray(UInt32(value)))
			return retVal
		}
		var retVal: [UInt8] = [255]
		retVal.append(contentsOf: toByteArray(UInt64(value)))
		return retVal
	}
}
