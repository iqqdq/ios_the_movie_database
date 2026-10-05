//
//  DateHelper.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class DateHelper {
    static let shared = DateHelper()

    private init() {}

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func year(from string: String) -> String? {
        guard let date = dateFormatter.date(from: string) else { return nil }
        return String(Calendar.current.component(.year, from: date))
    }
}
