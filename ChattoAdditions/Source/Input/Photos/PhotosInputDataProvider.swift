/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import PhotosUI

protocol PhotosInputDataProviderProtocol {
    var count: Int { get }
    func requestPreviewImageAtIndex(index: Int, targetSize: CGSize, completion: (UIImage) -> Void) -> Int32
    func requestFullImageAtIndex(index: Int, completion: (UIImage) -> Void)
    func cancelPreviewImageRequest(requestID: Int32)
}

class PhotosInputPlaceholderDataProvider: PhotosInputDataProviderProtocol {

    let numberOfPlaceholders: Int

    init(numberOfPlaceholders: Int = 5) {
        self.numberOfPlaceholders = numberOfPlaceholders
    }

    var count: Int {
        return self.numberOfPlaceholders
    }

    func requestPreviewImageAtIndex(index: Int, targetSize: CGSize, completion: (UIImage) -> Void) -> Int32 {
        return 0
    }

    func requestFullImageAtIndex(index: Int, completion: (UIImage) -> Void) {
    }

    func cancelPreviewImageRequest(requestID: Int32) {
    }
}

class PhotosInputDataProvider: PhotosInputDataProviderProtocol {
    private var imageManager = PHCachingImageManager()
    private var fetchResult: PHFetchResult!
    init() {
        let options = PHFetchOptions()
        options.sortDescriptors = [ NSSortDescriptor(key: "modificationDate", ascending: false) ]
        self.fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
    }

    var count: Int {
        return self.fetchResult.count
    }

    func requestPreviewImageAtIndex(index: Int, targetSize: CGSize, completion: (UIImage) -> Void) -> Int32 {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index] as! PHAsset
        let options = PHImageRequestOptions()
        options.deliveryMode = .HighQualityFormat
        return self.imageManager.requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFill, options: options) { (image, info) in
            if let image = image {
                completion(image)
            }
        }
    }

    func cancelPreviewImageRequest(requestID: Int32) {
        self.imageManager.cancelImageRequest(requestID)
    }

    func requestFullImageAtIndex(index: Int, completion: (UIImage) -> Void) {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index] as! PHAsset
        self.imageManager.requestImageDataForAsset(asset, options: .None) { (data, dataUTI, orientation, info) -> Void in
            if let data = data, image = UIImage(data: data) {
                completion(image)
            }
        }
    }
}

class PhotosInputWithPlaceholdersDataProvider: PhotosInputDataProviderProtocol {

    private let photosDataProvider: PhotosInputDataProviderProtocol
    private let placeholdersDataProvider: PhotosInputDataProviderProtocol

    init(photosDataProvider: PhotosInputDataProviderProtocol, placeholdersDataProvider: PhotosInputDataProviderProtocol) {
        self.photosDataProvider = photosDataProvider
        self.placeholdersDataProvider = placeholdersDataProvider
    }

    var count: Int {
        return max(self.photosDataProvider.count, self.placeholdersDataProvider.count)
    }

    func requestPreviewImageAtIndex(index: Int, targetSize: CGSize, completion: (UIImage) -> Void) -> Int32 {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        }
    }

    func requestFullImageAtIndex(index: Int, completion: (UIImage) -> Void) {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestFullImageAtIndex(index, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestFullImageAtIndex(index, completion: completion)
        }
    }

    func cancelPreviewImageRequest(requestID: Int32) {
        return self.photosDataProvider.cancelPreviewImageRequest(requestID)
    }
}
