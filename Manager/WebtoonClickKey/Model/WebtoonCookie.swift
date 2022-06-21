//
//  WebtoonCookie.swift
//  MarketKurly
//
//  Created by MK-Mac-210 on 2022/05/25.
//  Copyright © 2022 com.kurly. All rights reserved.
//

import Foundation

struct WebtoonClickKey: Encodable {
  let clickKey: String
  let createdTime: Date
  var isValid: Bool {
    if let timeDifference = Calendar.current.dateComponents(
      [.hour],
      from: self.createdTime,
      to: Date()
    ).hour,
      timeDifference < 24 {
      return true
    }
    return false
  }

  init(key: String) {
    self.clickKey = key
    self.createdTime = Date()
  }

  enum CodingKeys: String, CodingKey {
    case clickKey = "click_key"
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.clickKey, forKey: .clickKey)
  }
}

struct WebtoonClickKeyResponse: Decodable {
  let success: Bool?
  let message: String?
  let data: AdisonData?

  struct AdisonData: Decodable {
    let adisonResponse: String?
  }
}
