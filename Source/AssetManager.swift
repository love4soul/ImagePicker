import Foundation
import UIKit
import Photos
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}
open class AssetManager {

  open static func getImage(_ name: String) -> UIImage {
    let traitCollection = UITraitCollection(displayScale: 3)
    var bundle = Bundle(for: AssetManager.self)

    if let resource = bundle.resourcePath, let resourceBundle = Bundle(path: resource + "/ImagePicker.bundle") {
      bundle = resourceBundle
    }

    return UIImage(named: name, in: bundle, compatibleWith: traitCollection) ?? UIImage()
  }

  open static func fetch(_ completion: @escaping (_ assets: [PHAsset]) -> Void) {
    let fetchOptions = PHFetchOptions()
    let authorizationStatus = PHPhotoLibrary.authorizationStatus()
    var photoFetchResult: PHFetchResult<PHAsset>?
    var videoFetchResult: PHFetchResult<PHAsset>?

    guard authorizationStatus == .authorized else { return }

    if photoFetchResult == nil {
      photoFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }

    if videoFetchResult == nil {
      videoFetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
    }

    var assets = [PHAsset]()

    if Configuration.mediaTypes.contains(.image) && photoFetchResult?.count > 0 {
      photoFetchResult?.enumerateObjects({ object, _, _ in
        assets.insert(object, at: 0)
      })
    }

    if Configuration.mediaTypes.contains(.video) && videoFetchResult?.count > 0 {
      videoFetchResult?.enumerateObjects({ object, _, _ in
        assets.insert(object, at: 0)
      })
    }

    DispatchQueue.main.async(execute: {
      completion(assets)
    })
  }

  open static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), completion: @escaping (_ image: UIImage?) -> Void) {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat

    imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
      if let info = info, info["PHImageFileUTIKey"] == nil {
        DispatchQueue.main.async(execute: {
          completion(image)
        })
      }
    }
  }

  open static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280)) -> [UIImage] {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true

    var images = [UIImage]()
    for asset in assets {
      imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
        if let image = image {
          images.append(image)
        }
      }
    }
    return images
  }

  open static func resolveVideoAssets(_ assets: [PHAsset], completion: @escaping (([AVAsset]) -> Void)) -> Void {
    let imageManager = PHImageManager.default()
    var videos = [AVAsset]()
    let videoAssets = assets.filter { $0.mediaType == .video }
    let options = PHVideoRequestOptions()
    options.deliveryMode = .mediumQualityFormat
    videoAssets.forEach { asset in
      imageManager.requestAVAsset(forVideo: asset, options: options, resultHandler: { (avAsset, _, _) in
        if let avAsset = avAsset {
          videos.append(avAsset)
          if videos.count == videoAssets.count {
            completion(videos)
          }
        }
      })
    }
  }
}
