// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let workout = try? newJSONDecoder().decode(Workout.self, from: jsonData)

import Foundation

// MARK: - WorkoutElement
struct WorkoutElement: Codable {
    let date, workoutName: String
    let exerciseName: ExerciseName
    let setOrder: Int
    let weight: Double
    let reps: Int
    let distance: Double
    let seconds: Int
    let notes: Notes
    let workoutNotes, rpe: String

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case workoutName = "Workout Name"
        case exerciseName = "Exercise Name"
        case setOrder = "Set Order"
        case weight = "Weight"
        case reps = "Reps"
        case distance = "Distance"
        case seconds = "Seconds"
        case notes = "Notes"
        case workoutNotes = "Workout Notes"
        case rpe = "RPE"
    }
    
    func oneRepMax() -> Double {
        return weight / (1.0278 - 0.0278 * Double(reps))
    }
}

enum ExerciseName: String, Codable {
    case benchPressBarbell = "Bench Press (Barbell)"
    case benchPressDumbbell = "Bench Press (Dumbbell)"
    case benchPressSmithMachine = "Bench Press (Smith Machine)"
    case bentOverOneArmRowDumbbell = "Bent Over One Arm Row (Dumbbell)"
    case bicepCurlBarbell = "Bicep Curl (Barbell)"
    case bicepCurlCable = "Bicep Curl (Cable)"
    case bicepCurlDumbbell = "Bicep Curl (Dumbbell)"
    case bicepCurlMachine = "Bicep Curl (Machine)"
    case cableCrossover = "Cable Crossover"
    case chestFly = "Chest Fly"
    case chestFlyDumbbell = "Chest Fly (Dumbbell)"
    case chestPress = "Chest Press"
    case chestPressMachine = "Chest Press (Machine)"
    case chinUpAssisted = "Chin Up (Assisted)"
    case cycling = "Cycling"
    case frontPulldown = "Front Pulldown"
    case hammerCurlDumbbell = "Hammer Curl (Dumbbell)"
    case inclineBenchPressBarbell = "Incline Bench Press (Barbell)"
    case inclineBenchPressDumbbell = "Incline Bench Press (Dumbbell)"
    case inclineChestPressMachine = "Incline Chest Press (Machine)"
    case latPulldownCable = "Lat Pulldown (Cable)"
    case latPulldownMachine = "Lat Pulldown (Machine)"
    case lateralRaiseDumbbell = "Lateral Raise (Dumbbell)"
    case legCurl = "Leg Curl"
    case legExtensionMachine = "Leg Extension (Machine)"
    case legPress = "Leg Press"
    case overheadPressDumbbell = "Overhead Press (Dumbbell)"
    case overheadPressSmithMachine = "Overhead Press (Smith Machine)"
    case pullUpAssisted = "Pull Up (Assisted)"
    case pushUp = "Push Up"
    case reverseFlyCable = "Reverse Fly (Cable)"
    case reverseFlyMachine = "Reverse Fly (Machine)"
    case running = "Running"
    case seatedRowCable = "Seated Row (Cable)"
    case shoulderPressMachine = "Shoulder Press (Machine)"
    case sitUp = "Sit Up"
    case squatBarbell = "Squat (Barbell)"
    case squatBodyweight = "Squat (Bodyweight)"
    case squatSmithMachine = "Squat (Smith Machine)"
    case standingCalfRaiseBarbell = "Standing Calf Raise (Barbell)"
    case standingCalfRaiseDumbbell = "Standing Calf Raise (Dumbbell)"
    case standingCalfRaiseMachine = "Standing Calf Raise (Machine)"
    case standingCalfRaiseSmithMachine = "Standing Calf Raise (Smith Machine)"
    case stretching = "Stretching"
    case tricepsExtension = "Triceps Extension"
    case tricepsExtensionCable = "Triceps Extension (Cable)"
    case tricepsExtensionDumbbell = "Triceps Extension (Dumbbell)"
}

enum Notes: String, Codable {
    case chestPress = "Chest press"
    case empty = ""
    case seatHeight7 = "Seat Height 7"
    case the220NotDeepEnough = "220 not deep enough"
}

typealias Workouts = [WorkoutElement]
