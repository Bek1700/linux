// Live camera + on-device classification. Photos are never written to disk or uploaded.
import SwiftUI
import AVFoundation

final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    var onPhoto: ((UIImage) -> Void)?

    func start() {
        guard session.inputs.isEmpty,
              let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: dev) else { return }
        session.addInput(input); session.addOutput(output)
        DispatchQueue.global().async { self.session.startRunning() }
    }
    func stop() { session.stopRunning() }
    func capture() { output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self) }

    func photoOutput(_ o: AVCapturePhotoOutput, didFinishProcessingPhoto p: AVCapturePhoto, error: Error?) {
        guard let d = p.fileDataRepresentation(), let img = UIImage(data: d) else { return }
        DispatchQueue.main.async { self.onPhoto?(img) }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let v = UIView(); let l = AVCaptureVideoPreviewLayer(session: session)
        l.videoGravity = .resizeAspectFill; v.layer.addSublayer(l); return v
    }
    func updateUIView(_ v: UIView, context: Context) { v.layer.sublayers?.first?.frame = v.bounds }
}

struct ProofCameraView: View {
    let title: String
    let onAccepted: () -> Void
    var classifier: ProofClassifying = VisionProofClassifier()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraController()
    @State private var message = "Point the camera at a prayer mat, Quran, tasbih, sink or mosque."
    @State private var busy = false

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session).ignoresSafeArea()
            VStack {
                Text(title).font(.headline).padding(.top, 40)
                Text(message).font(.footnote).multilineTextAlignment(.center).padding()
                Spacer()
                HStack {
                    Button("Cancel") { dismiss() }
                    Spacer()
                    Button { busy = true; camera.capture() } label: {
                        Circle().strokeBorder(.white, lineWidth: 4).frame(width: 72, height: 72)
                    }.disabled(busy)
                    Spacer()
                    Button("Checkmark") { onAccepted(); dismiss() } // honest-mode fallback, as in the reference flow
                }.padding(30)
            }.foregroundStyle(.white)
        }
        .onAppear {
            camera.onPhoto = { img in
                Task {
                    if await classifier.accepts(img) { onAccepted(); dismiss() }
                    else { message = "Not recognised. Try again with the object clearly in view."; busy = false }
                }
            }
            camera.start()
        }
        .onDisappear { camera.stop() }
    }
}
