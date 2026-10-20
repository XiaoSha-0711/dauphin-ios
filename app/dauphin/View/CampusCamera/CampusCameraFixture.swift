#if DEBUG && targetEnvironment(simulator)
    import UIKit

    final class CampusCameraFixture: URLProtocol, @unchecked Sendable {
        static let session: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [CampusCameraFixture.self]
            return URLSession(configuration: config)
        }()
        private static let counter = Counter()

        override class func canInit(with request: URLRequest) -> Bool {
            request.url?.host == "webcam.ipcnet.tku.edu.tw"
        }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func stopLoading() {}
        override func startLoading() {
            let arguments = ProcessInfo.processInfo.arguments
            let failed =
                Self.counter.next() > 1 && arguments.contains("-campus-camera-refresh-failure-test")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: failed ? 503 : 200, httpVersion: nil,
                headerFields: [
                    "Content-Type": "image/jpeg", "Last-Modified": "Sat, 17 Oct 2026 13:29:21 GMT",
                ])!
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(
                size: CGSize(width: 426, height: 240), format: format
            ).image { context in
                UIColor.darkGray.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 426, height: 240))
                UIColor.gray.setFill()
                context.fill(CGRect(x: 0, y: 80, width: 426, height: 120))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.white,
                ]
                ("TKU · Camera " + (request.url?.lastPathComponent ?? "")).draw(
                    at: CGPoint(x: 12, y: 12), withAttributes: attributes)
                if !arguments.contains("-campus-camera-server-time-test") {
                    "2026-10-17 21:29:00".draw(
                        at: CGPoint(x: 120, y: 220), withAttributes: attributes)
                }
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: image.jpegData(compressionQuality: 0.9)!)
            client?.urlProtocolDidFinishLoading(self)
        }

        private final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            private var count = 0
            func next() -> Int {
                lock.lock()
                defer { lock.unlock() }
                count += 1
                return count
            }
        }
    }
#endif
