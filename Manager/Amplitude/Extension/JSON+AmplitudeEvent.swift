//
//  JSON+AmplitudeEvent.swift
//  MarketKurly
//
//  Created by Minha Seong on 08/11/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import SwiftyJSON

extension JSON {
  subscript(_ propertyKey: AmplitudeEvent.Property.Key) -> JSON {
    return self[propertyKey.rawValue]
  }
}
