//
//  Address+CoreDataProperties.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//
//

import Foundation
import CoreData


extension Address {

	@nonobjc public class func fetchRequest() -> NSFetchRequest<Address> {
		return NSFetchRequest<Address>(entityName: "Address")
	}
	
	@NSManaged public var privateKey: NSData
	@NSManaged public var publicKey: NSData
	@NSManaged public var address: String
	@NSManaged public var wif: String
	@NSManaged public var compressed: Bool
	@NSManaged public var type: Int16 // 0 - for receive 1 - for get change

}
