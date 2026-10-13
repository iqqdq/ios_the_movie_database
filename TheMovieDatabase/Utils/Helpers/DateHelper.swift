//
//  DateHelper.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

extension String {
    var year: String? {
        Self.dateFormatter.date(from: self).map {
            String(Calendar.current.component(.year, from: $0))
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
