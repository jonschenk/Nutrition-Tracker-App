//
//  ContentView.swift
//  mcro
//
//  Created by Jon Schenk on 9/23/23.
//

import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var proteinIntake: Double = 0
    @State private var calorieIntake: Double = 0
    @State private var proteinGoal: Double = 0
    @State private var calorieGoal: Double = 0
    
    @State private var isStartPageActive = true // Initially show the Start Page
    @State private var isEditGoalsActive = false // Track the state of the Edit Goals sheet
    
    var body: some View {
        NavigationView {
            Group {
                if isStartPageActive {
                    StartPage(proteinGoal: $proteinGoal, calorieGoal: $calorieGoal, proteinIntake: $proteinIntake, calorieIntake: $calorieIntake, isStartPageActive: $isStartPageActive)
                        .transition(.move(edge: .bottom))
                } else {
                    HomeView(proteinIntake: $proteinIntake, calorieIntake: $calorieIntake, proteinGoal: $proteinGoal, calorieGoal: $calorieGoal, isEditGoalsActive: $isEditGoalsActive)
                        .transition(.move(edge: .bottom))
                        .sheet(isPresented: $isEditGoalsActive) {
                            EditGoalsView(proteinGoal: $proteinGoal, calorieGoal: $calorieGoal, isEditGoalsActive: $isEditGoalsActive)
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
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Progress")
                .font(.custom("Courier New", size: 30).bold())
            
            CircularProgressBar(value: proteinIntake, goal: proteinGoal, label: "grams", color: Color(red: 122/255, green: 255/255, blue: 209/255))
                .frame(width: 150, height: 150) // Adjust the size of the circular progress bar
            
            CircularProgressBar(value: calorieIntake, goal: calorieGoal, label: "kcal", color: Color(red: 171/255, green: 122/255, blue: 255/255))
                .frame(width: 150, height: 150) // Adjust the size of the circular progress bar
            
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
            
            NavigationLink(destination: AddPage(proteinIntake: $proteinIntake, calorieIntake: $calorieIntake)) {
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
                        .foregroundColor(.black) // Set the color as needed
                
                    Text("\(Int(value))/\(Int(goal))") // Display progress numbers
                        .customFont() // Apply the custom font modifier to the numbers
                        .foregroundColor(.black) // Set the color as needed
                }
                .offset(y: -10) // Adjust the vertical position of the label and numbers
            }
        }
            .padding(.vertical, 4)
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
                    .font(.custom("Courier New", size: 16).bold())
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
            .navigationBarTitle("Edit Goals")
        }
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
            
            TextField("Enter Desired Protein Goal", text: $proteinInput, onCommit: {
                if let proteinValue = Double(proteinInput), proteinValue >= 0 {
                    proteinGoal = proteinValue
                    isStartPageActive = false // Close the StartPage
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .padding()
            
            TextField("Enter Desired Calorie Goal", text: $calorieInput, onCommit: {
                if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                    calorieGoal = calorieValue
                    isStartPageActive = false // Close the StartPage
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .padding()
            
            Button(action: {
                if let proteinValue = Double(proteinInput), proteinValue >= 0 {
                    proteinGoal = proteinValue
                    isStartPageActive = false // Close the StartPage
                }
                if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                    calorieGoal = calorieValue
                    isStartPageActive = false // Close the StartPage
                }
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
    @State private var proteinInput: String = ""
    @State private var calorieInput: String = ""
    
    @Environment(\.presentationMode) var presentationMode // Allows dismissing the view
    
    var body: some View {
        VStack {
            Text("Add Page")
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
                    proteinIntake += proteinValue
                }
                if let calorieValue = Double(calorieInput), calorieValue >= 0 {
                    calorieIntake += calorieValue
                }
                
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
