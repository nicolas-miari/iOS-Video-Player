//
//  VideoSlider.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/24.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit

/**
 Using custom subclass in order to override the thickness of the **track**.
 */
class VideoSlider: UISlider {

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var customBounds = super.trackRect(forBounds: bounds)
        customBounds.size.height = 5
        return customBounds
    }
}
