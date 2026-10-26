import UIKit

final class RestaurantCell: UITableViewCell {

    static let reuseIdentifier = "RestaurantCell"

    private let photoView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let starsStack = UIStackView()
    private let statusDot = UIView()
    private let favouriteButton = UIButton(type: .system)

    /// Called when the heart is tapped.
    var onFavouriteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        photoView.contentMode = .scaleAspectFit
        photoView.tintColor = UIColor(named: "AccentColor")
        photoView.backgroundColor = .secondarySystemBackground
        photoView.layer.cornerRadius = 12
        photoView.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .lightGray

        starsStack.axis = .horizontal
        starsStack.spacing = 2

        statusDot.layer.cornerRadius = 5

        favouriteButton.tintColor = .systemPink
        favouriteButton.addAction(UIAction { [weak self] _ in self?.onFavouriteTapped?() }, for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel, starsStack])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        [photoView, textStack, statusDot, favouriteButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoView.widthAnchor.constraint(equalToConstant: 64),
            photoView.heightAnchor.constraint(equalToConstant: 64),

            textStack.leadingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: statusDot.leadingAnchor, constant: -8),

            favouriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favouriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favouriteButton.widthAnchor.constraint(equalToConstant: 44),
            favouriteButton.heightAnchor.constraint(equalToConstant: 44),

            statusDot.trailingAnchor.constraint(equalTo: favouriteButton.leadingAnchor, constant: -4),
            statusDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    func setFavourite(_ isFavourite: Bool) {
        favouriteButton.setImage(UIImage(systemName: isFavourite ? "heart.fill" : "heart"), for: .normal)
        favouriteButton.accessibilityLabel = isFavourite ? "Remove from favourites" : "Add to favourites"
    }

    func configure(with restaurant: Restaurant, isFavourite: Bool) {
        setFavourite(isFavourite)
        photoView.image = UIImage(systemName: restaurant.imageName)
        nameLabel.text = restaurant.name
        detailLabel.text = "\(restaurant.cuisine) · \(restaurant.deliveryMinutes) min · \(PriceFormatter.string(from: restaurant.deliveryFee)) delivery"

        starsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let fullStars = Int(restaurant.rating.rounded())
        for index in 0..<5 {
            let star = UIImageView(image: UIImage(systemName: index < fullStars ? "star.fill" : "star"))
            star.tintColor = .systemOrange
            starsStack.addArrangedSubview(star)
        }

        statusDot.backgroundColor = restaurant.isOpen ? .systemGreen : .systemRed
    }
}
