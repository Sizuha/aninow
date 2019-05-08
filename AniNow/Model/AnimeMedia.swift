//
//  AnimeMedia.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import Foundation
import SQuery

class AnimeMedia: SQueryRow {
	
	static let tableName = "media"
	static let F_IDX = "idx"
	static let F_LABEL = "label"

	var idx: Int = 0
	var label: String = ""
	
	func load(from cursor: SQLiteCursor) {
		cursor.forEachColumn { cur, i in
			let name = cur.getColumnName(i)
			switch name {
			case AnimeMedia.F_IDX:
				idx = cur.getInt(i) ?? 0
			case AnimeMedia.F_LABEL:
				label = cur.getString(i) ?? ""
			default: break
			}
		}
	}
	
	func toValues() -> [String : Any?] {
		return [
			AnimeMedia.F_IDX: idx,
			AnimeMedia.F_LABEL: label
		]
	}
	
}
