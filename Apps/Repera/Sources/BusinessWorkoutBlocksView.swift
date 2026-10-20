import SwiftUI

/// Vista solo de lectura de los bloques que publicó el profesional.
/// Las series reales del deportista siguen en su ReperaStore privado.
struct BusinessWorkoutBlocksView: View {
    let prescription: BusinessWorkoutPrescription?

    var body: some View {
        if let blocks = prescription?.blocks, !blocks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { entry in
                    let block = entry.element
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: block.kind == "wod" ? "timer" : "square.stack.3d.up")
                                .foregroundStyle(OG.accent)
                            Text(block.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(OG.label)
                            Spacer(minLength: 0)
                            Text(block.format.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(OG.label2)
                        }
                        if block.kind == "wod" {
                            HStack(spacing: 10) {
                                if let rounds = block.rounds, rounds > 1 {
                                    Label("\(rounds) rondas", systemImage: "repeat")
                                }
                                if let time = block.timeCap, time > 0 {
                                    Label("\(time) min", systemImage: "clock")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        }
                        ForEach(Array(block.exercises.enumerated()), id: \.offset) { exerciseEntry in
                            let exercise = exerciseEntry.element
                            HStack(alignment: .center, spacing: 10) {
                                BusinessWorkoutThumb(name: exercise.name)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(OG.label)
                                    let target = [
                                        exercise.sets.map { "\($0) series" },
                                        exercise.reps.map { "\($0) reps" },
                                        exercise.rir.map { "RIR \($0)" },
                                        exercise.weight.flatMap { $0 > 0 ? "\(Int($0)) kg" : nil },
                                        exercise.duration.flatMap { $0 > 0 ? "\($0) s" : nil }
                                    ].compactMap { $0 }.joined(separator: " · ")
                                    if !target.isEmpty {
                                        Text(target)
                                            .font(.caption)
                                            .foregroundStyle(OG.label2)
                                    }
                                    if let notes = exercise.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(OG.label2)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(11)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.top, 4)
        }
    }
}

private struct BusinessWorkoutThumb: View {
    let name: String
    @State private var loaded: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(OG.surface2)
            if let loaded {
                Image(uiImage: loaded)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundStyle(OG.label2)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task(id: name) {
            loaded = nil
            guard let artName = ExerciseArt.imageName(forExerciseName: name, muscleGroup: "") else { return }
            loaded = await ThumbImageLoader.shared.load(named: artName, maxPixel: 144)
        }
    }
}