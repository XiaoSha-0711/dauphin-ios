import Foundation
import UIKit

enum CampusCamera: Int, CaseIterable, Identifiable {
    case r28 = 1
    case r27
    case track
    case basketball
    case elevator
    case mailroom
    case wuhugang1
    case postOffice
    case tennis
    case wuhugang2

    var id: Int { rawValue }
    var url: URL { URL(string: "https://webcam.ipcnet.tku.edu.tw/cam\(rawValue).jpg")! }
    var name: String {
        switch self {
        case .r28: String(localized: "R28 Bus Stop")
        case .r27: String(localized: "R27 Bus Stop")
        case .track: String(localized: "Track and Field Stadium")
        case .basketball: String(localized: "Basketball Court")
        case .elevator: String(localized: "Building B, 3F Elevator")
        case .mailroom: String(localized: "Mailroom")
        case .wuhugang1: String(localized: "Five-tiger Hill Court 1")
        case .postOffice: String(localized: "Post Office")
        case .tennis: String(localized: "Tennis Court")
        case .wuhugang2: String(localized: "Five-tiger Hill Court 2")
        }
    }
}

struct CameraSnapshot {
    let image: UIImage
    let overlayDate: Date?
    let serverDate: Date?

    init(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
            data.count <= 5 * 1024 * 1024, let image = UIImage(data: data)
        else { throw URLError(.cannotDecodeContentData) }
        self.image = image
        overlayDate = CameraTimestamp.recognize(in: data)
        serverDate = CameraTimestamp.parseHTTP(http.value(forHTTPHeaderField: "Last-Modified"))
    }

    static func fetch(_ camera: CampusCamera) async throws -> CameraSnapshot {
        var request = URLRequest(
            url: camera.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        let session: URLSession
        #if DEBUG && targetEnvironment(simulator)
            session =
                ProcessInfo.processInfo.arguments.contains("-campus-camera-test")
                ? CampusCameraFixture.session : .shared
        #else
            session = .shared
        #endif
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        return try CameraSnapshot(data: data, response: response)
    }
}
