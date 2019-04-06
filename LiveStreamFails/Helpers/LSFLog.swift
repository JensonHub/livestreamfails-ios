//
//  LSFLog.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-03-28.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import Foundation

func println(_ object: Any) {
    #if DEBUG
    Swift.print("APPPRINT: \(object)")
    #endif
}

