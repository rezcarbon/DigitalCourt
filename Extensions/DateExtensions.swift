import Foundation

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    func formattedString(_ style: DateFormatStyle) -> String {
        if #available(iOS 15.0, *) {
            // Use the system's built-in formatted method with appropriate style
            return self.formatted(date: .abbreviated, time: .shortened)
        } else {
            // Fallback for older iOS versions
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }
}

// Date format style for compatibility
struct DateFormatStyle {
    static func dateTime() -> DateTimeFormatStyle {
        return DateTimeFormatStyle()
    }
}

struct DateTimeFormatStyle {
    func hour() -> DateTimeFormatStyle {
        return self
    }
    
    func minute() -> DateTimeFormatStyle {
        return self
    }
    
    func second() -> DateTimeFormatStyle {
        return self
    }
}