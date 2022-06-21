//
//  DeepLink+HandlingOption.swift
//  MarketKurly
//
//  Created by Minha Seong on 29/07/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension Set where Element == DeepLink.HandlingOption {
  var navigationItemTitle: String? {
    let values = compactMap { option -> String? in
      switch option {
      case .navigationItemTitle(let title):
        return title
      default:
        return nil
      }
    }

    return values.first
  }

  var isAnimated: Bool {
    let values = compactMap { option -> Bool? in
      switch option {
      case .animated(let isAnimated):
        return isAnimated
      default:
        return nil
      }
    }

    return values.first ?? false
  }
}
