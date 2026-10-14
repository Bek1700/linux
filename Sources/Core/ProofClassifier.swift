// On-device "show me a prayer mat / Quran / sink" check. Uses Apple's built-in Vision classifier,
// so no image leaves the phone. Generic labels are weak for niche objects: for production,
// train a small Core ML image classifier and plug it in through `ProofClassifying`.
import Vision
import UIKit

protocol ProofClassifying { func accepts(_ image: UIImage) async -> Bool }

struct VisionProofClassifier: ProofClassifying {
    static let keywords = ["carpet", "rug", "mat", "prayer", "book", "rosary", "bead", "sink", "faucet",
                           "tap", "mosque", "minaret", "dome", "mihrab", "bathroom", "washbasin"]
    var minimumConfidence: Float = 0.12

    func accepts(_ image: UIImage) async -> Bool {
        guard let cg = image.cgImage else { return false }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cg)
        return await Task.detached {
            guard (try? handler.perform([request])) != nil else { return false }
            let hits = (request.results ?? []).filter {
                $0.confidence >= minimumConfidence && Self.keywords.contains { k in $0.identifier.lowercased().contains(k) }
            }
            return !hits.isEmpty
        }.value
    }
}
