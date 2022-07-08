//
//  UIImageView+Extension.swift
//  OpenMarket
//
//  Created by lily on 2022/01/19.
//

import UIKit

extension UIImageView {
    
    func setImage(with url: URL, invalidImage: UIImage) -> Cancellable? {
        let cacheKey = url.absoluteString as NSString
        
        if let cachedImage = ImageCacheManager.shared.object(forKey: cacheKey) {
            self.image = cachedImage
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let _ = error {
                DispatchQueue.main.async {
                    self?.image = invalidImage
                }
                return
            } else {
                DispatchQueue.main.async {
                    guard let imageData = data,
                          let image = UIImage(data: imageData) else { return }
                    self?.image = image
                    ImageCacheManager.shared.setObject(image, forKey: cacheKey)
                }
            }
        }
        task.resume()
        return task
    }
}
