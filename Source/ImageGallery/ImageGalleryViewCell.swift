import UIKit

class ImageGalleryViewCell: UICollectionViewCell {

  lazy var imageView = UIImageView()
  lazy var selectedImageView = UIImageView()
  lazy var durationLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .white
    label.textAlignment = .right
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    for view in [imageView, selectedImageView] {
      view.contentMode = .scaleAspectFill
      view.translatesAutoresizingMaskIntoConstraints = false
      view.clipsToBounds = true
      contentView.addSubview(view)
    }

    contentView.addSubview(durationLabel)
    durationLabel.frame = CGRect(x: 0, y: frame.height-20, width: frame.width-5, height: 20)

    isAccessibilityElement = true
    accessibilityLabel = "Photo"

    setupConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  func configureCell(_ image: UIImage, duration: TimeInterval? = nil) {
    imageView.image = image

    if let duration = duration, duration > 0 {
      durationLabel.isHidden = false
      durationLabel.text = duration.formattedDuration()
      accessibilityLabel = "Video"
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    durationLabel.text = nil
    durationLabel.isHidden = true
    accessibilityLabel = "Photo"
  }
}

extension TimeInterval {
  func formattedDuration() -> String {
    let interval = Int(self)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
