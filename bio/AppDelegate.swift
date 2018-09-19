//
//  AppDelegate.swift
//  bio
//
//  Created by Иван Алексеев on 03.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var firstLaunch: Bool = true
	public var model: ModelRoot?
	var needToProcessURL: Bool = false
	var openUrl: URL? = nil
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		model = ModelRoot(self)
		
		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		let components = URLComponents.init(url: url, resolvingAgainstBaseURL: true)
		if components?.scheme?.lowercased() != "sibcoin" &&
			components?.scheme?.lowercased() != "biocoin" &&
			components?.scheme?.lowercased() != "bitcoin" &&
			components?.scheme?.lowercased() != "file" {
			return false
		}
		needToProcessURL = true
		openUrl = url
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		let defs = UserDefaults.standard
		defs.set(Date(), forKey: "backgroundDate")
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		let defs = UserDefaults.standard
		defs.set(Date(), forKey: "backgroundDate")
		
		let vc = UIApplication.topViewController()
		
		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.frame = vc!.view.bounds
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		vc!.view.addSubview(blurEffectView)
		vc!.view.endEditing(true)
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		let defs = UserDefaults.standard
		let d: Date? = defs.object(forKey: "backgroundDate") as? Date
		var timeoutPIN: Bool = true
		if d != nil {
			let dd = Date()
			let components = Calendar.current.dateComponents([.second], from: d!, to: dd)
			timeoutPIN = components.second! > 15
		}
		
		let vc = UIApplication.topViewController()
		for v in vc!.view.subviews {
			if v is UIVisualEffectView {
				v.removeFromSuperview()
			}
		}
		
		//Грузим PIN-код
		if !firstLaunch && window!.rootViewController is RootViewController && timeoutPIN {
			if !(vc is CheckPINViewController) {
				(window!.rootViewController as! RootViewController).dismiss(animated: false, completion: nil)
			} else {
				if !(vc as! CheckPINViewController).Checked {
					(vc as! CheckPINViewController).tfPIN0.becomeFirstResponder()
				}
			}
		} else {
		}
		
		if firstLaunch {
			firstLaunch = false
		}
		
		if vc is BaseViewController {
			(vc as! BaseViewController).processUrlCommand()
		}
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		self.saveContext()
	}
	
	// MARK: - Core Data stack
	
	lazy var persistentContainer: PersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = PersistentContainer(name: "bio")
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
				model!.syncWatch()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	// UPDATE
	
	func checkAvailableUpdate() -> Void {
		DispatchQueue.main.async {
			let manifest = NSDictionary.init(contentsOf: URL.init(string: "https://biocoin.shop/manifest.plist")!)
			
			let items = manifest?.value(forKey: "items") as? [NSDictionary?]
			if items?.count ?? 0 < 1 { return }
			let metadata = items?[0]?.value(forKey: "metadata") as? NSDictionary
			let version = metadata?.value(forKey: "bundle-version") as? String
			if version == nil { return }
			let nVersion: Double? = (Decimal.init(string: version!) as NSDecimalNumber?)?.doubleValue
			if nVersion == nil { return }
			
			let dictionary = Bundle.main.infoDictionary!
			let appversion = dictionary["CFBundleShortVersionString"] as! String
			let nAppVersion: Double? = (Decimal.init(string: appversion) as NSDecimalNumber?)?.doubleValue
			if nAppVersion == nil { return }
			
			if nVersion! > nAppVersion! {
				
				let alert = UIAlertController.init(title: NSLocalizedString("UpdateAvailableTitle", comment: "UpdateAvailableTitle"), message: NSLocalizedString("UpdateAvailableMessage", comment: "UpdateAvailableTitle"), preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("Update", comment: "Обновить"), style: UIAlertAction.Style.default, handler: { _ in
					UIApplication.shared.open(URL.init(string: "itms-services://?action=download-manifest&url=https://biocoin.shop/manifest.plist")!, options: [:], completionHandler: nil)
					alert.dismiss(animated: true, completion: nil) }))
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertAction.Style.cancel, handler: { _ in
					alert.dismiss(animated: true, completion: nil) }))
				let vc = UIApplication.topViewController()
				vc?.present(alert, animated: true, completion: nil)
				
			}
		}
	}

}

