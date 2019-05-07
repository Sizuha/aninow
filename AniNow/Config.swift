//
//  config.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/03.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation

public var DEBUG_MODE: Bool {
	#if DEBUG
	return true
	#else
	return false
	#endif
}

public let USER_DB_FILE = "user.db"
public let BEGIN_OF_YEAR = 1970

// for DEBUG
public let ENABLE_STARTUP_RESET_DB = DEBUG_MODE && false

public var iCloudBackupUrl: URL? {
	let url = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.kishe.sizuha.aninow")?.appendingPathComponent("Backup")
	do {
		try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
		return url
	}
	catch {
		return nil
	}
}
