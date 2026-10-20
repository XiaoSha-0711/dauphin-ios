import Foundation
import ImageIO
import Vision

enum CameraTimestamp {
    static func parseOverlay(_ lines: [String]) -> Date? {
        let pattern =
            #"(?<!\d)(20\d{2})[-/]\s*(\d{2})[-/]\s*(\d{2})\s+(\d{2})[\s:：.]*(\d{2})[\s:：.]*(\d{2})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        for line in lines {
            guard
                let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
            else { continue }
            let parts = (1 ... 6).compactMap { index -> Int? in
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return Int(line[range])
            }
            guard parts.count == 6 else { continue }
            let components = DateComponents(
                year: parts[0], month: parts[1], day: parts[2], hour: parts[3], minute: parts[4],
                second: parts[5])
            guard let date = calendar.date(from: components),
                calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                    == components
            else { continue }
            return date
        }
        return nil
    }

    static func parseHTTP(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.isLenient = false
        return formatter.date(from: value)
    }

    static func display(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    static func recognize(in data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil), image.width <= 4096,
            image.height <= 4096
        else { return nil }
        // Cameras put tiny timestamps at either edge; enlarge each strip on-device.
        let height = max(1, image.height / 5)
        for y in [image.height - height, 0] {
            guard
                let crop = image.cropping(
                    to: CGRect(x: 0, y: y, width: image.width, height: height)),
                let context = CGContext(
                    data: nil, width: crop.width * 4, height: crop.height * 4, bitsPerComponent: 8,
                    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { continue }
            context.interpolationQuality = .high
            context.draw(
                crop, in: CGRect(x: 0, y: 0, width: crop.width * 4, height: crop.height * 4))
            guard let enlarged = context.makeImage() else { continue }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false
            do {
                try VNImageRequestHandler(cgImage: enlarged).perform([request])
                let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                if let date = parseOverlay(lines) { return date }
            } catch { continue }
        }
        return nil
    }
}
