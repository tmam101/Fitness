// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let workout = try? newJSONDecoder().decode(Workout.self, from: jsonData)

import Foundation

// MARK: - WorkoutElement

struct OneRepMax {
    var exerciseName: String
    var date: Date
    var weight: Double
}

struct WorkoutSet: Codable {
    let date, workoutName, duration, exerciseName: String
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
        case duration = "Duration"
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
    
    enum Notes: String, Codable {
        case chestPress = "Chest press"
        case empty = ""
        case seatHeight7 = "Seat Height 7"
        case the220NotDeepEnough = "220 not deep enough"
    }
    
    enum ExerciseName: String {
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
    
    func oneRepMax() -> Double {
        return Double(weight) / (1.0278 - 0.0278 * Double(reps))
    }
    
    func getDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: self.date)
    }
}

typealias Workout = [WorkoutSet]

class WorkoutManager: ObservableObject {
    var environment: AppEnvironmentConfig = .debug
    @Published var workouts: Workout = []
    @Published var workoutsGroupedByDay: [Workout] = []
    @Published public var firstBenchORM: Double = 0.0
    @Published public var benchORM: Double = 0.0
    @Published public var firstSquatORM: Double = 0.0
    @Published public var squatORM: Double = 0.0
    @Published public var smithMachine: Bool = false
    
    @Published public var benchORMs: [OneRepMax] = []
    @Published public var squatORMs: [OneRepMax] = []
    
    let formatter = DateFormatter()
    
    static let squatBodyweightRatio: Double = 1.6
    static let benchBodyweightRatio: Double = 1.2
//    init() {
//        if let filepath = Bundle.main.path(forResource: "strong", ofType: "json") {
//            do {
//                let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
//                let decoded = try JSONDecoder().decode(Workouts.self, from: data)
//                self.workouts = decoded
//                self.benchORM = oneRepMax(timeFrame: .mostRecent, tag: "bench")
//                self.squatORM = oneRepMax(timeFrame: .mostRecent, tag: "squat")
//            } catch {
//                
//            }
//        }
//    }
    
    init() { }
    
    init(afterDate: Date, environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release:
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            if let filepath = Bundle.main.path(forResource: "strong", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
                    let decoded = try JSONDecoder().decode(Workout.self, from: data)
                    self.workouts = decoded
                    self.workouts = workouts.filter {
                        formatter.date(from: $0.date)! > afterDate
                    }
                    
                    calculate()
                } catch {
                    print("error failed getting workouts")
                }
            } else {
                print("error failed getting workouts")
            }
        case .debug, .widgetRelease:
            self.firstBenchORM = 100
            self.firstSquatORM = 100
            self.benchORM = 150
            self.squatORM = 150
        }
    }
    
    func setup(afterDate: Date, environment: AppEnvironmentConfig) async {
        self.environment = environment
        switch environment {
        case .release:
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            if let filepath = Bundle.main.path(forResource: "strong", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
                    let decoded = try JSONDecoder().decode(Workout.self, from: data)
                    self.workouts = decoded
                    self.workouts = workouts.filter {
                        formatter.date(from: $0.date)! > afterDate
                    }
                    
                    calculate()
                } catch {
                    print("error failed getting workouts")
                }
            } else {
                print("error failed getting workouts")
            }
        case .debug, .widgetRelease:
            self.firstBenchORM = 100
            self.firstSquatORM = 100
            self.benchORM = 150
            self.squatORM = 150
        }
    }
    
    init(afterDate: String, environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release:
            
            formatter.dateFormat = "MM.dd.yyyy"
            let afterDateCorrected = formatter.date(from: afterDate)
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            if let filepath = Bundle.main.path(forResource: "strong", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
                    let decoded = try JSONDecoder().decode(Workout.self, from: data)
                    self.workouts = decoded
                    self.workouts = workouts.filter {
                        formatter.date(from: $0.date)! > afterDateCorrected!
                    }
                    
                    calculate()
                } catch {
                    
                }
            }
        case .debug, .widgetRelease:
            //            self.workouts = Workouts(arrayLiteral: [WorkoutElement(])
            self.firstBenchORM = 100
            self.firstSquatORM = 100
            self.benchORM = 150
            self.squatORM = 150
        }
    }
    
    func calculate() {
        switch environment {
        case .release:
            let squatType: WorkoutSet.ExerciseName = smithMachine ? .squatSmithMachine : .squatBarbell
            let benchType: WorkoutSet.ExerciseName = smithMachine ? .benchPressSmithMachine : .benchPressBarbell
            
            self.firstBenchORM = oneRepMax(timeFrame: .first, exerciseName: benchType)
            self.firstSquatORM = oneRepMax(timeFrame: .first, exerciseName: squatType)
            self.benchORM = oneRepMax(timeFrame: .mostRecent, exerciseName: benchType)
            self.squatORM = oneRepMax(timeFrame: .mostRecent, exerciseName: squatType)
            self.benchORMs = allOneRepMaxes(exerciseName: benchType)
            self.squatORMs = allOneRepMaxes(exerciseName: squatType)
        case .debug, .widgetRelease:
            self.firstBenchORM = 100
            self.firstSquatORM = 100
            self.benchORM = 150
            self.squatORM = 150
        }
    }
    
    enum TimeFrame {
        case mostRecent
        case first
    }
    
    func allOneRepMaxes(exerciseName: WorkoutSet.ExerciseName? = nil, exerciseNames: [WorkoutSet.ExerciseName]? = nil, tag: String? = nil) -> [OneRepMax] {
        var exercises: Workout = []
        if let name = exerciseName {
            exercises = workouts.filter { $0.exerciseName == name.rawValue }
        } else if let names = exerciseNames {
            exercises = workouts.filter { names.map { $0.rawValue }.contains($0.exerciseName) }
        } else if let tag = tag {
            exercises = workouts.filter { $0.exerciseName.lowercased().contains(tag.lowercased())}
        } else {
            return []
        }
//        var sameDates: [Workout] = []
        var x: [Date: Double] = [:]
//        var orms: [OneRepMax] = []
//        let sameDate = exercises.filter {
//            timeFrame == .mostRecent ?
//                $0.getDate() == exercises.last?.getDate() :
//                $0.getDate() == exercises.first?.getDate()
//        }
        for e in exercises {
//            print(e.oneRepMax())
//            print(e.getDate())
            if e.oneRepMax() > (x[e.getDate()!] ?? 0) {
                print("adding")
                x[e.getDate()!] = e.oneRepMax()
            }
        }
        var y: [OneRepMax] = x.map { OneRepMax(exerciseName: (exerciseName?.rawValue ?? exerciseNames?.first?.rawValue ?? ""), date: $0.key, weight: $0.value) }
        y.sort { $0.date < $1.date }
        return y
    }
    
    func oneRepMax(timeFrame: TimeFrame, exerciseName: WorkoutSet.ExerciseName? = nil, exerciseNames: [WorkoutSet.ExerciseName]? = nil, tag: String? = nil) -> Double {
        var exercises: Workout = []
        if let name = exerciseName {
            exercises = workouts.filter { $0.exerciseName == name.rawValue }
        } else if let names = exerciseNames {
            exercises = workouts.filter { names.map { $0.rawValue }.contains($0.exerciseName) }
        } else if let tag = tag {
            exercises = workouts.filter { $0.exerciseName.lowercased().contains(tag.lowercased())}
        } else {
            return 0.0
        }
        let sameDate = exercises.filter {
            timeFrame == .mostRecent ?
                $0.getDate() == exercises.last?.getDate() :
                $0.getDate() == exercises.first?.getDate()
        }
        let max = sameDate
            .map { $0.oneRepMax() }
            .max() ?? 0.0
        return max
    }
    
}
