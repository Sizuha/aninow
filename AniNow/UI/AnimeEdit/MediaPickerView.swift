//
//  MediaPickerView.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import Foundation
import SizUtil

class MediaPickerView: SizPopupPickerView, UIPickerViewDataSource, SizPopupPickerViewDelegate {
	
	let medias = AnimeDataManager.shared.loadMedias().sorted(by: <)
	var onSelected: ((_ number: Int)->Void)? = nil
	
	override init() {
		super.init()
		
		setDataSource(self)
		delegate = self
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	//------ SizPopupPickerViewDelegate
	
	func pickerView(pickerView: UIPickerView, didSelect numbers: [Int]) {
		onSelected?(numbers[0])
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return medias.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return medias[row].value
	}
	
}
