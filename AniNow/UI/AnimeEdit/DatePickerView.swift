//
//  DatePickerView.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUI
import SizUtil

class DatePickerView: SizPopupPickerView, UIPickerViewDataSource, SizPopupPickerViewDelegate {
	
	private var yearList = [(Int,String)]()
	var years: [(Int,String)] {
		return yearList
	}
	
	private var monthList = [(Int,String)]()
	var months: [(Int,String)] {
		return monthList
	}

	
	private let calendar = Calendar(identifier: .gregorian)
	private let today = Date()
	
	var onSelected: ((_ numbers: [Int])->Void)? = nil

	override init() {
		super.init()
		
		yearList.append( (0, Strings.UNKNOWN) )
		let todayYear = calendar.component(.year, from: self.today)
		for y in stride(from: todayYear, to: BEGIN_OF_YEAR-1, by: -1) {
			yearList.append( (y, String(format: Strings.FMT_YEAR, y)) )
		}
		
		monthList.append( (0, Strings.UNKNOWN) )
		for m in 1...12 {
			monthList.append( (m, String(format: Strings.FMT_MONTH, m)) )
		}
		
		setDataSource(self)
		delegate = self
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - SizPopupPickerViewDelegate
	
    func pickerView(_ pickerView: UIPickerView, didSelect numbers: [Int]) {
		onSelected?(numbers)
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0: return self.yearList.count
		case 1: fallthrough
		default: return self.monthList.count
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch component {
		case 0: return yearList[row].1
		case 1: fallthrough
		default: return monthList[row].1
		}
	}

}
