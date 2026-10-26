import Foundation

/// Remembers which restaurants the user has favourited, saved on the device.
@MainActor
final class FavouritesStore {

    static let shared = FavouritesStore()

    private let defaults: UserDefaults
    private let key = "favouriteRestaurantIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isFavourite(_ restaurant: Restaurant) -> Bool {
        ids.contains(restaurant.id)
    }

    /// Flips the favourite state and returns the new value.
    @discardableResult
    func toggle(_ restaurant: Restaurant) -> Bool {
        var current = ids
        let isNowFavourite = current.insert(restaurant.id).inserted
        if !isNowFavourite { current.remove(restaurant.id) }
        defaults.set(Array(current), forKey: key)
        return isNowFavourite
    }

    private var ids: Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }
}
