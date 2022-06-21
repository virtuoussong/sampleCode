//  
//  AmplitudeEventType.swift
//  MarketKurly
//  
//  Created by Taejun Kim on 2021/11/22.
//  Copyright © 2021 TheFarmers, Inc. All rights reserved.
//  

import Foundation

protocol AmplitudeEventType {
  var eventName: String { get }
  var eventProperties: AmplitudeEventProperties { get }
}

extension AmplitudeEventType {
  func send() {
    AmplitudeEvent(name: self.eventName)?
      .properties(self.eventProperties)
      .send()
  }
}
