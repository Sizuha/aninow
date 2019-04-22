//
//  AnimeTableView.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/27.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil

class AnimeTableView: SizSectionTableView<Anime> {
	
	override init(frame: CGRect, style: UITableView.Style, owner: UIViewController) {
		super.init(frame: frame, style: style, owner: owner)

		headerTextColor = UIColor.brown
		register(nibName: "AnimeItemCell", cellResId: "ani_item")
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func height(rowAt: IndexPath) -> CGFloat {
		return AnimeItemCell.cellHeight
	}
	
	override func getCell(rowAt: IndexPath) -> UITableViewCell {
		let item = self.sections[rowAt.section].items[rowAt.row]
		let cellView = dequeueReusableCell(withIdentifier: "ani_item", for: rowAt)
		if let cell = cellView as? AnimeItemCell {
			cell.title = item.title
			cell.SubTitle = item.titleOther
			cell.setRating(Int(item.rating))
			cell.setDate(item.startDate ??  YearMonth())
			cell.setMedia(item.media)
			cell.setProgress(current: item.progress, max: item.total)
		}
		return cellView
	}
	
	override func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {
		(cell as? SizViewUpdater)?.refreshViews()
	}
	
//	override func leadingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? {
//		let item = self.sections[indexPath.section].items[indexPath.row]
//		guard !item.finished else { return nil }
//
//		return SizSwipeActionBuilder()
//			.addAction(title: Strings.LABEL_FIN, bgColor: .brown) { action, view, handler in
//				let result = self.moveToFinished(item, indexPath: indexPath)
//				handler(result)
//			}
//			.createConfig(enableFullSwipe: true)
//	}
	
	override func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? {
		let item = self.sections[rowAt.section].items[rowAt.row]
		
		return SizSwipeActionBuilder()
			.addAction(title: Strings.REMOVE, style: .destructive) { action, view, handler in
				self.tryRemove(rowAt, handler: handler)
			}
			.addAction(title: Strings.EDIT, bgColor: .blue) { action, view, handler in
				handler(true)
				openEditAnimePage(self.parentViewController, item: item)
			}
			.createConfig()
	}
	
	func tryRemove(_ indexPath: IndexPath, handler: @escaping (Bool)->Void) {
		let item = self.sections[indexPath.section].items[indexPath.row]
		
		SizAlertBuilder(message: Strings.MSG_CONFIRM_REMOVE, style: .actionSheet)
			.addAction(title: Strings.REMOVE, style: .destructive) { _ in
				handler(false)
				let _ = self.remove(item, indexPath: indexPath)
			}
			.addAction(title: Strings.CANCEL, style: .cancel) { _ in handler(false) }
			.show(parent: self.parentViewController)
	}
	
	private func remove(_ item: Anime, indexPath: IndexPath) -> Void {
		if AnimeDataManager.shared.removeItem(id: item.id) {
			removeItem(indexPath: indexPath) { $0.id == item.id }
		}
		else {
			let dlg = createAlertDialog(title: Strings.REMOVE, message: Strings.ERR_FAIL_REMOVE, buttonText: Strings.OK)
			parentViewController.present(dlg, animated: true, completion: nil)
		}
	}
	
//	private func moveToFinished(_ item: Anime, indexPath: IndexPath) -> Bool {
//		let result = AnimeDataManager.shared.updateFinishedStatus(id: item.id, isFinished: true)
//		reloadData()
//		return result
//	}
	
	override func didSelect(item: Anime, rowAt: IndexPath) {
		openAnimeViewPage(item: item)
	}
	
	func openAnimeViewPage(item: Anime) {
		parentViewController.navigationController?
			.pushViewController(AnimeViewController(item: item), animated: true)
	}
	
}
