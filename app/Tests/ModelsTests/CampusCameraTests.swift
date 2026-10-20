import Foundation
import Testing
import UIKit

@testable import dauphin

@Suite("Campus camera timestamps") struct CampusCameraTests {
    @Test func overlayTimeUsesTaipeiInsteadOfDeviceTimeZone() {
        let date = CameraTimestamp.parseOverlay(["06A128 公車站 2026-10-17 21:29:00"])
        #expect(date == ISO8601DateFormatter().date(from: "2026-10-17T13:29:00Z"))
        #expect(CameraTimestamp.parseOverlay(["2026/10/17 21:29:00"]) == date)
        #expect(CameraTimestamp.parseOverlay(["2026-10-17 21 2900"]) == date)
        #expect(CameraTimestamp.display(date!) == "2026-10-17 21:29:00")
    }

    @Test func invalidOrMissingOverlayDoesNotInventATime() {
        for text in ["", "R28公車", "2026-02-30 10:20:30", "2026-10-17 25:00:00"] {
            #expect(CameraTimestamp.parseOverlay([text]) == nil)
        }
    }

    @Test func httpTimeIsASeparateFallback() {
        #expect(
            CameraTimestamp.parseHTTP("Sat, 17 Oct 2026 13:29:21 GMT")
                == ISO8601DateFormatter().date(from: "2026-10-17T13:29:21Z"))
        #expect(CameraTimestamp.parseHTTP(nil) == nil)
        #expect(CameraTimestamp.parseHTTP("invalid") == nil)
    }

    @Test func cameraURLsStayOnTheOfficialHTTPSHost() {
        #expect(CampusCamera.allCases.count == 10)
        for camera in CampusCamera.allCases {
            #expect(camera.url.scheme == "https")
            #expect(camera.url.host == "webcam.ipcnet.tku.edu.tw")
            #expect(camera.url.path == "/cam\(camera.rawValue).jpg")
        }
    }

    @MainActor @Test func invalidHTTPAndNonImageDataAreRejected() {
        let response = HTTPURLResponse(
            url: CampusCamera.r28.url, statusCode: 503, httpVersion: nil, headerFields: nil)!
        #expect(throws: Error.self) { try CameraSnapshot(data: Data(), response: response) }
        let ok = HTTPURLResponse(
            url: CampusCamera.r28.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        #expect(throws: Error.self) {
            try CameraSnapshot(data: Data("<html>offline</html>".utf8), response: ok)
        }
    }

    @MainActor @Test func missingTimestampRemainsUnknownForAValidImage() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let data = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 60), format: format)
            .image { context in
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 100, height: 60))
            }.jpegData(compressionQuality: 0.8)!
        let response = HTTPURLResponse(
            url: CampusCamera.r28.url, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "image/jpeg"])!
        let snapshot = try CameraSnapshot(data: data, response: response)
        #expect(snapshot.image.size.width == 100)
        #expect(snapshot.overlayDate == nil)
        #expect(snapshot.serverDate == nil)
    }

    @MainActor @Test(arguments: [6, 220]) func recognizesTimeAtEitherImageEdge(y: Int) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let data = UIGraphicsImageRenderer(size: CGSize(width: 426, height: 240), format: format)
            .image { context in
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 426, height: 240))
                "2026-10-17 21:29:00".draw(
                    at: CGPoint(x: 100, y: y),
                    withAttributes: [
                        .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular),
                        .foregroundColor: UIColor.white,
                    ])
            }.jpegData(compressionQuality: 0.9)!
        #expect(
            CameraTimestamp.recognize(in: data)
                == ISO8601DateFormatter().date(from: "2026-10-17T13:29:00Z"))
    }
}
