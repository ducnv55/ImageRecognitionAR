//
//  Instagram.swift
//  Object Detector
//
//  Created by Hoang Trong Anh on 12/21/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//

import Foundation
import Unbox

struct Instagram {
    let id : Int
    let username: String
    let profile_picture: URL
    let full_name: String
    let medias_count: Int
    let follows_count: Int
    let followed_by_count: Int
}

extension Instagram: Unboxable {
    init(unboxer: Unboxer) throws {
        self.id = try unboxer.unbox(keyPath: "user.id")
        self.username = try unboxer.unbox(keyPath: "user.username")
        self.profile_picture = try unboxer.unbox(keyPath: "user.profile_pic_url_hd")
        self.full_name = try unboxer.unbox(keyPath: "user.full_name")
        self.medias_count = try unboxer.unbox(keyPath: "user.media.count")
        self.follows_count = try unboxer.unbox(keyPath: "user.follows.count")
        self.followed_by_count = try unboxer.unbox(keyPath: "user.followed_by.count")
    }
}
