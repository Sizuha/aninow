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
	
    /// 最後にバックアップした日時
	var lastBackupDate: Date? {
		get {
			let dateStr = self.pref.string(forKey: "last_backup")
			return SQuery.newDateTimeFormat().date(from: dateStr ?? "")
		}
		set {
			self.pref.setValue(
				newValue == nil ? nil : SQuery.newDateTimeFormat().string(from: newValue!),
				forKey: "last_backup"
			)
		}
	}
    
    var autoBackupMode: AutoBackupMode {
        get {
            let i = self.pref.integer(forKey: "auto_backup_mode")
            return AUTO_BACKUP_OPTIONS[at: i] ?? .none
        }
        set {
            let i = AUTO_BACKUP_OPTIONS.firstIndex(of: newValue) ?? 0
            self.pref.set(i, forKey: "auto_backup_mode")
        }
    }
	
	var sortType: SortType {
		get {
			let rawVal = self.pref.integer(forKey: "sort_by")
			return SortType(rawValue: rawVal) ?? .byTitle
		}
		set {
			self.pref.set(newValue.rawValue, forKey: "sort_by")
		}
	}
	var sortDesc: Bool {
		get {
			return self.pref.bool(forKey: "sort_desc")
		}
		set {
			self.pref.set(newValue, forKey: "sort_desc")
		}
	}
	
}

enum AutoBackupMode {
    case none, monthly, weekly, daily
    
    func toString() -> String {
        switch self {
        case .daily: return Strings.AUTO_BACKUP_DAILY
        case .weekly: return Strings.AUTO_BACKUP_WEEKLY
        case .monthly: return Strings.AUTO_BACKUP_MONTHLY
        default: return Strings.AUTO_BACKUP_NONE
        }
    }
}

let AUTO_BACKUP_OPTIONS: [AutoBackupMode] = [.none, .daily, .weekly, .monthly]

func excuteAutoBackup_ifNeed() {
    guard Settings.shared.autoBackupMode != .none else { return }
    
    func backup(_ now: Date? = nil) {
        if AnimeDataManager.shared.backup() {
            Settings.shared.lastBackupDate = now ?? Date()
        }
    }
    
    guard let last = Settings.shared.lastBackupDate else {
        backup()
        return
    }
    
    let cal = Calendar.standard
    let next: Date?
    
    let mode = Settings.shared.autoBackupMode
    switch mode {
    case .monthly:
        next = cal.date(byAdding: .month, value: 1, to: last)
        
    case .weekly:
        next = cal.date(byAdding: .day, value: 7, to: last)
        
    case .daily:
        next = cal.date(byAdding: .day, value: 1, to: last)
        
    default: assert(false); return
    }
    
    let now = Date()
    if let date = next, now >= date  {
        backup(now)
    }
}
