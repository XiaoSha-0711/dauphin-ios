import SwiftUI

struct CampusCameraView: View {
    @State private var camera: CampusCamera = .r28

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Camera", selection: $camera) {
                    ForEach(CampusCamera.allCases) { camera in Text(camera.name).tag(camera) }
                }.pickerStyle(.menu).accessibilityIdentifier("campus-camera-picker")
                CameraFeedView(camera: camera).id(camera)
                Text(
                    "Refreshes every 30 seconds while this page is open. The university controls image updates."
                ).font(.footnote).foregroundStyle(.secondary)
                Link(
                    "Source: Tamkang University Webcams",
                    destination: URL(string: "https://webcam.ipcnet.tku.edu.tw/")!
                ).font(.footnote)
            }.padding()
        }.background(Color(.systemGroupedBackground)).navigationTitle("Campus Cameras")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CameraFeedView: View {
    let camera: CampusCamera
    @Environment(\.scenePhase) private var scenePhase
    @State private var snapshot: CameraSnapshot?
    @State private var loading = false
    @State private var failed = false
    @State private var enlarged = false
    @State private var refreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(camera.name).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            if let snapshot {
                Button {
                    enlarged = true
                } label: {
                    Image(uiImage: snapshot.image).resizable().scaledToFit().clipShape(
                        RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).accessibilityLabel(Text("Enlarge image: \(camera.name)"))
                    .accessibilityIdentifier("campus-camera-image")
                CameraTimeView(snapshot: snapshot)
            } else {
                ContentUnavailableView {
                    Label {
                        if loading {
                            Text("Loading image")
                        } else {
                            Text("Image temporarily unavailable")
                        }
                    } icon: {
                        Image(systemName: loading ? "camera" : "wifi.exclamationmark")
                    }
                } description: {
                    Text("Try refreshing later or choose another camera.")
                }.frame(minHeight: 180)
            }
            if failed && snapshot != nil {
                Label(
                    "Refresh failed. Showing the previous image.",
                    systemImage: "exclamationmark.triangle"
                ).font(.footnote).foregroundStyle(.secondary)
            }
            Button {
                refreshID = UUID()
            } label: {
                HStack {
                    if loading { ProgressView() }
                    Label("Refresh Image", systemImage: "arrow.clockwise")
                }.frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(.bordered).disabled(loading).accessibilityIdentifier(
                "campus-camera-refresh")
        }.padding().background(
            Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20)
        ).task(id: "\(scenePhase)-\(refreshID)") {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await refresh()
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
            }
        }.fullScreenCover(isPresented: $enlarged) {
            if let snapshot { CameraZoomView(camera: camera, snapshot: snapshot) }
        }
    }

    @MainActor private func refresh() async {
        guard !loading, scenePhase == .active else { return }
        loading = true
        defer { loading = false }
        do {
            let next = try await CameraSnapshot.fetch(camera)
            try Task.checkCancellation()
            snapshot = next
            failed = false
        } catch {
            guard !Task.isCancelled else { return }
            failed = true
        }
    }
}

private struct CameraTimeView: View {
    let snapshot: CameraSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let date = snapshot.overlayDate {
                Text("Image updated: \(CameraTimestamp.display(date))").accessibilityIdentifier(
                    "campus-camera-time")
                Text("Recognized from the image · Taipei time")
            } else if let date = snapshot.serverDate {
                Text("Image updated: \(CameraTimestamp.display(date))").accessibilityIdentifier(
                    "campus-camera-time")
                Text(
                    "Server file timestamp · Taipei time; image timestamp could not be recognized.")
            } else {
                Text("Update time unavailable. Refer to the timestamp in the image.")
                    .accessibilityIdentifier("campus-camera-time")
            }
        }.font(.footnote).foregroundStyle(.secondary).monospacedDigit()
    }
}

private struct CameraZoomView: View {
    let camera: CampusCamera
    let snapshot: CameraSnapshot
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @GestureState private var magnification: CGFloat = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: snapshot.image).resizable().scaledToFit().frame(
                            width: geometry.size.width * scale * magnification
                        ).accessibilityLabel(camera.name)
                    }.defaultScrollAnchor(.center).gesture(
                        MagnifyGesture().updating($magnification) { value, state, _ in
                            state = value.magnification
                        }.onEnded { value in scale = min(5, max(1, scale * value.magnification)) })
                }
                CameraTimeView(snapshot: snapshot).padding(.horizontal)
                Button("Reset Zoom") { scale = 1 }.padding(.bottom)
            }.navigationTitle(camera.name).navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
