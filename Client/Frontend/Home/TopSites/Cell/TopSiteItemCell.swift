// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import UIKit

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: BlurrableCollectionViewCell, ReusableCell {

    // MARK: - Variables

    private var homeTopSite: TopSite?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    struct UX {
        static let borderColor = UIColor(white: 0, alpha: 0.1)
        static let borderWidth: CGFloat = 0.5
        static let cellCornerRadius: CGFloat = 8
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 36, height: 36)
        static let iconCornerRadius: CGFloat = 4
        static let imageBackgroundSize = CGSize(width: 60, height: 60)
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize: CGSize = CGSize(width: 12, height: 12)
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 2
        static let topSpace: CGFloat = 8
        static let textSafeSpace: CGFloat = 8
        static let bottomSpace: CGFloat = 8
        static let imageBottomSpace: CGFloat = 3
        static let titleFontSize: CGFloat = 12
        static let sponsorFontSize: CGFloat = 11
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = UX.cellCornerRadius
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    // Holds the title and the pin image of the top site
    private lazy var titlePinWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    // Holds the titlePinWrapper and the Sponsored text for a sponsored tile
    private lazy var descriptionWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    private lazy var pinViewHolder: UIView = .build { view in
        view.isHidden = true
    }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.pinSmall)
        imageView.isHidden = true
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                        size: UX.titleFontSize)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + UX.shadowRadius
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
    }

    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption2,
                                                                            size: UX.sponsorFontSize)
        sponsoredLabel.adjustsFontForContentSizeCategory = true
        sponsoredLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + TopSiteItemCell.UX.shadowRadius
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = UX.cellCornerRadius
        selectedOverlay.backgroundColor = UX.overlayColor
    }

    override var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            selectedOverlay.isHidden = !isHighlighted
        }
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell

        setupLayout()
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged,
                                                          .WallpaperDidChange])
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        titleLabel.text = nil
        sponsoredLabel.text = nil
        pinViewHolder.isHidden = true
        pinImageView.isHidden = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedOverlay.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.cellCornerRadius).cgPath
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSite, position: Int) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel

        imageView.setFaviconOrDefaultIcon(forSite: topSite.site) {}

        configurePinnedSite(topSite)
        configureSponsoredSite(topSite)

        applyTheme()
        adjustLayout()
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        rootContainer.backgroundColor = .clear

        titlePinWrapper.addArrangedSubview(pinViewHolder)
        titlePinWrapper.addArrangedSubview(titleLabel)
        pinViewHolder.addSubview(pinImageView)

        descriptionWrapper.addArrangedSubview(titlePinWrapper)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)
        rootContainer.addSubview(descriptionWrapper)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                           constant: UX.topSpace),
            imageView.centerXAnchor.constraint(equalTo: rootContainer.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: UX.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.iconSize.height),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: descriptionWrapper.topAnchor,
                                              constant: -UX.imageBottomSpace),

            descriptionWrapper.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                        constant: UX.textSafeSpace),
            descriptionWrapper.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                         constant: -UX.textSafeSpace),
            descriptionWrapper.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                       constant: -UX.bottomSpace),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),

            pinViewHolder.bottomAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor,
                                                  constant: UX.pinAlignmentSpacing),
            pinViewHolder.leadingAnchor.constraint(equalTo: pinImageView.leadingAnchor),
            pinViewHolder.trailingAnchor.constraint(equalTo: pinImageView.trailingAnchor,
                                                    constant: UX.titleOffset),
            pinViewHolder.topAnchor.constraint(equalTo: pinImageView.topAnchor),

            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
        ])
    }

    private func configurePinnedSite(_ topSite: TopSite) {
        guard topSite.isPinned else { return }

        pinViewHolder.isHidden = false
        pinImageView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSite) {
        guard topSite.isSponsoredTile else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }

    private func adjustLayout() {
        // If blur is disabled set background color
        if shouldApplyWallpaperBlur {
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = UIColor.theme.homePanel.topSitesContainerView
            setupShadow()
        }
    }

    private func setupShadow() {
        rootContainer.layer.cornerRadius = UX.cellCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.cellCornerRadius).cgPath
        rootContainer.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        rootContainer.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        rootContainer.layer.shadowOffset = CGSize(width: 0, height: UX.shadowOffset)
        rootContainer.layer.shadowRadius = UX.shadowRadius
    }
}

// MARK: NotificationThemeable
extension TopSiteItemCell: NotificationThemeable {
    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        titleLabel.textColor = UIColor.theme.homePanel.topSiteDomain
        sponsoredLabel.textColor = UIColor.theme.homePanel.sponsored

        adjustLayout()
    }
}

// MARK: - Notifiable
extension TopSiteItemCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged,
                    .WallpaperDidChange:
                self?.applyTheme()
            default: break
            }
        }
    }
}
