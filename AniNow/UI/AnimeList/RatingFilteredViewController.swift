//
//  RatingFilteredViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/25.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery

class RatingFilteredViewController: AnimeItemsViewController {
	
	override func getTitle() -> String {
		return getRatingToStarText(self.rating)
	}
	
	var rating: Int = 0
	
	override func applyFilter(to target: TableQuery) {
		super.applyFilter(to: target)
		let _ = target.andWhere("rating >= ? AND rating < ?", self.rating, self.rating + 1)
	}
	
	override func createNewItem() -> Anime {
		let item = super.createNewItem()
		item.rating = Float(rating)
		return item
	}
	
}
