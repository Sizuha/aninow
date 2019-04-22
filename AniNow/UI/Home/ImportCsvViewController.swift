
//
//  ImportCsvViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/19.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil

class ImportCsvViewController: CommonUIViewController, UITableViewDataSource, UITableViewDelegate {
	
	class FileInfo {
		var filename: String = ""
	}
	
	private var filesView: UITableView!
	private var files = [FileInfo]()
	
	private var emptyView: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		initNavigationBar()
		initTableView()
		
		loadCsvList()		
	}
	
	private func initNavigationBar() {
		guard let navigationBar = self.navigationController?.navigationBar else { return }
		
		initNavigationBarStyle(navigationBar)		
		self.navigationItem.title = Strings.IMPORT
	}
	
	private func initTableView() {
		self.filesView = UITableView(frame: .zero, style: .plain)
		self.filesView.translatesAutoresizingMaskIntoConstraints = false
		self.filesView.tableFooterView = UIView()
		
		self.filesView.register(UITableViewCell.self, forCellReuseIdentifier: "file")
		self.filesView.dataSource = self
		self.filesView.delegate = self
		self.view.addSubview(self.filesView)
		
		self.emptyView = createEmptyView()
		self.emptyView.center = self.filesView.center
		self.view.addSubview(self.emptyView)
	}
	
	override func viewWillLayoutSubviews() {
		setMatchToParent(parent: self.view, child: self.filesView)
		
		self.emptyView.centerXAnchor.constraint(equalTo: self.filesView.centerXAnchor).isActive = true
		self.emptyView.centerYAnchor.constraint(
			equalTo: view.centerYAnchor,
			constant: -(self.tabBarController?.tabBar.frame.size.height ?? 0)).isActive = true
	}
	
	func loadCsvList() {
		self.files.removeAll()
		let fileManager = FileManager.default
		let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
		do {
			let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
			for fileUrl in fileURLs {
				let filename = fileUrl.lastPathComponent
				if filename.lowercased().hasSuffix(".csv") {
					let fielInfo = FileInfo()
					fielInfo.filename = filename
					self.files.append(fielInfo)
				}
			}
		}
		catch {
			print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
		}
		
		self.emptyView.isHidden = !self.files.isEmpty
		sortItems()
	}
	
	func sortItems() {
		self.files.sort { fileInfoA, fileInfoB in
			return fileInfoA.filename.compare(fileInfoB.filename).rawValue > 0
		}
	}
	
	func confirmImport(file: String, indexPath: IndexPath) {
		SizAlertBuilder(style: .actionSheet)
			.setTitle(file)
			.setMessage(Strings.MSG_CONFIRM_IMPORT)
			.addAction(title: Strings.CLEAR_AND_IMPORT, style: .destructive) { _ in
				self.fadeOut { fin in
					if fin {
						self.startNowLoading()
						DispatchQueue.main.async {
							AnimeDataManager.shared.removeAll()
							self.importFromCsv(file: file)
						}
					}
				}
			}
			.addAction(title: Strings.APPEND_IMPORT) { _ in
				self.fadeOut { fin in
					if fin {
						self.startNowLoading()
						DispatchQueue.main.async {
							self.importFromCsv(file: file)
						}
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel) { _ in
				self.filesView.deselectRow(at: indexPath, animated: true)
			}
			.show(parent: self)
	}
	
	func importFromCsv(file: String) {
		let insertCount = AnimeDataManager.shared.importFrom(file: "\(SizPath.appDocument)/\(file)")
		
		stopNowLoading()
		fadeIn()
		
		SizAlertBuilder()
			.setMessage(String(format: Strings.FMT_END_IMPORT, insertCount))
			.addAction(title: Strings.OK) { _ in self.popSelf() }
			.show(parent: self)
	}
	
	//------ Table View Delegate
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.files.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.filesView.dequeueReusableCell(withIdentifier: "file")!
		
		let item = self.files[indexPath.row]
		cell.textLabel?.text = item.filename
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = self.files[indexPath.row]
		confirmImport(file: item.filename, indexPath: indexPath)
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let item = self.files[indexPath.row]
		return SizSwipeActionBuilder()
			.addAction(title: Strings.REMOVE, style: .destructive) { action, view, handler in
				do {
					try FileManager.default.removeItem(atPath: "\(SizPath.appDocument)/\(item.filename)")
					handler(true)
					
					//self.filesView.beginUpdates()
					self.files.remove(at: indexPath.row)
					//self.filesView.endUpdates()
					self.filesView.reloadData()
				}
				catch {
					handler(false)
				}
			}
			.createConfig(enableFullSwipe: false)
	}
	
}
