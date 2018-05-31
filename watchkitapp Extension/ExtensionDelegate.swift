//
//  ExtensionDelegate.swift
//  watchkitapp Extension
//
//  Created by Иван Алексеев on 31.05.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import WatchKit
import CoreData
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
	
	var session: WCSession?
	var addresses: [String]? = []
	var delegate: ApplicationContextDelegate?
	var qrReceive: UIImage?
	
	public var persistentContainer: PersistentContainer = {
		let container = PersistentContainer(name: "bio")
		container.loadPersistentStores(completionHandler: { (storeDescription:NSPersistentStoreDescription, error:Error?) in
			if let error = error as NSError?{
				fatalError("UnResolved error \(error), \(error.userInfo)")
			}
		})
		
		return container
	}()
	
	func applicationDidFinishLaunching() {
		// Perform any final initialization of your application.
		addresses = UserDefaults.standard.value(forKey: "Addresses") as? [String]
		let d: Data? = UserDefaults.standard.value(forKey: "QR") as? Data
		if d != nil {
			qrReceive = UIImage.init(data: d!)
		}
		
		if WCSession.isSupported() {
			session = WCSession.default
			session?.delegate = self
			session?.activate()
		}
	}
	
	func applicationDidBecomeActive() {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillResignActive() {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, etc.
	}
	
	func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
		// Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
		for task in backgroundTasks {
			// Use a switch statement to check the task type
			switch task {
			case let backgroundTask as WKApplicationRefreshBackgroundTask:
				// Be sure to complete the background task once you’re done.
				backgroundTask.setTaskCompletedWithSnapshot(false)
			case let snapshotTask as WKSnapshotRefreshBackgroundTask:
				// Snapshot tasks have a unique completion call, make sure to set your expiration date
				snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
			case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
				// Be sure to complete the connectivity task once you’re done.
				connectivityTask.setTaskCompletedWithSnapshot(false)
			case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
				// Be sure to complete the URL session task once you’re done.
				urlSessionTask.setTaskCompletedWithSnapshot(false)
			default:
				// make sure to complete unhandled task types
				task.setTaskCompletedWithSnapshot(false)
			}
		}
	}
	
	func requestContext() {
		session?.sendMessage(["Context" : "Refresh"], replyHandler: nil, errorHandler: nil)
	}
	
	func requestQR() {
		session?.sendMessage(["ReceiveQR" : "Incoming"], replyHandler: nil, errorHandler: nil)
	}
	
	//WCSessionDelegate
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		if activationState == WCSessionActivationState.activated {
			requestContext()
		} else {
			delegate?.contextUpdated()
		}
	}
	
	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		addresses = applicationContext["Addresses"] as? [String]
		UserDefaults.standard.setValue(addresses, forKey: "Addresses")
		delegate?.contextUpdated()
	}
	
	public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
		qrReceive = UIImage.init(data: messageData)
		UserDefaults.standard.setValue(messageData, forKey: "QR")
		delegate?.qrUpdated();
	}
}

protocol ApplicationContextDelegate {
	func contextUpdated()
	func qrUpdated()
}
