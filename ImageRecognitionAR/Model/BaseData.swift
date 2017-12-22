//
//  Data.swift
//  Object Detector
//
//  Created by Hoang Trong Anh on 12/21/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//

import Foundation
import Unbox

struct BaseData {
    let twitter : Twitter
    let facebook: Facebook
    let instagram: Instagram
}

extension BaseData: Unboxable {
    init(unboxer: Unboxer) throws {
        self.twitter = try unboxer.unbox(key: "twitter")
        self.facebook = try unboxer.unbox(key: "facebook")
        self.instagram = try unboxer.unbox(key: "instagram")
    }
}

