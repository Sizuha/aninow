//
//  AnimeDataManager.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/19.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation
import SQuery
import SizUtil

protocol AnimeListFilter {
    func applyFilter(to target: TableQuery)
}

class AnimeDataManager {
    
    private let db: SQuery
    
    private init(source: URL) {
        db = SQuery(url: source, mode: .readWriteCreate)!
    }
    
    private static var sharedInstance: AnimeDataManager? = nil
    static var shared: AnimeDataManager {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return sharedInstance ?? AnimeDataManager(source: path.appendingPathComponent(USER_DB_FILENAME, isDirectory: false))
    }
    
    func createDbTables() {
        db.create(tables: [Anime.self, AnimeMedia.self])
        
        insertMedia(1, "OVA")
        insertMedia(2, "Movie")
        insertMedia(3, "TV")
        insertMedia(4, "Netflix")
    }
    
    //MARK: - Media Item
    
    private func insertMedia(_ idx: Int, _ label: String) {
        guard let table = db.from(AnimeMedia.tableName) else {
            assert(false)
            return
        }
        defer { table.close() }
        let _ = table
            .values([AnimeMedia.F_IDX: idx, AnimeMedia.F_LABEL: label])
            .insert()
    }
    
    func updateMedia(_ idx: Int, _ label: String) {
        guard let table = db.from(AnimeMedia.tableName) else {
            assert(false)
            return
        }
        defer { table.close() }
        let isOk = table
            .values([AnimeMedia.F_IDX: idx, AnimeMedia.F_LABEL: label])
            .insertOrUpdate()
        
        if DEBUG_MODE {
            print("isOk => \(isOk ? "O" : "X")")
        }
    }
    
    func deleteMedia(_ idx: Int) {
        guard let table = db.from(AnimeMedia.tableName) else {
            assert(false)
            return
        }

        defer { table.close() }
        let _ = table
            .andWhere("\(AnimeMedia.F_IDX) = ?", idx)
            .delete()
    }
    
    func loadMedias() -> [Int:String] {
        var result = [Int:String]()
        
        guard let table = db.from(AnimeMedia.tableName) else {
            assert(false)
            return result
        }

        defer { table.close() }
        let _ = table
            .andWhere("\(AnimeMedia.F_IDX) > 0")
            .select(factory: { AnimeMedia() }) { row in
            result[row.idx] = row.label
        }
        
        result[0] = Strings.NO_CATEGORY
        return result
    }
    
    func getMediaLable(_ code: Int) -> String {
        guard code >= 1 else {
            return Strings.NO_CATEGORY
        }
        guard let table = db.from(AnimeMedia.tableName) else {
            return Strings.UNKNOWN
        }
        defer { table.close() }
        
        let (row, _) = table
            .andWhere("idx=?", code)
            .selectOne { AnimeMedia() }
        
        guard let label = row?.label else {
            return Strings.UNKNOWN
        }
        return label
    }
    
    //MARK: - Anime Item
    
    func loadItems(filter: AnimeListFilter? = nil, sortBy: SortType = .byTitle, sortAsc: Bool = true) -> [Anime] {
        guard let anime = db.from(Anime.tableName) else { return [] }
        defer { anime.close() }
        
        let sortField: String
        switch sortBy {
        case .byMedia: sortField = "media"
        case .byDate: sortField = "start_date"
        case .byRating: sortField = "rating"
        default: sortField = "title"
        }
        
        filter?.applyFilter(to: anime)
        return anime
            .andWhere("removed IS NULL OR removed=0")
            .orderBy(sortField, desc: !sortAsc)
            .orderBy("title")
            .columns(
                Anime.F_IDX,
                Anime.F_TITLE,
                Anime.F_TITLE_OTHER,
                Anime.F_START_DATE,
                Anime.F_MEDIA,
                Anime.F_PROGRESS,
                Anime.F_TOTAL,
                Anime.F_RATING,
                Anime.F_FIN
            )
            .select { Anime() }.0
    }
    
    func loadDetail(id: Int) -> Anime? {
        guard let anime = db.from(Anime.tableName) else { return nil }
        defer { anime.close() }
        return anime.setWhere("\(Anime.F_IDX)=?", id).selectOne { Anime() }.0
    }
    
    func count(finished: Bool? = nil) -> Int {
        guard let anime = db.from(Anime.tableName) else { return 0 }
        defer { anime.close() }
        
        if let finished = finished {
            let _ = anime.andWhere("fin=?", finished)
        }
        return anime
            .andWhere("removed IS NULL OR removed=0")
            .count() ?? 0
    }
    
    func countWithFilter(_ filter: (TableQuery)->Void) -> Int {
        guard let anime = db.from(Anime.tableName) else { return 0 }
        defer { anime.close() }
        
        filter(anime)
        return anime
            .andWhere("removed IS NULL OR removed=0")
            .count() ?? 0
    }

    
    func addItem(_ item: Anime) -> Bool {
        guard let anime = db.from(Anime.tableName) else { return false }
        defer { anime.close() }
        return anime.insert(values: item, except: [Anime.F_IDX]).isSuccess
    }
    
    func removeItem(_ item: Anime) -> Bool {
        return removeItem(id: item.id)
    }
    func removeItem(id: Int) -> Bool {
        guard let anime = db.from(Anime.tableName) else { return false }
        defer { anime.close() }
        return anime.setWhere("\(Anime.F_IDX)=?", id).delete().rowCount > 0
    }
    
    func updateItem(_ item: Anime) -> Bool {
        guard let anime = db.from(Anime.tableName) else { return false }
        defer { anime.close() }
        let result = anime.keys(Anime.F_IDX).update(set: item).rowCount
        
        assert(result >= 1, "[Anime Data] 更新できませんでした")
        assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
        return result >= 1
    }
    
    func updateFinishedStatus(id itemId: Int, isFinished: Bool) -> Bool {
        guard let anime = db.from(Anime.tableName) else { return false }
        defer { anime.close() }
        let result = anime
            .setWhere("\(Anime.F_IDX)=\(itemId)")
            .update(set: [Anime.F_FIN : isFinished])
            .rowCount
        
        assert(result >= 1, "[Anime Data] 更新できませんでした")
        assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
        return result >= 1
    }
    
    func updateProgress(id itemId: Int, progress: Float) -> Bool {
        guard let anime = db.from(Anime.tableName) else { return false }
        defer { anime.close() }
        let result = anime
            .setWhere("\(Anime.F_IDX)=\(itemId)")
            .update(set: [Anime.F_PROGRESS : progress])
            .rowCount
        
        assert(result >= 1, "[Anime Data] 更新できませんでした")
        assert(result == 1, "[Anime Data] 2個以上のデータが更新されました")
        return result >= 1
    }
    
    func loadAllItems() -> [Anime] {
        guard let anime = db.from(Anime.tableName) else { return [] }
        defer { anime.close() }
        return anime
            .andWhere("removed IS NULL OR removed=0")
            .select { Anime() }.0
    }
    
    func removeAll() {
        guard let anime = db.from(Anime.tableName) else { return }
        defer { anime.close() }
        let _ = anime.delete()
    }

    //MARK: - import/export CSV
    
    func importFrom(url: URL) -> Int { importFrom(file: url.path) }
    
    func importFrom(file filepath: String) -> Int {
        var count = 0
        
        let loader = CsvDeserializer { Anime() }
        loader.headerLineCount = 1
        loader.importFrom(file: filepath) { item in
            if !item.title.isEmpty {
                if addItem(item) {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    func exportTo(url: URL) { exportTo(file: url.path) }
    
    func exportTo(file filepath: String) {
        let writer = CsvSerializer()
        writer.header = "backup_csv_header".localized()
        guard writer.beginExport(file: filepath) else { return }
        defer { writer.endExport() }
        
        if let anime = db.from(Anime.tableName) {
            defer { anime.close() }
            let _ = anime
                .andWhere("removed IS NULL OR removed=0")
                .select(factory: { Anime() }) { row in
                    writer.push(row: row)
                }
        }
    }
    
    //MARK: - backup/restore
    
    func syncBackupData() -> Bool {
        let url = iCloudBackupUrl?.appendingPathComponent(BACKUP_DB_FILENAME)
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url!)
            return true
        }
        catch let error {
            print("error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func copyDbFile(from fromUrl: URL, to toUrl: URL) -> Bool {
        let fileMng = FileManager.default
        do { try fileMng.removeItem(at: toUrl) } catch {
            print("fail: remove a target file")
        }
        do { try fileMng.copyItem(at: fromUrl, to: toUrl) } catch {
            print("fail: copy file")
            return false
        }
        
        return true
    }
    
    func backup() -> Bool {
        guard let iCloudUrl = iCloudBackupUrl else { return false }
        guard let appDocUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        let fromUrl = appDocUrl.appendingPathComponent(USER_DB_FILENAME)
        let toUrl = iCloudUrl.appendingPathComponent(BACKUP_DB_FILENAME)
        
        return copyDbFile(from: fromUrl, to: toUrl)
    }
    
    func restore() -> Bool {
        guard let fromUrl = iCloudBackupUrl?.appendingPathComponent(BACKUP_DB_FILENAME) else {
            return false
        }
        guard syncBackupData() else {
            return false
        }
        guard let appDocUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let toUrl = appDocUrl.appendingPathComponent(USER_DB_FILENAME)
        return copyDbFile(from: fromUrl, to: toUrl)
    }
    
}
