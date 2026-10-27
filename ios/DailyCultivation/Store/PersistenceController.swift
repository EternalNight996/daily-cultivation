import CoreData

/// 持久化容器。SQLite 放 Application Support，随 iCloud 整机备份（隐私政策里写明"开发者不访问"）。
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DailyCultivation",
                                          managedObjectModel: CultivationModel.make())

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                self?.loadError = error
                AppLog.store.error("store load failed: \(String(describing: error), privacy: .public)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
