//
//  YearFilteredViewController.swift
//  AniNow
//
//  Created by ILKYOUNG HWANG on 2021/12/28.
//  Copyright © 2021 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SQuery

class YearFilteredViewController: AnimeItemsViewController {
    
    override func getTitle() -> String {
        self.year == 0 ? Strings.UNKNOWN : String(format: Strings.FMT_YEAR, self.year)
    }
    
    var year: Int = 0
    
    override func applyFilter(to target: TableQuery) {
        super.applyFilter(to: target)
        _ = target.andWhere("\(Anime.F_START_DATE) BETWEEN ? AND ?", self.year * 100, self.year * 100 + 99)
    }
    
    override func createNewItem() -> Anime {
        let item = super.createNewItem()
        item.startDate = YearMonth(from: self.year * 100)
        return item
    }
    
}
