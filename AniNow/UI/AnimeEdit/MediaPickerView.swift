//
//  MediaPickerView.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUtil
import SizUI

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
	
	// MARK: - SizPopupPickerViewDelegate
	
    func pickerView(_ pickerView: UIPickerView, didSelect rows: [Int]) {
		onSelected?(rows[0])
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
