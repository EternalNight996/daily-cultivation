import CoreData

/// V1 的模型用代码定义而不是 .xcdatamodeld：
/// - 纯文本、可 review、Windows 上也能改
/// - 只有 3 个实体，用不到模型编辑器的可视化
/// 一旦实体膨胀或需要多版本迁移，再换成 .xcdatamodeld（届时也更容易写 mapping model）。
@objc(CultivationDay)
final class CultivationDay: NSManagedObject {
    @NSManaged var dayKey: String
    @NSManaged var qi: Int64
    @NSManaged var casts: Int32
    @NSManaged var streakAtEnd: Int16
    @NSManaged var updatedAt: Date
}

@objc(CultivationSession)
final class CultivationSession: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startedAt: Date
    @NSManaged var qi: Int32
    @NSManaged var score: Double
    @NSManaged var strokeCount: Int16
    @NSManaged var shichenRaw: String
    @NSManaged var dayKey: String
}

@objc(PetState)
final class PetState: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var xp: Int64
    @NSManaged var lastResonanceAt: Date?
}

enum CultivationModel {
    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            entity(name: "CultivationDay", className: CultivationDay.self, attributes: [
                ("dayKey", .stringAttributeType, false),
                ("qi", .integer64AttributeType, false),
                ("casts", .integer32AttributeType, false),
                ("streakAtEnd", .integer16AttributeType, false),
                ("updatedAt", .dateAttributeType, false)
            ], unique: ["dayKey"]),
            entity(name: "CultivationSession", className: CultivationSession.self, attributes: [
                ("id", .UUIDAttributeType, false),
                ("startedAt", .dateAttributeType, false),
                ("qi", .integer32AttributeType, false),
                ("score", .doubleAttributeType, false),
                ("strokeCount", .integer16AttributeType, false),
                ("shichenRaw", .stringAttributeType, false),
                ("dayKey", .stringAttributeType, false)
            ]),
            entity(name: "PetState", className: PetState.self, attributes: [
                ("id", .stringAttributeType, false),
                ("xp", .integer64AttributeType, false),
                ("lastResonanceAt", .dateAttributeType, true)
            ])
        ]
        return model
    }

    private static func entity(name: String, className: AnyClass,
                               attributes: [(String, NSAttributeType, Bool)],
                               unique: [String] = []) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(className)
        entity.properties = attributes.map { name, type, optional in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }
        if !unique.isEmpty {
            entity.uniquenessConstraints = [unique as [Any]]
        }
        return entity
    }
}
