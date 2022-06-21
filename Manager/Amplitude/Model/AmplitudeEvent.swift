//
//  AmplitudeEvent.swift
//  MarketKurly
//
//  Created by Minha Seong on 10/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

typealias AmplitudeEventProperties = [AmplitudeEvent.Property.Key: Any?]

class AmplitudeEvent: Reflectable {
  private(set) var properties: [String: Any?]?
  private(set) var predefinedName: AmplitudeEvent.Name?
  private(set) var name: String? {
    didSet {
      predefinedName = name?.toEnum()
    }
  }

  init?(name: String?) {
    let isTrackingAvailable = AmplitudeManager.shared.isTrackingAvailable
    guard let unwrappedName = name, isTrackingAvailable else {
      DLog.warning("isTrackingAvailable: \(isTrackingAvailable), name: \(String(describing: name))")

      return nil
    }

    // https://stackoverflow.com/a/29501998
    ({ self.name = unwrappedName })()
  }
}

// MARK: - Lifecycle

// MARK: - Public

extension AmplitudeEvent {
  static func name(_ name: AmplitudeEvent.Name?) -> AmplitudeEvent? {
    guard let name = name else {
      return nil
    }
    return AmplitudeEvent(name: name.rawValue)
  }

  @discardableResult
  func properties(_ eventProperties: AmplitudeEventProperties?) -> AmplitudeEvent {
    let eventProperties = eventProperties?.reduce(into: [String: Any?]()) { result, property in
      result[property.key.rawValue] = property.value
    }

    return properties(eventProperties)
  }

  @discardableResult
  func properties(_ eventProperties: [String: Any?]?) -> AmplitudeEvent {
    var temporaryEventProperties = properties ?? [:]
    if let eventProperties = eventProperties {
      temporaryEventProperties.merge(eventProperties) { $1 ?? $0 }
    }

    if !temporaryEventProperties.isEmpty {
      properties = temporaryEventProperties
    }

    return self
  }

  func removeProperties(forKeys keys: AmplitudeEvent.Property.Key...) {
    keys.forEach {
      properties?.removeValue(forKey: $0.rawValue)
    }
  }

  func send() {
    AmplitudeManager.shared.sendEvent(self)
  }
}

// MARK: - Private

// MARK: - Action

// MARK: - Override

// MARK: - Notification
