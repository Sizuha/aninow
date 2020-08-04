//
//  AnimeItemCell.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/12.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil
import SizUI

class AnimeItemCell: UITableViewCell, SizViewUpdater {
	
	static let cellHeight = CGFloat(74)
	
	@IBOutlet weak var txtTitle: UILabel!
	@IBOutlet weak var txtTitleCenter: UILabel!
	@IBOutlet weak var txtSubTitle: UILabel!
	@IBOutlet weak var txtRatingStar: UILabel!
	@IBOutlet weak var txtMedia: UILabel!
	@IBOutlet weak var txtDate: UILabel!
	@IBOutlet weak var txtProgress: UILabel!
	
	public var title: String {
		get {
			return self.txtTitle.text ?? ""
		}
		set(text) {
			self.txtTitle.text = text
			self.txtTitleCenter.text = text
		}
	}
	
	public var SubTitle: String {
		get { return self.txtSubTitle.text ?? "" }
		set(text) { self.txtSubTitle.text = text }
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		onInit()
	}
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	private func onInit() {
		// nothing
	}
	
	override var textLabel: UILabel? {
		return nil
	}
	
	override var detailTextLabel: UILabel? {
		return nil
	}
	
	func setRating(_ stars: Int) {
		var star = ""
		for _ in stride(from: 0, to: stars, by: 1) {
			star.append(Strings.STAR)
		}
		txtRatingStar.text = star
	}
	
	func setProgress(current: Float, max: Int) {
		let progressFmt = NumberFormatter()
		progressFmt.minimumFractionDigits = 0
		progressFmt.maximumFractionDigits = 1
		
		let currStr = progressFmt.string(for: current) ?? "0"
		let maxStr = max > 0 ? "\(max)" : Strings.NONE_VALUE
		
		txtProgress.text = "Episode: \(currStr) / " + maxStr
	}
	
	func setMedia(_ media: Int) {
		txtMedia.text = AnimeDataManager.shared.getMediaLable(media)
	}
	
	func setDate(_ date: YearMonth) {
		txtDate.text = date.toString()
	}

	func refreshViews() {
		let isEmptySubTitle = txtSubTitle.text?.isEmpty ?? true
		txtSubTitle.isHidden = isEmptySubTitle
		txtTitle.isHidden = isEmptySubTitle
		txtTitleCenter.isHidden = !isEmptySubTitle
		
		txtMedia.layer.masksToBounds = true
		txtMedia.layer.cornerRadius = 7
		txtMedia.layer.shadowRadius = 0
	}
}
