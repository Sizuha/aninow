//
//  AnimeDataManager.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/19.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation
import SQuery
import SizUtil

protocol AnimeListFilter {
	func applyFilter(to target: TableQuery)
}

class AnimeDataManager {
	
	private let db: SQuery
	
	private init(source: String) {
		db = SQuery(at: source)
	}
	
	private static var sharedInstance: AnimeDataManager? = nil
	static var shared: AnimeDataManager {
		let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
		return sharedInstance ?? AnimeDataManager(source: "\(path)/\(USER_DB_FILE)")
	}
	
	func createDbTable() -> Bool {
		if let tableAnime = db.tableCreator(name: Anime.tableName) {
			defer { tableAnime.close() }
			return tableAnime
				.addAutoInc(Anime.F_IDX)
				.addColumn(Anime.F_TITLE, type: .text, notNull: true)
				.addColumn(Anime.F_TITLE_OTHER, type: .text)
				.addColumn(Anime.F_START_DATE, type: .integer)
				.addColumn(Anime.F_MEDIA, type: .integer)
				.addColumn(Anime.F_PROGRESS, type: .float)
				.addColumn(Anime.F_TOTAL, type: .integer)
				.addColumn(Anime.F_FIN, type: .integer)
				.addColumn(Anime.F_RATING, type: .float)
				.addColumn(Anime.F_MEMO, type: .text)
				.addColumn(Anime.F_LINK, type: .text)
				.addColumn(Anime.F_IMG_PATH, type: .text)
				.addColumn(Anime.F_REMOVED, type: .integer)
				.create(ifNotExists: true) != nil
		}
		return false
	}
	
	func loadItems(filter: AnimeListFilter, sortBy: SortType = .byTitle, sortAsc: Bool = true) -> [Anime] {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			
			let sortField: String
			switch sortBy {
			case .byMedia: sortField = "media"
			case .byDate: sortField = "start_date"
			case .byRating: sortField = "rating"
			default: sortField = "title"
			}
			
			filter.applyFilter(to: anime)
			return anime
				.whereAnd("removed IS NULL OR removed=0")
				.orderBy(sortField, desc: !sortAsc)
				.orderBy("title")
				.columns(
					Anime.F_IDX,
					Anime.F_TITLE,
					Anime.F_TITLE_OTHER,
					Anime.F_START_DATE,
					Anime.F_MEDIA,
					Anime.F_PROGRESS,
					Anime.F_TOTAL,
					Anime.F_RATING,
					Anime.F_FIN
				)
				.select { Anime() }.0
		}
		return [Anime]()
	}
	
	func loadDetail(id: Int) -> Anime? {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			return anime.setWhere("\(Anime.F_IDX)=?", id).selectOne { Anime() }.0
		}
		return nil
	}
	
	func count(finished: Bool? = nil) -> Int {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			
			if let finished = finished {
				let _ = anime.whereAnd("fin=?", finished)
			}
			return anime
				.whereAnd("removed IS NULL OR removed=0")
				.count() ?? 0
		}
		
		return 0
	}
	
	func countWithFilter(_ filter: (TableQuery)->Void) -> Int {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			
			filter(anime)
			return anime
				.whereAnd("removed IS NULL OR removed=0")
				.count() ?? 0
		}
		
		return 0
	}

	
	func addItem(_ item: Anime) -> Bool {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			return anime.insert(values: item, except: [Anime.F_IDX]).isSuccess
		}
		return false
	}
	
	func removeItem(_ item: Anime) -> Bool {
		return removeItem(id: item.id)
	}
	func removeItem(id: Int) -> Bool {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			return anime.setWhere("\(Anime.F_IDX)=?", id).delete().rowCount > 0
		}
		return false
	}
	
	func updateItem(_ item: Anime) -> Bool {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			let result = anime.keys(Anime.F_IDX).update(set: item).rowCount
			
			assert(result >= 1, "[Anime Data] 更新できませんでした")
			assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
			return result >= 1
		}
		return false
	}
	
	func updateFinishedStatus(id itemId: Int, isFinished: Bool) -> Bool {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			let result = anime
				.setWhere("\(Anime.F_IDX)=\(itemId)")
				.update(set: [Anime.F_FIN : isFinished])
				.rowCount
			
			assert(result >= 1, "[Anime Data] 更新できませんでした")
			assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
			return result >= 1
		}
		return false
	}
	
	func updateProgress(id itemId: Int, progress: Float) -> Bool {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			let result = anime
				.setWhere("\(Anime.F_IDX)=\(itemId)")
				.update(set: [Anime.F_PROGRESS : progress])
				.rowCount
			
			assert(result >= 1, "[Anime Data] 更新できませんでした")
			assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
			return result >= 1
		}
		return false
	}
	
	func loadAllItems() -> [Anime] {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			return anime
				.whereAnd("removed IS NULL OR removed=0")
				.select { Anime() }.0
		}
		return [Anime]()
	}
	
	func importFrom(file filepath: String) -> Int {
		var count = 0
		
		let loader = CsvDeserializer { Anime() }
		loader.headerLineCount = 1
		loader.importFrom(file: filepath) { item in
			if !item.title.isEmpty {
				if addItem(item) {
					count += 1
				}
			}
		}
		
		return count
	}
	
	func exportTo(file filepath: String) {
		let writer = CsvSerializer()
		writer.header = "backup_csv_header".localized()
		guard writer.beginExport(file: filepath) else { return }
		defer { writer.endExport() }
		
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			let _ = anime
				.whereAnd("removed IS NULL OR removed=0")
				.select(factory: { Anime() }) { row in
					writer.push(row: row)
				}
		}
	}
	
	func removeAll() {
		if let anime = db.from(Anime.tableName) {
			defer { anime.close() }
			let _ = anime.delete()
		}
	}
	
}
