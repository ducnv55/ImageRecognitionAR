//
//  Facebook.swift
//  Object Detector
//
//  Created by Hoang Trong Anh on 11/24/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//

import Foundation
import Unbox

struct Facebook {
    let id : String
    let name: String
    let picture: URL
}

extension Facebook: Unboxable {
    init(unboxer: Unboxer) throws {
        self.id = try unboxer.unbox(key: "id")
        self.name = try unboxer.unbox(key: "name")
        self.picture = try unboxer.unbox(keyPath: "picture.data.url")
    }
}


