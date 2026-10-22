import SwiftUI
import HomeKit
import os

extension HMAccessory {
    /// Erstes Kamera-Profil (Kameras und Video-Türklingeln). `nil` = keine Kamera.
    var cameraProfile: HMCameraProfile? {
        cameraProfiles?.first
    }
}

/// Steuert Snapshot und Live-Stream EINER Kamera. Jede View bekommt ihren
/// eigenen Controller, damit Vorschau-Kachel und Vollbild sich nicht
/// gegenseitig den Stream wegnehmen.
@MainActor
@Observable
final class CameraController {
    enum StreamState: Equatable {
        case idle, starting, streaming, failed(String)
    }

    /// Was `HMCameraView` gerade zeigen soll: Live-Stream oder letzter Snapshot.
    private(set) var source: HMCameraSource?
    private(set) var streamState: StreamState = .idle
    private(set) var snapshotDate: Date?

    private let profile: HMCameraProfile
    private let proxy = CameraDelegateProxy()
    private let log = Logger(subsystem: "de.marcel.homedash", category: "Camera")

    init(profile: HMCameraProfile) {
        self.profile = profile
        proxy.owner = self
        profile.streamControl?.delegate = proxy
        profile.snapshotControl?.delegate = proxy
        // Sofort den letzten bekannten Snapshot zeigen – kein schwarzes Bild.
        if let snapshot = profile.snapshotControl?.mostRecentSnapshot {
            source = snapshot
            snapshotDate = snapshot.captureDate
        }
    }

    var hasStream: Bool { profile.streamControl != nil }

    func takeSnapshot() {
        // Delegate zurückholen, falls das Vollbild ihn zwischenzeitlich hatte.
        profile.snapshotControl?.delegate = proxy
        profile.snapshotControl?.takeSnapshot()
    }

    func startStream() {
        guard let control = profile.streamControl else {
            streamState = .failed(NSLocalizedString("camera.error.noStream", comment: ""))
            return
        }
        // Delegates erneut setzen: ein anderer Controller derselben Kamera
        // kann sie inzwischen übernommen haben.
        control.delegate = proxy
        profile.snapshotControl?.delegate = proxy
        streamState = .starting
        control.startStream()
    }

    func stopStream() {
        profile.streamControl?.stopStream()
        streamState = .idle
        if let snapshot = profile.snapshotControl?.mostRecentSnapshot {
            source = snapshot
        }
    }

    // MARK: - Delegate-Eingang
    fileprivate func streamDidStart() {
        guard let stream = profile.streamControl?.cameraStream else { return }
        source = stream
        streamState = .streaming
    }

    fileprivate func streamDidStop(error: Error?) {
        if let error {
            log.error("Stream: \(error.localizedDescription, privacy: .private)")
            streamState = .failed(error.friendlyHomeKitDescription)
        } else if streamState != .idle {
            streamState = .idle
        }
    }

    fileprivate func snapshotDidUpdate(error: Error?) {
        if let error {
            log.error("Snapshot: \(error.localizedDescription, privacy: .private)")
            return
        }
        // Während des Live-Streams nicht auf ein Standbild zurückspringen.
        guard streamState != .streaming,
              let snapshot = profile.snapshotControl?.mostRecentSnapshot else { return }
        source = snapshot
        snapshotDate = snapshot.captureDate
    }
}

private final class CameraDelegateProxy: NSObject, HMCameraStreamControlDelegate, HMCameraSnapshotControlDelegate {
    weak var owner: CameraController?

    nonisolated func cameraStreamControlDidStartStream(_ cameraStreamControl: HMCameraStreamControl) {
        Task { @MainActor [weak owner] in owner?.streamDidStart() }
    }

    nonisolated func cameraStreamControl(_ cameraStreamControl: HMCameraStreamControl,
                                         didStopStreamWithError error: Error?) {
        Task { @MainActor [weak owner] in owner?.streamDidStop(error: error) }
    }

    nonisolated func cameraSnapshotControl(_ cameraSnapshotControl: HMCameraSnapshotControl,
                                           didTake snapshot: HMCameraSnapshot?,
                                           error: Error?) {
        Task { @MainActor [weak owner] in owner?.snapshotDidUpdate(error: error) }
    }

    nonisolated func cameraSnapshotControlDidUpdateMostRecentSnapshot(_ cameraSnapshotControl: HMCameraSnapshotControl) {
        Task { @MainActor [weak owner] in owner?.snapshotDidUpdate(error: nil) }
    }
}

/// SwiftUI-Hülle um Apples `HMCameraView` (rendert Snapshot oder Stream).
struct CameraSourceView: UIViewRepresentable {
    let source: HMCameraSource?

    func makeUIView(context: Context) -> HMCameraView {
        let view = HMCameraView()
        view.backgroundColor = .black
        view.cameraSource = source
        return view
    }

    func updateUIView(_ view: HMCameraView, context: Context) {
        if view.cameraSource !== source {
            view.cameraSource = source
        }
    }
}

/// Vollbild-Livebild einer Kamera. Menu-Taste schließt (Standard bei
/// `fullScreenCover`), Select startet den Stream nach einem Fehler neu.
struct CameraFullscreenView: View {
    let accessory: HMAccessory
    let profile: HMCameraProfile
    @State private var controller: CameraController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(accessory: HMAccessory, profile: HMCameraProfile) {
        self.accessory = accessory
        self.profile = profile
        _controller = State(initialValue: CameraController(profile: profile))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraSourceView(source: controller.source)
                .ignoresSafeArea()
            statusOverlay
        }
        .overlay(alignment: .topLeading) { titleBar }
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled()
        .onTapGesture(perform: retryIfNeeded)
        .onPlayPauseCommand(perform: retryIfNeeded)
        .onExitCommand { dismiss() }
        .onAppear {
            isFocused = true
            controller.startStream()
        }
        .onDisappear { controller.stopStream() }
        .onChange(of: scenePhase) { _, phase in
            // Kein Stream im Hintergrund – spart Bandbreite und Kamera-Akku.
            if phase == .active {
                controller.startStream()
            } else {
                controller.stopStream()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessory.name))
    }

    private var titleBar: some View {
        HStack(spacing: 16) {
            if controller.streamState == .streaming {
                Circle().fill(Color.red).frame(width: 16, height: 16)
                Text("camera.live", bundle: .main)
                    .font(.system(size: 24, weight: .bold))
            }
            Text(accessory.name)
                .font(HomeDesign.tileTitleFont)
            if let room = accessory.room?.name {
                Text(room)
                    .font(HomeDesign.tileStatusFont)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.black.opacity(0.45), in: Capsule())
        .padding(.top, HomeDesign.safeAreaV)
        .padding(.leading, HomeDesign.safeAreaH)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch controller.streamState {
        case .starting:
            ProgressView()
                .scaleEffect(1.6)
                .tint(.white)
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 64, weight: .semibold))
                Text(message)
                    .font(HomeDesign.tileTitleFont)
                    .multilineTextAlignment(.center)
                Text("camera.retry", bundle: .main)
                    .font(HomeDesign.tileStatusFont)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .padding(48)
            .background(.black.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
        case .idle, .streaming:
            EmptyView()
        }
    }

    private func retryIfNeeded() {
        if case .failed = controller.streamState {
            controller.startStream()
        }
    }
}
