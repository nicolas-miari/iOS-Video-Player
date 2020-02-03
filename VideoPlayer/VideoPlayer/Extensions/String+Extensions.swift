//
//  String+Extensions.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/24.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

extension String {

    /**
     Initializes a string in the time format "mm:ss" or "HH:mm:ss" given a total number fo seconds and
     a flag.
     */
    init(seconds: Int, showHours: Bool = false) {

        let h = seconds / 3600
        let m = (seconds - (3600*h))/60
        let s = seconds - (3600*h) - (m*60)

        if showHours {
            // Video lasts one hour or more: Display hours
            self.init(format: "%02d:%02d:%02d", h, m, s)
        } else {
            // Video lasts less than one hour: display only minutes and seconds
            self.init(format: "%02d:%02d", m, s)
        }
    }
}
