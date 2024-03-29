//
//  AppDelegate.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/11/30.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		initDB()
		
		self.window = UIWindow(frame: UIScreen.main.bounds)
		
		let mainController = UINavigationController()
		mainController.pushViewController(HomeViewController(), animated: false)
		
		self.window?.rootViewController = mainController
		self.window?.makeKeyAndVisible()
		return true
	}
	
	private func initDB() {
		setEnableSQueryDebug(DEBUG_MODE)

		// Create: App Support Dirctory (for DB storage)
		let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
		do {
			try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		} catch  {}
		
		// *** for DEBUG ***
		if ENABLE_STARTUP_RESET_DB {
			let _ = SQuery(at: "\(path)\(USER_DB_FILENAME)").from(Anime.tableName)?.drop()
		}
		
		AnimeDataManager.shared.createDbTables()
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        excuteAutoBackup_ifNeed()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

