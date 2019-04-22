//
//  NowViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery

class NowViewController: AnimeItemsViewController {
	
	override func getTitle() -> String {
		return Strings.NOW_VIEWING
	}
	
	override func applyFilter(to target: TableQuery) {
		super.applyFilter(to: target)
		let _ = target.whereAnd("fin=?", false)
	}
	
}
