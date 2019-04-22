//
//  Settings.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/17.
//  Copyright © 2018 Sizuha's Atelier. All rights reserved.
//

import Foundation
import SQuery

class Settings {
	
	private static var sharedInstance: Settings? = nil
	static var shared: Settings {
		return sharedInstance ?? Settings()
	}
	
	private var pref: UserDefaults {
		return UserDefaults.standard
	}
	
	private init() {}
	
	var lastBackupDate: Date? {
		get {
			let dateStr = self.pref.string(forKey: "last_backup")
			return SQuery.newDateTimeFormat().date(from: dateStr ?? "")
		}
		set(date) {
			self.pref.setValue(
				date == nil ? nil : SQuery.newDateTimeFormat().string(from: date!),
				forKey: "last_backup"
			)
		}
	}
	
	var sortType: SortType {
		get {
			let rawVal = self.pref.integer(forKey: "sort_by")
			return SortType(rawValue: rawVal) ?? .byTitle
		}
		set(value) {
			self.pref.set(value.rawValue, forKey: "sort_by")
		}
	}
	var sortDesc: Bool {
		get {
			return self.pref.bool(forKey: "sort_desc")
		}
		set(value) {
			self.pref.set(value, forKey: "sort_desc")
		}
	}
	
}
