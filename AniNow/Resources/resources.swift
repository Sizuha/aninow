//
//  resources.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

public class Icons {
	static let STAR5_EMPTY = UIImage(named: "star5_empty")!
	static let STAR5_FILL = UIImage(named: "star5_fill")!
	static let SETTINGS = UIImage(named: "setting")!
}

public class Strings {
	static let STAR = "★"
	
	static let OK = "ok".localized()
	static let CANCEL = "cancel".localized()
	static let REMOVE = "remove".localized()
	static let ADD_NEW = "add_new".localized()
	static let EDIT = "edit".localized()
	
	static var LABEL_ANIME_LIST: String { return "anime_list".localized() }
	static var FILTER_MEDIA: String { return "filter_media".localized() }
	static var FILTER_RATING: String { return "filter_rating".localized() }
	
	static var SORT: String { return "sort".localized() }
	static var SORT_BY_TITLE: String { return "sort_f_title".localized() }
	static var SORT_BY_TITLE_DESC: String { return "sort_f_title_desc".localized() }
	static var SORT_BY_DATE: String { return "sort_f_date".localized() }
	static var SORT_BY_DATE_DESC: String { return "sort_f_date_desc".localized() }
	static var SORT_BY_RATING: String { return "sort_f_rating".localized() }
	static var SORT_BY_RATING_DESC: String { return "sort_f_rating_desc".localized() }
	static var SORT_BY_MEDIA: String { return "sort_f_media".localized() }

	static var ALL_VIEWING: String { return "all_view".localized() }
	static var NOW_VIEWING: String { return "now_view".localized() }
	static var END_VIEWING: String { return "finished".localized() }
	static var SETTING: String { return "setting".localized() }
	static var SELECT: String { return "select".localized() }
	
	static var ANIME_TITLE: String { return "anime_title".localized() }
	static var ANIME_TITLE_2ND: String { return "anime_title_2nd".localized() }
	static var MEDIA: String { return "media".localized() }
	static var MEMO: String { return "memo".localized() }
	static var EMPTY_MEMO: String { return "empty_memo".localized() }
	static var NO_CATEGORY: String { return "no_category".localized() }
	static var NONE_VALUE: String { return "none_value".localized() }
	static var NONE_VALUE2: String { return "none_value2".localized() }
	static var UNKNOWN: String { return "unknown".localized() }
	static var EMPTY_ITEMS: String { return "empty_items".localized() }
	static var NO_RATING: String { return "no_rating".localized() }
	static var NOT_USED: String { return "not_used".localized() }
	
	static var LABEL_FIN: String { return "label_fin".localized() }
	static var FINAL_EP: String { return "final_ep".localized() }
	static var LABEL_CURR_EP: String { return "label_progress".localized() }
	static var PUB_DATE: String { return "pub_date".localized() }
	static var RATING: String { return "rating".localized() }
	
	static var INFO: String { return "info".localized() }
	static var COUNT_NOW: String { return "count_now".localized() }
	static var COUNT_FINISHED: String { return "count_finished".localized() }
	static var BACKUP: String { return "backup".localized() }
	static var RESTORE: String { return "restore".localized() }
	static var IMPORT: String { return "import".localized() }
	static var EXPORT: String { return "export".localized() }
	static var LAST_BACKUP: String { return "last_backup".localized() }
	
	static var ERR_FAIL_REMOVE: String { return "err_fail_remove".localized() }
	static var ERR_FAIL_SAVE: String { return "err_fail_save".localized() }
	
	static var DELETE_ALL: String { return "delete_all".localized() }
	static var CLEAR_AND_IMPORT: String { return "clear_and_import".localized() }
	static var APPEND_IMPORT: String { return "append_import".localized() }
	static var MSG_FAIL: String { return "msg_fail".localized() }
	static var MSG_CONFIRM_REMOVE: String { return "msg_confirm_remove".localized() }
	static var MSG_CONFIRM_REMOVE_ALL: String { return "msg_confirm_remove_all".localized() }
	static var MSG_CONFIRM_EXPORT: String { return "msg_confirm_export".localized() }
	static var MSG_END_BACKUP: String { return "msg_end_backup".localized() }
	static var MSG_END_EXPORT: String { return "msg_end_export".localized() }
	static var MSG_CONFIRM_IMPORT: String { return "msg_confirm_import".localized() }
	static var MSG_CONFIRM_RESTORE: String { return "msg_confirm_restore".localized() }
    static var MSG_CONFIRM_BACKUP: String { return "msg_confirm_backup".localized() }
	static var FMT_END_IMPORT: String { return "fmt_end_import".localized() }
	static var MSG_NO_BACKUP: String { return "msg_no_backup".localized() }
	static var MSG_NOW_LOADING: String { return "msg_now_loading".localized() }
	static var MSG_END_RESTORE: String { return "msg_end_restore".localized() }

	static var FMT_YEAR: String { return "fmt_year".localized() }
	static var FMT_MONTH: String { return "fmt_month".localized() }
	static var FMT_YEAR_MONTH: String { return "fmt_year_month".localized() }
}
