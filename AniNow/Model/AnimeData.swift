//
//  AnimeData.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/11/30.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation
import SQuery
import SizUtil

enum SortType: Int {
	case byTitle = 1
	case byDate = 2
	case byRating = 3
	case byMedia = 4
}

//------ Anime

class Anime: SQueryRow, CsvSerializable {
	
	static let tableName = "anime"
	static let F_IDX = "idx"
	static let F_TITLE = "title"
	static let F_TITLE_OTHER = "title_other"
	static let F_START_DATE = "start_date"
	static let F_MEDIA = "media"
	static let F_PROGRESS = "progress"
	static let F_TOTAL = "total"
	static let F_FIN = "fin"
	static let F_RATING = "rating"
	static let F_MEMO = "memo"
	static let F_LINK = "link"
	static let F_IMG_PATH = "img_path"
	static let F_REMOVED = "removed"
	
	// auto inc
	private var idx = -1
	var id: Int { return idx }
	
	var title = ""
	var titleOther = ""
	
	private let fmtYearMonth: DateFormatter
	
	// yyyyMM
	var startDate: YearMonth? = nil
	
	var media: Int = 0
	
	// 話
	var progress: Float = 0.0
	var total = 0
	var finished = false
	
	// 0 ~ 5
	var rating: Float = 0.0
	func getStarRating() -> String {
		let stars = Int(self.rating)
		var star = ""
		for _ in stride(from: 0, to: stars, by: 1) {
			star.append(Strings.STAR)
		}
		return star
	}
	
	var memo = ""
	var link = ""
	var imagePath = ""
	
	var removed = false
	
	init() {
		self.fmtYearMonth = DateFormatter()
		self.fmtYearMonth.locale = SQuery.standardLocal
		self.fmtYearMonth.dateFormat = "yyyyMM"
		self.fmtYearMonth.timeZone = SQuery.utcTimeZone
	}
	
	private func reset() {
		self.idx = 0
		self.title = ""
		self.titleOther = ""
		self.startDate = nil
		self.media = 0
		self.progress = 0
		self.total = 0
		self.finished = false
		self.rating = 0
		self.memo = ""
		self.link = ""
		self.imagePath = ""
		self.removed = false
	}
	
	func load(from cursor: SQLiteCursor) {
		cursor.forEachColumn { cur, i in
			let colName = cur.getColumnName(i)
			switch colName {
			case Anime.F_IDX: self.idx = cur.getInt(i) ?? -1
			
			case Anime.F_TITLE: self.title = cur.getString(i) ?? ""
			case Anime.F_TITLE_OTHER: self.titleOther = cur.getString(i) ?? ""
			
			case Anime.F_START_DATE:
				if let yyyyMM = cur.getInt(i) {
					self.startDate = YearMonth(from: yyyyMM)
				}
				else {
					self.startDate = nil
				}
				
			case Anime.F_MEDIA:
				self.media = cur.getInt(i) ?? 0
				
			case Anime.F_PROGRESS:
				self.progress = cur.getFloat(i) ?? 0
			case Anime.F_TOTAL:
				self.total = cur.getInt(i) ?? 0
			case Anime.F_FIN:
				self.finished = cur.getBool(i) == true
			case Anime.F_RATING:
				self.rating = cur.getFloat(i) ?? 0
			case Anime.F_MEMO:
				self.memo = cur.getString(i) ?? ""
			case Anime.F_LINK: self.link =
				cur.getString(i) ?? ""
			case Anime.F_IMG_PATH: self.imagePath =
				cur.getString(i) ?? ""
			case Anime.F_REMOVED: self.removed =
				cur.getBool(i) == true
			default: break
			}
		}
	}
	
	func toValues() -> [String:Any?] {
		return [
			Anime.F_IDX: self.idx,
			Anime.F_TITLE: self.title,
			Anime.F_TITLE_OTHER: self.titleOther,
			Anime.F_START_DATE: self.startDate?.toInt(),
			Anime.F_MEDIA: self.media,
			Anime.F_PROGRESS: self.progress,
			Anime.F_TOTAL: self.total,
			Anime.F_FIN: self.finished,
			Anime.F_RATING: self.rating,
			Anime.F_MEMO: self.memo,
			Anime.F_LINK: self.link,
			Anime.F_IMG_PATH: self.imagePath,
			Anime.F_REMOVED: self.removed
		]
	}
	
	func toCsv() -> [String] {
		var result = [String]()
		if !self.removed {
			result.append(self.title)
			result.append(self.titleOther)
			result.append("\(self.media)")
			result.append("\(self.startDate?.toInt() ?? 0)")
			result.append("\(self.progress)")
			result.append("\(self.total)")
			result.append(finished ? "1" : "0")
			result.append("\(Int(self.rating))")
			result.append(self.memo)
			result.append(self.link)
			result.append(self.imagePath)
		}
		return result
	}
	
	func load(from csvColumn: SizCsvParser.ColumnData) {
		switch csvColumn.colIdx {
		case 0: self.title = csvColumn.data
		case 1: self.titleOther = csvColumn.data
		case 2: self.media = csvColumn.asInt ?? 0
		case 3: self.startDate = YearMonth(from: csvColumn.asInt ?? 0)
		case 4: self.progress = csvColumn.asFloat ?? 0
		case 5: self.total = csvColumn.asInt ?? 0
		case 6: self.finished = csvColumn.asBool
		case 7: self.rating = csvColumn.asFloat ?? 0
		case 8: self.memo = csvColumn.data
		case 9: self.link = csvColumn.data
		case 10: self.imagePath = csvColumn.data
		default:
			break
		}
	}
}
