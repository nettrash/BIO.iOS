//
//  PersistentContainer.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import CoreData

class PersistentContainer: NSPersistentContainer {
	override class func defaultDirectoryURL() -> URL{
		return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ru.nettrash.biocoinwallet")!
	}
}
