# YYCache_Swift

[![CI Status](https://img.shields.io/travis/shenyutao/YYCache_Swift.svg?style=flat)](https://travis-ci.org/shenyutao/YYCache_Swift)
[![Version](https://img.shields.io/cocoapods/v/YYCache_Swift.svg?style=flat)](https://cocoapods.org/pods/YYCache_Swift)
[![License](https://img.shields.io/cocoapods/l/YYCache_Swift.svg?style=flat)](https://cocoapods.org/pods/YYCache_Swift)
[![Platform](https://img.shields.io/cocoapods/p/YYCache_Swift.svg?style=flat)](https://cocoapods.org/pods/YYCache_Swift)
## 介绍

`YYCache_Swift` 是 [YYCache](https://github.com/ibireme/YYCache) 的Swift实现版本。

 与原版 [YYCache](https://github.com/ibireme/YYCache) 相比，`YYCache_Swift` 有以下几个不同点：
 - 添加了对 `Codable` 对象的缓存能力。
 - 替换了在原 `YYCache` 仓库中被标注为废弃方法。
 - 在底层缓存结构上使用了 Swift 的 `Dictionary` ，而不是 Core Foundation 的 `CFDictionary` 。

## 系统要求

iOS 11.0+

## CocoaPods 安装
```ruby
pod 'YYCache_Swift', :git => 'https://github.com/syt2/YYCache_Swift.git'
```

## 使用
使用逻辑同 [YYCache](https://github.com/ibireme/YYCache)
基础用法如下，其他接口请自行查看代码

``` swift
import YYCache_Swift

struct MyCacheValue: Codable { ... }

// if you want to cache NSCoding object,
// make sure the object implement NSSecureCoding
// otherwise the value can't parse success from disk cache.
class MyCacheNSCodingValue: NSObject, NSSecureCoding { ... }

// get an instance of YYCacheSwift
let cache = YYCacheSwift(name: "MyCache")

// set cache synchronized
cache?.set(key: "cacheKey", value: MyCacheValue(...))

// get cache synchronized
let cachedValue = cache?.get(type: MyCacheValue.self, key: "cacheKey")

// remove cache by key synchronized
cache?.remove(key: "cacheKey")

// set cache asynchronized
cache?.set(key: "cacheKey", value: MyCacheNSCodingValue(...), completion: nil)

// get cache asynchronized
cache?.get(type: MyCacheNSCodingValue.self, key: "cacheKey") { key, value in
    // do what you want
}

// remove all caches asynchronized
cache?.removeAll { }
```

## License

YYCache_Swift is available under the MIT license. See the LICENSE file for more info.
