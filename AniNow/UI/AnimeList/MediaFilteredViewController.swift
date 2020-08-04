//
//  MediaFilteredViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/25.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery

class MediaFilteredViewController: AnimeItemsViewController {
	
	override func getTitle() -> String {
		return AnimeDataManager.shared.getMediaLable(mediaFilter)
	}
	
	var mediaFilter: Int = 0
	
	override func applyFilter(to target: TableQuery) {
		super.applyFilter(to: target)
		let _ = target.andWhere("media=?", mediaFilter)
	}
	
	override func createNewItem() -> Anime {
		let item = super.createNewItem()
		item.media = mediaFilter
		return item
	}
	
}
