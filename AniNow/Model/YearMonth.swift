//
//  YearMonth.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/03.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation

class YearMonth {
	var year: Int
	var month: Int
	
	init() {
		year = 0
		month = 0
	}
	
	init(from yyyyMM: Int) {
		year = yyyyMM / 100
		month = yyyyMM - year*100
	}
	
	convenience init(from yyyyMM: String) {
		let value = Int(yyyyMM) ?? 0
		self.init(from: value)
	}
	
	convenience init(year: Int, month: Int) {
		self.init(from: year*100 + month)
	}

	init(from date: Date) {
		let cal = Calendar.init(identifier: .gregorian)
		year = cal.component(.year, from: date)
		month = cal.component(.month, from: date)
	}
	
	func toInt() -> Int {
		return year*100 + month
	}
	
	func toString() -> String {
		switch (year, month) {
		case (let y, let m) where y > 0 && m > 0:
			return String(format: Strings.FMT_YEAR_MONTH, year, month)
		case (let y, let m) where y > 0 && m <= 0:
			return String(format: Strings.FMT_YEAR, year)
		case (let y, let m) where y <= 0 && m > 0:
			return String(format: Strings.FMT_MONTH, month)
		default:
			return Strings.UNKNOWN
		}
	}
}
