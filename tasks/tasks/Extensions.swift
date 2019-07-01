//
//  Extensions.swift
//  tasks
//
//  Created by Mason Macias on 7/1/19.
//  Copyright © 2019 Mason Macias. All rights reserved.
//

import Foundation

enum DateFormat {
    case dateShortTimeShort
    case dateFullTimeFull
}

extension DateFormat: RawRepresentable {
    typealias RawValue = (date: DateFormatter.Style, time: DateFormatter.Style)
    
    init?(rawValue: RawValue) {
        switch rawValue {
        case (.short, .short):
            self = .dateShortTimeShort
        default:
            return nil
        }
    }
    
    var rawValue: (date: DateFormatter.Style, time: DateFormatter.Style) {
        switch self {
        case .dateShortTimeShort:
            return (.short, .short)
        case .dateFullTimeFull:
            return (.full, .full)
        }
    }
}

extension Date {
    func string(_ dateFormat: DateFormat) -> String {
        return DateFormatter.localizedString(from: self, dateStyle: dateFormat.rawValue.date, timeStyle: dateFormat.rawValue.time)
    }
}


extension String {
    func date(_ dateFormat: DateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateFormat.rawValue.date
        dateFormatter.timeStyle = dateFormat.rawValue.time
        return dateFormatter.date(from: self)
    }
}
