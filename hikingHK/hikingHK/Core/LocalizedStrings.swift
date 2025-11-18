//
//  LocalizedStrings.swift
//  hikingHK
//
//  Created for storing localized strings
//

import Foundation

struct LocalizedStrings {
    static let shared = LocalizedStrings()
    
    private let strings: [AppLanguage: [String: String]] = [
        .english: englishStrings,
        .traditionalChinese: traditionalChineseStrings
    ]
    
    func getString(for key: String, language: AppLanguage) -> String {
        return strings[language]?[key] ?? strings[.english]?[key] ?? key
    }
    
    private static let englishStrings: [String: String] = [
        // Common
        "app.name": "Hiking HK",
        "ok": "OK",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "edit": "Edit",
        "close": "Close",
        "start": "Start",
        "stop": "Stop",
        "pause": "Pause",
        "resume": "Resume",
        "done": "Done",
        
        // Auth
        "auth.name": "Name",
        "auth.email": "Email",
        "auth.password": "Password",
        "auth.create.account": "Create your hiking account.",
        "auth.sign.in.description": "Sign in to sync your hikes, badges and plans.",
        "auth.create.account.button": "Create Account",
        "auth.sign.in": "Sign In",
        "auth.have.account": "Have an account? Sign in",
        "auth.new.hiker": "New hiker? Create account",
        "auth.preparing.storage": "Preparing secure storage…",
        
        // Profile
        "profile.title": "Profile",
        "profile.account": "Account",
        "profile.stats": "Statistics",
        "profile.achievements": "Achievements",
        "profile.achievements.badges": "Achievements & Badges",
        "profile.goals": "Goals",
        "profile.data.services": "Data & services",
        "profile.language": "Language",
        "profile.language.description": "Choose your preferred language",
        "profile.sign.out": "Sign Out",
        "profile.sign.out.confirm": "Are you sure you want to sign out?",
        
        // Stats
        "stats.planned": "planned",
        "stats.favorites": "favorites",
        "stats.logged": "logged",
        
        // Home
        "home.title": "Home",
        "home.quick.actions": "Quick Actions",
        "home.trail.alerts": "Trail Alerts",
        "home.offline.maps": "Offline Maps",
        "home.ar.identify": "AR Identify",
        "home.location.share": "Location Share",
        "home.start.tracking": "Start Tracking",
        "home.hike.records": "Hike Records",
        "home.recommendations": "Recommendations",
        "home.species.id": "Species ID",
        "home.journal": "Journal",
        "home.sos": "Emergency SOS",
        "home.sos.confirm": "This will open the location sharing feature where you can send an emergency SOS.",
        "home.sos.open.sharing": "Open Location Sharing",
        "home.featured.trail": "Featured Trail",
        "home.elev.gain": "Elev gain",
        "home.view.trail.plan": "View trail plan",
        "home.next.plans": "Next plans",
        "home.add": "Add",
        "home.no.hikes.scheduled": "No hikes scheduled",
        "home.tap.add.to.plan": "Tap Add to plan your first walk",
        "home.refresh.weather": "Refresh weather",
        "home.safety": "Safety",
        "home.sos.button": "SOS",
        
        // Trails
        "trails.title": "Trails",
        "trails.details": "Trail Details",
        "trails.distance": "Distance",
        "trails.duration": "Duration",
        "trails.difficulty": "Difficulty",
        "trails.district": "District",
        "trails.all.difficulties": "All difficulties",
        "trails.search.prompt": "Name or district",
        
        // Planner
        "planner.title": "Planner",
        "planner.choose.trail": "Choose trail",
        "planner.schedule": "Schedule",
        "planner.date": "Date",
        "planner.note": "Note (meet point, gear...)",
        "planner.preview": "Preview",
        "planner.select.trail": "Select a trail to see summary",
        "planner.saved": "Plan saved",
        "planner.saved.message": "Your hike has been added to your plans.",
        
        // Safety
        "safety.progress": "Progress",
        "safety.all.complete": "Great! You're all set for a safe hike.",
        "safety.complete.all": "Complete all items before heading out.",
        "safety.checklist.title": "Safety checklist",
        
        // Trail Alerts
        "alerts.no.active": "No Active Alerts",
        "alerts.all.clear": "All trails are clear. Enjoy your hike!",
        "alerts.critical": "Critical",
        "alerts.active": "Active Alerts",
        
        // Hike Plan
        "hike.plan.title": "Hike plan",
        "hike.plan.status": "Status",
        "hike.plan.mark.completed": "Mark as completed",
        "hike.plan.completed.on": "Completed on",
        "hike.plan.update": "Update plan",
        "hike.plan.delete": "Delete plan",
        "hike.plan.delete.message": "This hike will be removed from your planner.",
        
        // Hike Tracking
        "tracking.title": "Hike Tracking",
        "tracking.time": "Time",
        "tracking.distance": "Distance",
        "tracking.speed": "Speed",
        "tracking.altitude": "Altitude",
        "tracking.track.points": "Track Points",
        "tracking.select.trail": "Select Trail",
        
        // Hike Records
        "records.title": "Hike Records",
        "records.no.records": "No Hike Records",
        "records.start.tracking": "Start tracking your hiking activities to create records",
        "records.detail": "Hike Record",
        "records.route.track": "Route Track",
        "records.no.track.data": "No Track Data",
        "records.detailed.stats": "Detailed Statistics",
        "records.max.speed": "Max Speed",
        "records.max.altitude": "Max Altitude",
        "records.min.altitude": "Min Altitude",
        "records.elev.loss": "Elev Loss",
        "records.track.points": "Track Points",
        "records.elevation.profile": "Elevation Profile",
        "records.insufficient.data": "Insufficient Data",
        "records.3d.playback": "3D Track Playback",
        "records.delete": "Delete Record",
        "records.delete.confirm": "Are you sure you want to delete this hike record? This action cannot be undone.",
        
        // Location Sharing
        "location.sharing.title": "Location Sharing",
        "location.sharing.sharing": "Sharing Location",
        "location.sharing.not.sharing": "Not Sharing",
        "location.sharing.description": "Your real-time location is being shared with emergency contacts",
        "location.sharing.start.description": "Tap the button below to start sharing location",
        "location.sharing.start": "Start Sharing",
        "location.sharing.stop": "Stop Sharing",
        "location.sharing.sos": "Emergency SOS",
        "location.sharing.anomaly": "Anomaly Detection",
        "location.sharing.detected.at": "Detected at",
        "location.sharing.current.location": "Current Location",
        "location.sharing.latitude": "Latitude",
        "location.sharing.longitude": "Longitude",
        "location.sharing.altitude": "Altitude",
        "location.sharing.share.link": "Share Link",
        "location.sharing.copy.link": "Copy Link",
        "location.sharing.contacts": "Emergency Contacts",
        "location.sharing.no.contacts": "No Emergency Contacts",
        "location.sharing.add.contact.description": "Please add at least one emergency contact to use location sharing and emergency SOS features",
        "location.sharing.add.contact": "Add Emergency Contact",
        "location.sharing.contact.info": "Contact Information",
        "location.sharing.name": "Name",
        "location.sharing.phone": "Phone Number",
        "location.sharing.email": "Email (Optional)",
        "location.sharing.primary": "Primary",
        "location.sharing.sos.confirm": "Confirm Emergency SOS",
        "location.sharing.sos.message": "This will send your location and SOS message to all emergency contacts. Please confirm this is an emergency.",
        "location.sharing.send": "Send",
        
        // Species Identification
        "species.title": "Species Identification",
        "species.identifying": "Identifying...",
        "species.take.photo": "Take Photo",
        "species.photo.library": "Photo Library",
        "species.habitat": "Habitat",
        "species.distribution": "Distribution",
        "species.other.possibilities": "Other Possibilities",
        "species.unable.to.identify": "Unable to Identify",
        "species.history": "Identification History",
        "species.no.history": "No Identification History",
        "species.start.identifying": "Start identifying species to view history",
        
        // Recommendations
        "recommendations.title": "Trail Recommendations",
        "recommendations.settings": "Recommendation Settings",
        "recommendations.available.time": "Available Time",
        "recommendations.hours": "hours",
        "recommendations.regenerate": "Regenerate Recommendations",
        "recommendations.no.recommendations": "No Recommendations",
        "recommendations.adjust.preferences": "Please adjust your preferences or available time",
        "recommendations.for.you": "Recommended for You",
        "recommendations.match": "Match",
        "recommendations.view.details": "View Details",
        "recommendations.preferences": "Preferences",
        "recommendations.preferred.difficulty": "Preferred Difficulty",
        "recommendations.difficulty": "Difficulty",
        "recommendations.no.preference": "No Preference",
        "recommendations.preferred.distance": "Preferred Distance",
        "recommendations.min": "Min",
        "recommendations.max": "Max",
        
        // Journal
        "journal.title": "Journal",
        "journal.create": "Create Journal Entry",
        "journal.edit": "Edit Journal Entry",
        "journal.detail": "Journal Detail",
        
        // Achievements
        "achievements.title": "Achievements & Badges",
        "achievements.unlocked": "Unlocked",
        "achievements.total": "Total",
        "achievements.new.unlocked": "New Achievement Unlocked!",
        "achievements.congratulations": "Congratulations! You unlocked the",
        "achievements.achievement": "achievement!",
        "achievements.unlocked.on": "Unlocked on",
        "achievements.filter.all": "All"
    ]
    
    private static let traditionalChineseStrings: [String: String] = [
        // Common
        "app.name": "行山香港",
        "ok": "確定",
        "cancel": "取消",
        "save": "儲存",
        "delete": "刪除",
        "edit": "編輯",
        "close": "關閉",
        "start": "開始",
        "stop": "停止",
        "pause": "暫停",
        "resume": "繼續",
        
        // Profile
        "profile.title": "個人資料",
        "profile.account": "帳戶",
        "profile.stats": "統計",
        "profile.achievements": "成就",
        "profile.achievements.badges": "成就與徽章",
        "profile.goals": "目標",
        "profile.data.services": "數據與服務",
        "profile.language": "語言",
        "profile.language.description": "選擇您的偏好語言",
        "profile.sign.out": "登出",
        "profile.sign.out.confirm": "您確定要登出嗎？",
        
        // Stats
        "stats.planned": "已計劃",
        "stats.favorites": "收藏",
        "stats.logged": "已記錄",
        
        // Home
        "home.title": "首頁",
        "home.quick.actions": "快捷操作",
        "home.trail.alerts": "路線警示",
        "home.offline.maps": "離線地圖",
        "home.ar.identify": "AR 識別",
        "home.location.share": "位置分享",
        "home.start.tracking": "開始追蹤",
        "home.hike.records": "行山記錄",
        "home.recommendations": "智能推薦",
        "home.species.id": "物種識別",
        "home.journal": "日記",
        "home.sos": "緊急求救",
        "home.sos.confirm": "這將打開位置分享功能，您可以在那裡發送緊急求救。",
        "home.sos.open.sharing": "打開位置分享",
        "home.featured.trail": "精選路線",
        "home.elev.gain": "海拔上升",
        "home.view.trail.plan": "查看路線計劃",
        "home.next.plans": "即將計劃",
        "home.add": "添加",
        "home.no.hikes.scheduled": "尚無計劃的行山",
        "home.tap.add.to.plan": "點擊添加以計劃您的第一次行山",
        "home.refresh.weather": "刷新天氣",
        "home.safety": "安全",
        "home.sos.button": "緊急求救",
        
        // Trails
        "trails.title": "路線",
        "trails.details": "路線詳情",
        "trails.distance": "距離",
        "trails.duration": "時長",
        "trails.difficulty": "難度",
        "trails.district": "地區",
        "trails.all.difficulties": "所有難度",
        "trails.search.prompt": "名稱或地區",
        
        // Planner
        "planner.title": "計劃",
        "planner.choose.trail": "選擇路線",
        "planner.schedule": "時間表",
        "planner.date": "日期",
        "planner.note": "備註（集合點、裝備...）",
        "planner.preview": "預覽",
        "planner.select.trail": "選擇路線以查看摘要",
        "planner.saved": "計劃已儲存",
        "planner.saved.message": "您的行山計劃已添加到您的計劃中。",
        
        // Safety
        "safety.progress": "進度",
        "safety.all.complete": "太好了！您已準備好安全行山。",
        "safety.complete.all": "出發前請完成所有項目。",
        "safety.checklist.title": "安全檢查清單",
        
        // Trail Alerts
        "alerts.no.active": "尚無活躍警示",
        "alerts.all.clear": "所有路線暢通。享受您的行山之旅！",
        "alerts.critical": "緊急",
        "alerts.active": "活躍警示",
        
        // Hike Plan
        "hike.plan.title": "行山計劃",
        "hike.plan.status": "狀態",
        "hike.plan.mark.completed": "標記為已完成",
        "hike.plan.completed.on": "完成日期",
        "hike.plan.update": "更新計劃",
        "hike.plan.delete": "刪除計劃",
        "hike.plan.delete.message": "此行山將從您的計劃中移除。",
        
        // Hike Tracking
        "tracking.title": "行山追蹤",
        "tracking.time": "時間",
        "tracking.distance": "距離",
        "tracking.speed": "速度",
        "tracking.altitude": "海拔",
        "tracking.track.points": "軌跡點",
        "tracking.select.trail": "選擇路線",
        
        // Hike Records
        "records.title": "行山記錄",
        "records.no.records": "尚無行山記錄",
        "records.start.tracking": "開始追蹤您的行山活動以創建記錄",
        "records.detail": "行山記錄",
        "records.route.track": "路線軌跡",
        "records.no.track.data": "無軌跡數據",
        "records.detailed.stats": "詳細統計",
        "records.max.speed": "最高速度",
        "records.max.altitude": "最高海拔",
        "records.min.altitude": "最低海拔",
        "records.elev.loss": "海拔下降",
        "records.track.points": "軌跡點數",
        "records.elevation.profile": "海拔變化",
        "records.insufficient.data": "數據不足",
        "records.3d.playback": "3D 軌跡回放",
        "records.delete": "刪除記錄",
        "records.delete.confirm": "確定要刪除此行山記錄嗎？此操作無法撤銷。",
        
        // Location Sharing
        "location.sharing.title": "位置分享",
        "location.sharing.sharing": "正在分享位置",
        "location.sharing.not.sharing": "未分享位置",
        "location.sharing.description": "您的實時位置正在分享給緊急聯繫人",
        "location.sharing.start.description": "點擊下方按鈕開始分享位置",
        "location.sharing.start": "開始分享",
        "location.sharing.stop": "停止分享",
        "location.sharing.sos": "緊急求救",
        "location.sharing.anomaly": "異常檢測",
        "location.sharing.detected.at": "檢測時間",
        "location.sharing.current.location": "當前位置",
        "location.sharing.latitude": "緯度",
        "location.sharing.longitude": "經度",
        "location.sharing.altitude": "海拔",
        "location.sharing.share.link": "分享鏈接",
        "location.sharing.copy.link": "複製鏈接",
        "location.sharing.contacts": "緊急聯繫人",
        "location.sharing.no.contacts": "尚未添加緊急聯繫人",
        "location.sharing.add.contact.description": "請添加至少一個緊急聯繫人以使用位置分享和緊急求救功能",
        "location.sharing.add.contact": "添加緊急聯繫人",
        "location.sharing.contact.info": "聯繫人信息",
        "location.sharing.name": "姓名",
        "location.sharing.phone": "電話號碼",
        "location.sharing.email": "電子郵件（可選）",
        "location.sharing.primary": "主要",
        "location.sharing.sos.confirm": "確認發送緊急求救",
        "location.sharing.sos.message": "這將向所有緊急聯繫人發送您的位置和求救信息。請確認這是緊急情況。",
        "location.sharing.send": "發送",
        
        // Species Identification
        "species.title": "物種識別",
        "species.identifying": "正在識別...",
        "species.take.photo": "拍照",
        "species.photo.library": "相冊",
        "species.habitat": "棲息地",
        "species.distribution": "分佈",
        "species.other.possibilities": "其他可能",
        "species.unable.to.identify": "無法識別",
        "species.history": "識別歷史",
        "species.no.history": "尚無識別記錄",
        "species.start.identifying": "開始識別物種以查看歷史記錄",
        
        // Recommendations
        "recommendations.title": "智能推薦",
        "recommendations.settings": "推薦設置",
        "recommendations.available.time": "可用時間",
        "recommendations.hours": "小時",
        "recommendations.regenerate": "重新生成推薦",
        "recommendations.no.recommendations": "暫無推薦",
        "recommendations.adjust.preferences": "請調整您的偏好設置或可用時間",
        "recommendations.for.you": "為您推薦",
        "recommendations.match": "匹配度",
        "recommendations.view.details": "查看詳情",
        "recommendations.preferences": "偏好設置",
        "recommendations.preferred.difficulty": "偏好難度",
        "recommendations.difficulty": "難度",
        "recommendations.no.preference": "無偏好",
        "recommendations.preferred.distance": "偏好距離",
        "recommendations.min": "最小",
        "recommendations.max": "最大",
        
        // Journal
        "journal.title": "日記",
        "journal.create": "創建日記",
        "journal.edit": "編輯日記",
        "journal.detail": "日記詳情",
        
        // Achievements
        "achievements.title": "成就與徽章",
        "achievements.unlocked": "已解鎖",
        "achievements.total": "總數",
        "achievements.new.unlocked": "新成就解鎖！",
        "achievements.congratulations": "恭喜！您解鎖了",
        "achievements.achievement": "成就！",
        "achievements.unlocked.on": "解鎖時間",
        "achievements.filter.all": "全部"
    ]
}

