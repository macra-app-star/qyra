import Foundation
import Vision
import UIKit

// INTEGRATED FROM: Apple Vision framework (VNDetectHumanBodyPoseRequest)
// Real-time pose estimation for exercise form feedback.
// No external model needed — uses Apple's built-in body pose detection.

actor PoseEstimationService {
    static let shared = PoseEstimationService()

    // MARK: - Detect Pose

    /// Detect body pose in an image. Returns joint positions normalized 0-1.
    func detectPose(in image: CGImage) async throws -> BodyPose? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let pose = try BodyPose(from: observation)
                    continuation.resume(returning: pose)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Form Analysis

    /// Analyze squat form based on joint angles
    func analyzeSquatForm(_ pose: BodyPose) -> FormFeedback {
        guard let hipAngle = pose.hipAngle,
              let kneeAngle = pose.kneeAngle else {
            return FormFeedback(quality: .unknown, tips: ["Stand facing the camera so all joints are visible."])
        }

        var tips: [String] = []
        var quality: FormQuality = .good

        // Check squat depth (knee angle < 90° = deep squat)
        if kneeAngle > 160 {
            quality = .poor
            tips.append("Go deeper — aim for thighs parallel to ground.")
        } else if kneeAngle > 120 {
            quality = .fair
            tips.append("Almost there — try to get a bit lower.")
        }

        // Check hip hinge (hip angle should open as you descend)
        if hipAngle < 70 {
            quality = min(quality, .fair)
            tips.append("Open your hips more — push your knees out.")
        }

        // Check back angle (torso should stay upright-ish)
        if let torsoAngle = pose.torsoAngle, torsoAngle < 45 {
            quality = min(quality, .fair)
            tips.append("Keep your chest up — avoid leaning too far forward.")
        }

        if tips.isEmpty {
            tips.append("Great form! Keep it up.")
        }

        return FormFeedback(quality: quality, tips: tips)
    }

    /// Analyze push-up form
    func analyzePushUpForm(_ pose: BodyPose) -> FormFeedback {
        guard let elbowAngle = pose.elbowAngle else {
            return FormFeedback(quality: .unknown, tips: ["Position yourself sideways to the camera."])
        }

        var tips: [String] = []
        var quality: FormQuality = .good

        if elbowAngle > 160 {
            quality = .poor
            tips.append("Lower your chest closer to the ground.")
        } else if elbowAngle > 120 {
            quality = .fair
            tips.append("Try to get your elbows to 90 degrees.")
        }

        // Check body alignment (hips shouldn't sag)
        if let torsoAngle = pose.torsoAngle, torsoAngle < 150 {
            quality = min(quality, .fair)
            tips.append("Keep your body in a straight line — engage your core.")
        }

        if tips.isEmpty {
            tips.append("Solid push-up form!")
        }

        return FormFeedback(quality: quality, tips: tips)
    }

    // MARK: - Rep Counting

    /// Simple rep counter based on joint angle oscillation
    func detectRep(currentAngle: Double, previousAngle: Double, threshold: Double = 30) -> Bool {
        // A rep is counted when angle goes from extended → flexed → extended
        let isFlexing = currentAngle < previousAngle - threshold
        return isFlexing
    }
}

// MARK: - Body Pose Model

struct BodyPose: Sendable {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidence: [VNHumanBodyPoseObservation.JointName: Float]

    init(from observation: VNHumanBodyPoseObservation) throws {
        let recognized = try observation.recognizedPoints(.all)
        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var confidence: [VNHumanBodyPoseObservation.JointName: Float] = [:]

        for (key, point) in recognized where point.confidence > 0.3 {
            // Vision coordinates: origin bottom-left, y-up. Convert to top-left.
            joints[key] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            confidence[key] = point.confidence
        }

        self.joints = joints
        self.confidence = confidence
    }

    // MARK: - Angle Calculations

    /// Angle at the knee (hip-knee-ankle)
    var kneeAngle: Double? {
        angleBetween(
            joints[.rightHip] ?? joints[.leftHip],
            joints[.rightKnee] ?? joints[.leftKnee],
            joints[.rightAnkle] ?? joints[.leftAnkle]
        )
    }

    /// Angle at the hip (shoulder-hip-knee)
    var hipAngle: Double? {
        angleBetween(
            joints[.rightShoulder] ?? joints[.leftShoulder],
            joints[.rightHip] ?? joints[.leftHip],
            joints[.rightKnee] ?? joints[.leftKnee]
        )
    }

    /// Angle at the elbow (shoulder-elbow-wrist)
    var elbowAngle: Double? {
        angleBetween(
            joints[.rightShoulder] ?? joints[.leftShoulder],
            joints[.rightElbow] ?? joints[.leftElbow],
            joints[.rightWrist] ?? joints[.leftWrist]
        )
    }

    /// Torso angle relative to vertical
    var torsoAngle: Double? {
        guard let shoulder = joints[.rightShoulder] ?? joints[.leftShoulder],
              let hip = joints[.rightHip] ?? joints[.leftHip] else { return nil }

        let dx = Double(shoulder.x - hip.x)
        let dy = Double(shoulder.y - hip.y)
        return abs(atan2(dx, -dy) * 180.0 / Double.pi)
    }

    private func angleBetween(_ a: CGPoint?, _ b: CGPoint?, _ c: CGPoint?) -> Double? {
        guard let a, let b, let c else { return nil }
        let baX = Double(a.x - b.x)
        let baY = Double(a.y - b.y)
        let bcX = Double(c.x - b.x)
        let bcY = Double(c.y - b.y)
        let dot = baX * bcX + baY * bcY
        let magBA = sqrt(baX * baX + baY * baY)
        let magBC = sqrt(bcX * bcX + bcY * bcY)
        guard magBA > 0, magBC > 0 else { return nil }
        let cosAngle = max(-1.0, min(1.0, dot / (magBA * magBC)))
        return acos(cosAngle) * 180.0 / Double.pi
    }
}

// MARK: - Form Feedback

struct FormFeedback: Sendable {
    let quality: FormQuality
    let tips: [String]
}

enum FormQuality: Int, Comparable, Sendable {
    case unknown = 0
    case poor = 1
    case fair = 2
    case good = 3

    static func < (lhs: FormQuality, rhs: FormQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .unknown: return "—"
        case .poor: return "Needs work"
        case .fair: return "Getting there"
        case .good: return "Great form"
        }
    }

    var color: String {
        switch self {
        case .unknown: return "gray"
        case .poor: return "red"
        case .fair: return "orange"
        case .good: return "green"
        }
    }
}
