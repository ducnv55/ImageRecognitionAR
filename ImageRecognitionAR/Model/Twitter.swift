//
//  Twitter.swift
//  Object Detector
//
//  Created by Hoang Trong Anh on 11/24/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//

import Foundation
import Unbox

struct Twitter {
    let id : String
    let name: String
    let screen_name: String
    let profile_image_url_https: URL
    let location: String
}

extension Twitter: Unboxable {
    init(unboxer: Unboxer) throws {
        self.id = try unboxer.unbox(key: "id_str")
        self.name = try unboxer.unbox(key: "name")
        self.screen_name = try unboxer.unbox(key: "screen_name")
        self.profile_image_url_https = try unboxer.unbox(key: "profile_image_url_https")
        self.location = try unboxer.unbox(key: "location")
    }
}

