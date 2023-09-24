//
//  ContentView.swift
//  mcro
//
//  Created by Jon Schenk on 9/23/23.
//

import SwiftUI
import SwiftData

// Create a struct to represent a daily log entry
struct DailyLog: Codable {
    var date: Date
    var proteinIntake: Double
    var calorieIntake: Double
    
    enum CodingKeys: String, CodingKey {
        case date
        case proteinIntake
        case calorieIntake
    }
}

func saveDailyLogs(_ dailyLogs: [DailyLog]) {
    let encoder = JSONEncoder()
    if let encodedData = try? encoder.encode(dailyLogs) {
        UserDefaults.standard.set(encodedData, forKey: "dailyLogs")
    }
}

func loadDailyLogs() -> [DailyLog] {
    if let data = UserDefaults.standard.data(forKey: "dailyLogs"),
       let logs = try? JSONDecoder().decode([DailyLog].self, from: data) {
        return logs
    } else {
        return []
    }
}

// Save goals to UserDefaults
func saveGoals(proteinGoal: Double, calorieGoal: Double) {
    UserDefaults.standard.set(proteinGoal, forKey: "proteinGoal")
    UserDefaults.standard.set(calorieGoal, forKey: "calorieGoal")
}

// Load goals from UserDefaults
func loadGoals() -> (proteinGoal: Double, calorieGoal: Double) {
    let proteinGoal = UserDefaults.standard.double(forKey: "proteinGoal")
    let calorieGoal = UserDefaults.standard.double(forKey: "calorieGoal")
    return (proteinGoal, calorieGoal)
}

extension View {
    func customFont() -> some View {
        self.modifier(CustomFont())
    }
}

struct CustomFont: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("CourierNewPS-BoldMT", size: 16))
    }
}

struct BlackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct ContentView: View {
    @State private var proteinIntake: Double = 0
    @State private var calorieIntake: Double = 0
    @State private var isEditGoalsActive = false
    @State private var dailyLogs: [DailyLog] = loadDailyLogs()
    @State private var isStartPageActive = loadDailyLogs().isEmpty // Initialize based on logs

    // Load goals globally
    @AppStorage("proteinGoal") var proteinGoal: Double = 0 // Load the protein goal
    @AppStorage("calorieGoal") var calorieGoal: Double = 0 // Load the calorie goal


    var body: some View {
        NavigationView {
            Group {
                if isStartPageActive { // Show StartPage initially
                    StartPage(
                        proteinGoal: $proteinGoal,
                        calorieGoal: $calorieGoal,
                        proteinIntake: $proteinIntake,
                        calorieIntake: $calorieIntake,
                        isStartPageActive: $isStartPageActive
                    )
                    .transition(.move(edge: .bottom))
                } else {
                    TabView {
                        HomeView(
                            proteinIntake: $proteinIntake,
                            calorieIntake: $calorieIntake,
                            proteinGoal: $proteinGoal, // Pass protein goal
                            calorieGoal: $calorieGoal, // Pass calorie goal
                            isEditGoalsActive: $isEditGoalsActive,
                            dailyLogs: $dailyLogs
                        )
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }

                        DailyLogListView(dailyLogs: $dailyLogs)
                        .tabItem {
                            Image(systemName: "book")
                            Text("Log")
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .sheet(isPresented: $isEditGoalsActive) {
                        EditGoalsView(
                            proteinGoal: $proteinGoal, // Pass protein goal
                            calorieGoal: $calorieGoal, // Pass calorie goal
                            isEditGoalsActive: $isEditGoalsActive
                        )
                    }
                }
            }
            .customFont()
        }
        .customFont()
    }
}

struct HomeView: View {
    @Binding var proteinIntake: Double
    @Binding var calorieIntake: Double
    @Binding var proteinGoal: Double
    @Binding var calorieGoal: Double
    @Binding var isEditGoalsActive: Bool
    @Binding var dailyLogs: [DailyLog]

    private var currentDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM dd, yyyy"
        return dateFormatter.string(from: Date())
    }

    var body: some View {
        let todayLog = dailyLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) })

        VStack(spacing: 20) {
            Text("Progress")
                .font(.custom("Courier New", size: 30).bold())

            Text(currentDate) // Display the current day here
                .font(.custom("Courier New", size: 16))
                .foregroundColor(.gray)

            if let todayLog = todayLog {
                CircularProgressBar(value: todayLog.proteinIntake, goal: proteinGoal, label: "grams", color: Color(red: 122/255, green: 255/255, blue: 209/255))
                    .frame(width: 150, height: 150) // Adjust the size of the circular progress bar

                CircularProgressBar(value: todayLog.calorieIntake, goal: calorieGoal, label: "kcal", color: Color(red: 171/255, green: 122/255, blue: 255/255))
                    .frame(width: 150, height: 150) // Adjust the size of the circular progress bar
            } else {
                // Display a message when there's no log entry for the current day
                Text("No data available for today.")
                    .foregroundColor(.gray)
                    .italic()
            }

            Button(action: {
                isEditGoalsActive = true // Show the Edit Goals sheet
            }) {
                Text("Edit Goals")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(BlackButtonStyle())
            .padding(.horizontal)

            NavigationLink(destination: AddPage(proteinIntake: $proteinIntake, calorieIntake: $calorieIntake, dailyLogs: $dailyLogs)) {
                Text("Add")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(BlackButtonStyle())
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct EditGoalsView: View {
    @Binding var proteinGoal: Double
    @Binding var calorieGoal: Double
    @Binding var isEditGoalsActive: Bool

    @State private var proteinInput: String = ""
    @State private var calorieInput: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Goals")
                    .font(.custom("Courier New", size: 30).bold())
                    .padding()
                TextField("Enter Desired Protein Goal", text: $proteinInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()

                TextField("Enter Desired Calorie Goal", text: $calorieInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()

                Button(action: {
                    if let proteinValue = Double(proteinInput), proteinValue >= 0 {
                        proteinGoal = proteinValue
                        saveGoals(proteinGoal: proteinValue, calorieGoal: calorieGoal) // Save protein goal
                    }
                    if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                        calorieGoal = calorieValue
                        saveGoals(proteinGoal: proteinGoal, calorieGoal: calorieValue) // Save calorie goal
                    }
                    isEditGoalsActive = false // Dismiss the Edit Goals view
                }) {
                    Text("Save Goals")
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(BlackButtonStyle())
                .padding()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
    }
}

struct DailyLogListView: View {
    @Binding var dailyLogs: [DailyLog]
    
    var body: some View {
        NavigationView {
            if dailyLogs.isEmpty {
                Text("No logs available.\nLogs will appear when data is added.")
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(dailyLogs, id: \.date) { log in
                        NavigationLink(destination: DailyLogDetailView(log: log)) {
                            Text("\(log.date.formattedDate())")
                        }
                    }
                    .onDelete(perform: deleteLog)
                }
            }
        }
    }
    
    private func deleteLog(at offsets: IndexSet) {
        dailyLogs.remove(atOffsets: offsets)
        
        // Save the updated daily logs to storage (you can use CoreData or another storage mechanism)
        if let encodedLogs = try? JSONEncoder().encode(dailyLogs) {
            UserDefaults.standard.set(encodedLogs, forKey: "dailyLogs")
        }
    }
}

struct DailyLogDetailView: View {
    var log: DailyLog
    
    private let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            return formatter
        }()
    
    var body: some View {
        VStack {
            Text("Date: \(log.date.formattedDate())")
                .font(.custom("Courier New", size: 16).bold())
                .padding()
            Text("Protein Intake: \(numberFormatter.string(for: log.proteinIntake) ?? "0") grams")
                .font(.custom("Courier New", size: 16))
                .padding()
                        
            Text("Calorie Intake: \(numberFormatter.string(for: log.calorieIntake) ?? "0") kcal")
                .font(.custom("Courier New", size: 16))
                .padding()
        }
    }
}

extension Date {
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}

struct ProgressBar: View {
    var value: Double
    var goal: Double
    var label: String
    var color: Color
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 20) // Make the progress bar taller
                    .foregroundColor(Color.gray)
                
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: min(CGFloat(value / goal), 1.0) * geometry.size.width, height: 20)
                        .foregroundColor(color) // Use the specified color
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CircularProgressBar: View {
    var value: Double
    var goal: Double
    var label: String
    var color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 10) // Gray background circle
                    .frame(width: 100, height: 100) // Adjust the size as needed
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(value / goal, 1.0))) // Use the percentage of completion
                    .stroke(color, lineWidth: 10) // Colored circle indicating progress
                    .frame(width: 100, height: 100) // Adjust the size as needed
                    .rotationEffect(.degrees(-90)) // Rotate to start from the top
            
                VStack(spacing: 0) {
                    Text(label)
                        .customFont() // Apply the custom font modifier to the label
                        .foregroundColor(Color.primary) // Set the text color based on the system appearance
                        .padding(.bottom, 4) // Adjust spacing between label and numbers
                
                    Text("\(Int(value))/\(Int(goal))") // Display progress numbers
                        .customFont() // Apply the custom font modifier to the numbers
                        .foregroundColor(Color.primary) // Set the text color based on the system appearance
                }
                .offset(y: -10) // Adjust the vertical position of the label and numbers
            }
        }
        .padding(.vertical, 4)
    }
}

struct StartPage: View {
    @Binding var proteinGoal: Double
    @Binding var calorieGoal: Double
    @Binding var proteinIntake: Double
    @Binding var calorieIntake: Double
    @Binding var isStartPageActive: Bool
    
    @State private var proteinInput: String = ""
    @State private var calorieInput: String = ""
    
    var body: some View {
        VStack {
            Text("Welcome to Protein Tracker")
                .font(.custom("Courier New", size: 50).bold()) // Apply custom font and make it bold
                .padding()
            
            Spacer() // Pushes the following content to the bottom
            
            Text("Set your daily goals to get started.")
                .font(.custom("Courier New", size: 16)) // Apply custom font (monospace)
                .padding()
            
            TextField("Enter Desired Protein Goal", text: $proteinInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            TextField("Enter Desired Calorie Goal", text: $calorieInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Button(action: {
                if let proteinValue = Double(proteinInput), proteinValue >= 0 {
                    proteinGoal = proteinValue
                }
                if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                    calorieGoal = calorieValue
                }
                isStartPageActive = false // Close the StartPage
            }) {
                Text("Set Goals")
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(BlackButtonStyle())
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct AddPage: View {
    @Binding var proteinIntake: Double
    @Binding var calorieIntake: Double
    @Binding var dailyLogs: [DailyLog]
    @State private var proteinInput: String = ""
    @State private var calorieInput: String = ""
    
    @Environment(\.presentationMode) var presentationMode // Allows dismissing the view
    
    var body: some View {
        VStack {
            Text("Add your protein and calories")
                .font(.title)
            
            TextField("Enter Protein Intake", text: $proteinInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            TextField("Enter Calorie Intake", text: $calorieInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Button(action: {
                if let proteinValue = Double(proteinInput), proteinValue >= 0 {
                    proteinIntake = proteinValue
                }
                if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                    calorieIntake = calorieValue
                }
                
                // Get the current date
                let currentDate = Date()
                
                // Check if a log entry for the current date already exists
                if let existingLogIndex = dailyLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
                    // Update the existing log entry with the new values
                    dailyLogs[existingLogIndex].proteinIntake += proteinIntake
                    dailyLogs[existingLogIndex].calorieIntake += calorieIntake
                } else {
                    // Create a new log entry if one does not exist for the current date
                    let logEntry = DailyLog(date: currentDate, proteinIntake: proteinIntake, calorieIntake: calorieIntake)
                    dailyLogs.append(logEntry)
                }
                
                // Save daily logs to storage
                saveDailyLogs(dailyLogs)
                
                // Dismiss the AddPage and return to the previous view (home page)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add")
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(BlackButtonStyle())
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .navigationBarTitle("Add Protein/Calories")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
