//
//  AMPTrackingOptions+Extension.swift
//  MarketKurly
//
//  Created by Minha Seong on 19/09/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import Amplitude

extension AMPTrackingOptions {
  /// https://help.amplitude.com/hc/en-us/articles/115002278527#disable-automatic-tracking-of-user-properties
  static var defaultOptions: AMPTrackingOptions {
    let options = AMPTrackingOptions()
    options.disableDMA()?.disableIPAddress()?.disableLatLng()

    return options
  }
}
