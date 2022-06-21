//
//  Dictionary+AmplitudeEvent.swift
//  MarketKurly
//
//  Created by Minha Seong on 23/10/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit

extension Dictionary {
  subscript(_ propertyKey: AmplitudeEvent.Property.Key) -> Any? {
    return self[propertyKey.rawValue as! Key]
  }
}
