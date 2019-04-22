//
//  SecondViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/11/30.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery

class FinishedViewController: AnimeItemsViewController {

	override func getTitle() -> String {
		return Strings.END_VIEWING
	}
	
	override func applyFilter(to target: TableQuery) {
		super.applyFilter(to: target)
		let _ = target.whereAnd("fin=?", true)
	}
	
	override func createNewItem() -> Anime {
		let item = super.createNewItem()
		item.finished = true
		return item
	}
}

