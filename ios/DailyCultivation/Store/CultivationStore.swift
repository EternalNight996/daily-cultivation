import CoreData
import Foundation
import TalismanKit

/// 本地记录：今日灵气、连续天数、总经验、施法明细。
/// V1 用 viewContext（每天 2–10 次写，量级极小），换来更少的合并问题；
/// 一旦每日写入超过百级，再换 newBackgroundContext + perform。
@MainActor
final class CultivationStore {
    struct Snapshot: Equatable {
        var streak: Int
        var longestStreak: Int
        var totalXp: Int
        var earnedToday: Int
        var castsToday: Int
        var totalCasts: Int
        var title: Title

        static let empty = Snapshot(streak: 0, longestStreak: 0, totalXp: 0,
                                    earnedToday: 0, castsToday: 0,
                                    totalCasts: 0, title: .fanren)

        var isFirstOfDay: Bool { castsToday == 0 }
    }

    /// 修行录里的一行
    struct Record: Identifiable, Equatable {
        let id: UUID
        let date: Date
        let qi: Int
        let score: Double
        let strokes: Int
        let shichen: Shichen
    }

    private enum Key {
        static let streak = "dc.v1.streak"
        static let longest = "dc.v1.longest"
        static let totalXp = "dc.v1.totalXp"
        static let totalCasts = "dc.v1.totalCasts"
        static let lastActive = "dc.v1.lastActive"
    }

    private let context: NSManagedObjectContext
    private let defaults: UserDefaults
    private let calendar = CultivationCalendar()

    init(container: NSPersistentContainer, defaults: UserDefaults = .standard) {
        self.context = container.viewContext
        self.defaults = defaults
    }

    // MARK: - 读

    func snapshot(now: Date = .now) -> Snapshot {
        let todayKey = calendar.dateKey(for: now)
        let day = fetchDay(todayKey)
        let storedStreak = defaults.integer(forKey: Key.streak)
        let lastActive = defaults.object(forKey: Key.lastActive) as? Date

        return Snapshot(streak: displayStreak(stored: storedStreak, lastActive: lastActive, now: now),
                        longestStreak: defaults.integer(forKey: Key.longest),
                        totalXp: defaults.integer(forKey: Key.totalXp),
                        earnedToday: Int(day?.qi ?? 0),
                        castsToday: Int(day?.casts ?? 0),
                        totalCasts: defaults.integer(forKey: Key.totalCasts),
                        title: Title.forStreak(displayStreak(stored: storedStreak, lastActive: lastActive, now: now)))
    }

    /// 修行录：最近的施法记录，倒序
    func recentRecords(limit: Int = 60) -> [Record] {
        let request = NSFetchRequest<CultivationSession>(entityName: "CultivationSession")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = limit
        guard let rows = try? context.fetch(request) else { return [] }
        return rows.compactMap { row in
            guard let id = row.id, let date = row.startedAt else { return nil }
            return Record(id: id,
                          date: date,
                          qi: Int(row.qi),
                          score: row.score,
                          strokes: Int(row.strokeCount),
                          shichen: Shichen(rawValue: row.shichenRaw ?? "") ?? .chang)
        }
    }

    /// 展示用连续天数：今天已来或昨天来过 → 保留；否则显示 0（但不清账，下次施法会重算）。
    private func displayStreak(stored: Int, lastActive: Date?, now: Date) -> Int {
        guard let lastActive else { return 0 }
        let today = calendar.dateKey(for: now)
        let last = calendar.dateKey(for: lastActive)
        if last == today { return stored }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        if last == calendar.dateKey(for: yesterday) { return stored }
        return 0
    }

    // MARK: - 写

    @discardableResult
    func record(qi: Int, score: Double, strokes: Int, shichen: Shichen, at date: Date = .now) -> Snapshot {
        let dayKey = calendar.dateKey(for: date)
        let existing = fetchDay(dayKey)
        let isFirstCastToday = existing == nil
        let lastActive = defaults.object(forKey: Key.lastActive) as? Date
        let previousStreak = defaults.integer(forKey: Key.streak)

        let streak: Int
        if isFirstCastToday {
            streak = calendar.nextStreak(previous: previousStreak, lastActive: lastActive, now: date)
        } else {
            streak = max(previousStreak, 1)
        }

        let day = existing ?? CultivationDay(context: context)
        if existing == nil { day.dayKey = dayKey }
        day.qi += Int64(qi)
        day.casts += 1
        day.streakAtEnd = Int16(clamping: streak)
        day.updatedAt = date

        let session = CultivationSession(context: context)
        session.id = UUID()
        session.startedAt = date
        session.qi = Int32(clamping: qi)
        session.score = score
        session.strokeCount = Int16(clamping: strokes)
        session.shichenRaw = shichen.rawValue
        session.dayKey = dayKey

        defaults.set(streak, forKey: Key.streak)
        defaults.set(max(streak, defaults.integer(forKey: Key.longest)), forKey: Key.longest)
        defaults.set(defaults.integer(forKey: Key.totalXp) + qi, forKey: Key.totalXp)
        defaults.set(defaults.integer(forKey: Key.totalCasts) + 1, forKey: Key.totalCasts)
        defaults.set(date, forKey: Key.lastActive)

        save()
        pruneIfNeeded(now: date)
        return snapshot(now: date)
    }

    func resetForDebug() {
        let entities = ["CultivationDay", "CultivationSession", "PetState"]
        for name in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            _ = try? context.execute(delete)
        }
        [Key.streak, Key.longest, Key.totalXp, Key.totalCasts, Key.lastActive]
            .forEach { defaults.removeObject(forKey: $0) }
        save()
    }

    // MARK: - 查询

    private func fetchDay(_ key: String) -> CultivationDay? {
        let request = NSFetchRequest<CultivationDay>(entityName: "CultivationDay")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "dayKey == %@", key)
        return (try? context.fetch(request))?.first
    }

    // MARK: - 维护

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            AppLog.store.error("save failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// 明细留 90 天（增长主体），按日聚合留 400 天（年度回顾够用）。
    private func pruneIfNeeded(now: Date) {
        let sessionCutoff = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        let dayCutoff = Calendar.current.date(byAdding: .day, value: -400, to: now) ?? now
        batchDelete(entity: "CultivationSession", predicate: NSPredicate(format: "startedAt < %@", sessionCutoff as NSDate))
        batchDelete(entity: "CultivationDay", predicate: NSPredicate(format: "updatedAt < %@", dayCutoff as NSDate))
    }

    private func batchDelete(entity: String, predicate: NSPredicate) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        request.predicate = predicate
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        delete.resultType = .resultTypeObjectIDs
        guard let result = try? context.execute(delete) as? NSBatchDeleteResult,
              let ids = result.result as? [NSManagedObjectID] else { return }
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                                            into: [context])
    }
}
