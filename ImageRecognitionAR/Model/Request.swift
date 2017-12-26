//
//  Request.swift
//  Object Detector
//
//  Created by Hoang Trong Anh on 12/21/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//


//  Example :
//            Api(scname: "Tam").getData { (data) in
//                print(data)
//            }

import Foundation
import Alamofire
import Unbox

class Api {
    var scname: String?
    var baseData: BaseData?
    
    init(scname: String?) {
        self.scname = scname
    }
    
    func getData(data: @escaping (BaseData) -> ()) {
        Alamofire.request("http://192.168.0.16:3000/api/scname=\(self.scname!)").responseJSON { response in
            if let res = response.response {
                if response.response?.statusCode == 200 {
                    if let _ = response.data {
                        do {
                            self.baseData = try unbox(data: response.data!)
                            data(self.baseData!)
                        } catch {
                            print(res.description)
                        }
                    }
                } else {
                    debugPrint("\(res.statusCode)")
                    debugPrint("\(res.debugDescription)")
                }
            }
        }
    }
}
