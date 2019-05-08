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
		let stars = Int(rating)
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
		fmtYearMonth = DateFormatter()
		fmtYearMonth.locale = Locale.standard
		fmtYearMonth.dateFormat = "yyyyMM"
		fmtYearMonth.timeZone = TimeZone.utc
	}
	
	private func reset() {
		idx = 0
		title = ""
		titleOther = ""
		startDate = nil
		media = 0
		progress = 0
		total = 0
		finished = false
		rating = 0
		memo = ""
		link = ""
		imagePath = ""
		removed = false
	}
	
	func load(from cursor: SQLiteCursor) {
		cursor.forEachColumn { cur, i in
			let colName = cur.getColumnName(i)
			switch colName {
			case Anime.F_IDX: idx = cur.getInt(i) ?? -1
			
			case Anime.F_TITLE: title = cur.getString(i) ?? ""
			case Anime.F_TITLE_OTHER: titleOther = cur.getString(i) ?? ""
			
			case Anime.F_START_DATE:
				if let yyyyMM = cur.getInt(i) {
					startDate = YearMonth(from: yyyyMM)
				}
				else {
					startDate = nil
				}
				
			case Anime.F_MEDIA:
				media = cur.getInt(i) ?? 0
				
			case Anime.F_PROGRESS:
				progress = cur.getFloat(i) ?? 0
			case Anime.F_TOTAL:
				total = cur.getInt(i) ?? 0
			case Anime.F_FIN:
				finished = cur.getBool(i) == true
			case Anime.F_RATING:
				rating = cur.getFloat(i) ?? 0
			case Anime.F_MEMO:
				memo = cur.getString(i) ?? ""
			case Anime.F_LINK:
				link = cur.getString(i) ?? ""
			case Anime.F_IMG_PATH:
				imagePath = cur.getString(i) ?? ""
			case Anime.F_REMOVED:
				removed = cur.getBool(i) == true
			default: break
			}
		}
	}
	
	func toValues() -> [String:Any?] {
		return [
			Anime.F_IDX: idx,
			Anime.F_TITLE: title,
			Anime.F_TITLE_OTHER: titleOther,
			Anime.F_START_DATE: startDate?.toInt(),
			Anime.F_MEDIA: media,
			Anime.F_PROGRESS: progress,
			Anime.F_TOTAL: total,
			Anime.F_FIN: finished,
			Anime.F_RATING: rating,
			Anime.F_MEMO: memo,
			Anime.F_LINK: link,
			Anime.F_IMG_PATH: imagePath,
			Anime.F_REMOVED: removed
		]
	}
	
	func toCsv() -> [String] {
		var result = [String]()
		if !removed {
			result.append(title)
			result.append(titleOther)
			result.append("\(media)")
			result.append("\(startDate?.toInt() ?? 0)")
			result.append("\(progress)")
			result.append("\(total)")
			result.append(finished ? "1" : "0")
			result.append("\(Int(rating))")
			result.append(memo)
			result.append(link)
			result.append(imagePath)
			
			var mediaText = AnimeDataManager.shared.getMediaLable(media)
			if mediaText.isEmpty {
				mediaText = Strings.UNKNOWN
			}
			result.append(mediaText)
		}
		return result
	}
	
	func load(from csvColumn: SizCsvParser.ColumnData) {
		switch csvColumn.colIdx {
		case 0: title = csvColumn.data
		case 1: titleOther = csvColumn.data
		case 2: media = csvColumn.asInt ?? 0
		case 3: startDate = YearMonth(from: csvColumn.asInt ?? 0)
		case 4: progress = csvColumn.asFloat ?? 0
		case 5: total = csvColumn.asInt ?? 0
		case 6: finished = csvColumn.asBool
		case 7: rating = csvColumn.asFloat ?? 0
		case 8: memo = csvColumn.data
		case 9: link = csvColumn.data
		case 10: imagePath = csvColumn.data
		default:
			break
		}
	}
}
