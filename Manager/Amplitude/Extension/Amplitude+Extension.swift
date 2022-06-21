//
//  Amplitude+Extension.swift
//  MarketKurly
//
//  Created by Minha Seong on 19/09/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import Amplitude

extension Amplitude {
  var propertyList: Any? {
    guard let propertyListPath = propertyListPath, let data = try? Data(contentsOf: URL(fileURLWithPath: propertyListPath)) else {
      return nil
    }
    guard let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else {
      return nil
    }

    return propertyList
  }
}
