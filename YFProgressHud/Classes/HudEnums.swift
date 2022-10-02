//
//  HudEnums.swift
//  YFProgressHud
//
//  Created by sky on 2022/10/2.
//

import Foundation

public enum YFProgressHudMode {
    case indeterminate
    case determinate
    case determinateHorizontalBar
    case annularDeterminate
    case customView
    case text
}

public enum YFProgressHudAnimation {
    case fade
    case zoom
    case zoomOut
    case zoomIn
}

public enum YFProgressHudBackgroundStyle {
    case solidColor
    case blur
}
