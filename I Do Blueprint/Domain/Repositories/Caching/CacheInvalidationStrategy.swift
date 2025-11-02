//
//  CacheInvalidationStrategy.swift
//  I Do Blueprint
//
//  Strategy protocol for cache invalidation per domain
//

import Foundation

protocol CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async
}
