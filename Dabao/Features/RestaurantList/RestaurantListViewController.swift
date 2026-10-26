import UIKit

/// The first screen: a list of restaurants.
///
/// This screen uses plain MVC. The view controller fetches the data, holds it,
/// and configures the table view. Compare it with the Menu module, which uses VIPER.
final class RestaurantListViewController: UIViewController {

    private let service: RestaurantServicing
    private let favourites: FavouritesStore

    private nonisolated enum Section: Hashable, Sendable { case main }

    private lazy var dataSource = makeDataSource()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let searchController = UISearchController(searchResultsController: nil)
    private var allRestaurants: [Restaurant] = []
    private var showOpenOnly = false
    private var showFavouritesOnly = false
    private var sortOption: SortOption = .none

    private enum SortOption: String, CaseIterable {
        case none = "Default"
        case rating = "Rating"
        case deliveryTime = "Delivery time"
    }

    init(service: RestaurantServicing = RestaurantService(),
         favourites: FavouritesStore = .shared) {
        self.service = service
        self.favourites = favourites
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dabao"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        setUpSearch()
        updateFilterMenu()
        setUpTableView()
        setUpSpinner()
        loadRestaurants()
    }

    private func setUpSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search name or cuisine"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func updateFilterMenu() {
        let openNow = UIAction(title: "Open now",
                               state: showOpenOnly ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.showOpenOnly.toggle()
            self.updateFilterMenu()
            self.applyFilter()
        }
        let favouritesOnly = UIAction(title: "Favourites only",
                                      image: UIImage(systemName: "heart"),
                                      state: showFavouritesOnly ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.showFavouritesOnly.toggle()
            self.updateFilterMenu()
            self.applyFilter()
        }
        let sortActions = SortOption.allCases.map { option in
            UIAction(title: option.rawValue,
                     state: sortOption == option ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.sortOption = option
                self.updateFilterMenu()
                self.applyFilter()
            }
        }
        let sortMenu = UIMenu(title: "Sort by", options: .displayInline, children: sortActions)
        let isActive = showOpenOnly || showFavouritesOnly || sortOption != .none
        let icon = isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: icon),
                                                            menu: UIMenu(children: [openNow, favouritesOnly, sortMenu]))
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(RestaurantCell.self, forCellReuseIdentifier: RestaurantCell.reuseIdentifier)
        tableView.rowHeight = 88
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadRestaurants() {
        spinner.startAnimating()
        service.fetchRestaurants { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()
            switch result {
            case .success(let restaurants):
                self.allRestaurants = restaurants
                self.applyFilter()
            case .failure:
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(title: "Couldn't load restaurants",
                                      message: "Please try again later.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RestaurantListViewController {

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Restaurant> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, restaurant in
            let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantCell.reuseIdentifier,
                                                     for: indexPath) as! RestaurantCell
            cell.configure(with: restaurant, isFavourite: self?.favourites.isFavourite(restaurant) ?? false)
            cell.onFavouriteTapped = { [weak self, weak cell] in
                guard let self else { return }
                let isFavourite = self.favourites.toggle(restaurant)
                cell?.setFavourite(isFavourite)
                if self.showFavouritesOnly { self.applyFilter() }
            }
            return cell
        }
    }

    private func applySnapshot(_ restaurants: [Restaurant], animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Restaurant>()
        snapshot.appendSections([.main])
        snapshot.appendItems(restaurants)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

extension RestaurantListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }

    private func applyFilter() {
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespaces)
        var result = allRestaurants
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query) || $0.cuisine.localizedCaseInsensitiveContains(query)
            }
        }
        if showFavouritesOnly {
            result = result.filter(favourites.isFavourite)
        }
        if showOpenOnly {
            result = result.filter(\.isOpen)
        }
        switch sortOption {
        case .none: break
        case .rating: result.sort { $0.rating > $1.rating }
        case .deliveryTime: result.sort { $0.deliveryMinutes < $1.deliveryMinutes }
        }
        applySnapshot(result)
    }
}

extension RestaurantListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let restaurant = dataSource.itemIdentifier(for: indexPath) else { return }

        // The Menu screen is a VIPER module. We ask its router to build it for us.
        let menu = MenuRouter.createModule(restaurant: restaurant, cart: CartStore.shared)
        navigationController?.pushViewController(menu, animated: true)
    }
}
