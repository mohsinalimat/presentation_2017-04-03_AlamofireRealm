//
//  DateTransform_Custom.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import ObjectMapper

public extension DateTransform {
    
    public static var custom: DateFormatterTransform {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return DateFormatterTransform(dateFormatter: formatter)
    }
}
