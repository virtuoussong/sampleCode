//
//  RecommendationSectionInfo.swift
//  MarketKurly
//
//  Created by Minha Seong on 04/03/2019.
//  Copyright © 2019 TheFarmers, Inc. All rights reserved.
//

import UIKit
// Library
import SwiftyJSON

struct RecommendationSectionInfo: AmplitudeEventPropertyProtocol {
  let identifier: String?
  let group: Group
  let titleTextColor: UIColor
  let title: String
  let subtitle: String?
  let url: URL?
  let hasDivider: Bool
  let hasMinimalTopPadding: Bool

  init(identifier: String? = "") {
    if let identifier = identifier {
      self.init(JSON(parseJSON: "{\"section_id\": \"\(identifier)\"}"))
    } else {
      self.init(JSON(parseJSON: ""))
    }
  }

  init(_ json: JSON) {
    identifier = json["section_id"].string
    group = json["section_type"].stringValue.camelCased().toEnum() ?? .unknown
    titleTextColor = UIColor(hexString: json["title_text_color"].string) ?? UIColor.presetText
    title = json["title"].stringValue
    subtitle = json["subtitle"].string
    url = json["landing_url"].url
    hasDivider = json["has_divider"].boolValue
    hasMinimalTopPadding = json["short_top_padding"].boolValue
  }
}

extension RecommendationSectionInfo {
  enum Group: String {
    case unknown
    case mainBanner
    case productList
    case specialDealList
    case eventList
    case staticBanner
    case categoryList
    case recipeList
    case companyProfile
  }
}
