import SwiftUI

struct ContentView: View {
    var body: some View {
        TaskPlannerView()
        .onAppear {
            for family in UIFont.familyNames.sorted() {
              let names = UIFont.fontNames(forFamilyName: family)
              print(family, names)
            }
        }
    }
}

struct AddTaskView: View {
    var onAdd: (Task) -> ()
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var category = Category.general
    @State private var animateColor = Category.general.color
    @State private var animate = false
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 10.0) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                Text("Create New Task")
                    .ubuntu(size: 28, weight: .light)
                
                TitleView("NAME")
                
                TextField("Make New Video", text: $name)
                    .ubuntu(size: 12)
                    .tint(.white)
                    .offset(y: -5)
                    .overlay(alignment: .bottom) {
                        underline.offset(y: 5)
                    }
                
                TitleView("DATE")
                
                HStack {
                    HStack {
                        Text(date.toString(format: "EEEE dd, MMMM"))
                            .ubuntu(size: 16)
                        Image(systemName: "calendar")
                            .font(.title3)
                            .overlay {
                                DatePicker("", selection: $date, displayedComponents: [.date])
                                    .blendMode(.destinationOver)
                            }
                    }
                    .offset(y: -5)
                    .overlay(alignment: .bottom) {
                        underline.offset(y: 5)
                    }
                    
                    HStack {
                        Text(date.toString(format: "hh:mm a"))
                            .ubuntu(size: 16)
                        Image(systemName: "clock")
                            .font(.title3)
                            .overlay {
                                DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                                    .blendMode(.destinationOver)
                            }
                    }
                    .offset(y: -5)
                    .overlay(alignment: .bottom) {
                        underline.offset(y: 5)
                    }
                }

            }
            .environment(\.colorScheme, .dark)
            .foregroundColor(.white)
            .hAlign(.leading)
            .padding(15)
            .background {
                ZStack {
                    category.color
                    GeometryReader {
                        let size = $0.size
                        Rectangle()
                            .fill(animateColor)
                            .mask { Circle() }
                            .frame(width: animate ? size.width * 2 : 0,
                                   height: animate ? size.height * 2 : 0)
                            .offset(animate ? CGSize(width: -size.width / 2,
                                                     height: -size.height / 2)
                                    : size)
                    }
                    .clipped()
                }
                .ignoresSafeArea()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                TitleView("DESCRIPTION", color: .gray)
                
                TextEditor(text: $description)
                    .ubuntu(size: 16)
                    .frame(height: 60)
                
                Rectangle()
                    .fill(.black.opacity(0.2))
                    .frame(height: 1)
                
                TitleView("CATEGORY", color: .gray)
                
                LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 20), count: 3), spacing: 15) {
                    ForEach(Category.allCases, id: \.rawValue) { category in
                        Text(category.rawValue.uppercased())
                            .ubuntu(size: 12)
                            .hAlign(.center)
                            .padding(.vertical, 5)
                            .background {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(category.color.opacity(0.25))
                            }
                            .foregroundColor(category.color)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !animate else { return }
                                animateColor = category.color
                                withAnimation(.interactiveSpring(response: 0.7, dampingFraction: 1, blendDuration: 1)) {
                                    animate = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    animate = false
                                    self.category = category
                                }
                            }
                    }
                }
                
                Button {
                    let task = Task(date: date, name: name, description: description, category: category)
                    onAdd(task)
                } label: {
                    Text("Create Task")
                        .ubuntu(size: 16)
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .hAlign(.center)
                        .background {
                            Capsule()
                                .fill(animateColor.gradient)
                        }
                }
                .vAlign(.bottom)
                .disabled(name == "" || animate)
                .opacity(name == "" ? 0.6 : 1)

            }
            .padding(15)
        }
        .vAlign(.top)
    }
    
    var underline: some View {
        Rectangle()
            .fill(.white.opacity(0.7))
            .frame(height: 0.7)
    }
    
    @ViewBuilder
    func TitleView(_ title: String, color: Color = .white.opacity(0.7)) -> some View {
        Text(title)
            .ubuntu(size: 12)
            .foregroundColor(color)
    }
}

struct TaskPlannerView: View {
    @State private var currentDay = Date()
    @State private var tasks = Task.sampleTasks
    @State private var addNewTask = false
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            TimelineView()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HeaderView()
        }
        .fullScreenCover(isPresented: $addNewTask) {
            AddTaskView { task in
                tasks.append(task)
                addNewTask = false
            }
        }
    }
    @ViewBuilder
    func TimelineView() -> some View {
        ScrollViewReader { proxy in
            let hours = Calendar.current.hours
            let midHour = hours[hours.count / 3]
            VStack {
                let hours = Calendar.current.hours
                ForEach(hours, id: \.self) { hour in
                    TimelineRow(hour).id(hour)
                }
            }
            .onAppear {
                proxy.scrollTo(midHour)
            }
        }
        .padding(.horizontal)
    }
    @ViewBuilder
    func TimelineRow(_ date: Date) -> some View {
        HStack(alignment: .top) {
            Text(date.toString(format: "h a"))
                .ubuntu(size: 14)
                .frame(width: 45, alignment: .leading)
            
            let calendar = Calendar.current
            let filteredTasks = tasks.filter {
                if let hour = calendar.dateComponents([.hour], from: date).hour,
                   let taskHour = calendar.dateComponents([.hour], from: $0.date).hour,
                   hour == taskHour && calendar.isDate($0.date, inSameDayAs: currentDay) {
                    print(hour, taskHour)
                    return true
                }
                return false
            }
            
            if filteredTasks.isEmpty {
                Rectangle()
                    .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, lineCap: .butt, lineJoin: .bevel, dash: [5], dashPhase: 5))
                    .frame(height: 0.5)
                    .offset(y: 10)
            } else {
                VStack {
                    ForEach(filteredTasks) { task in
                        TaskRow(task)
                    }
                }
            }
        }
        .hAlign(.leading)
        .padding(.vertical)
    }
    
    @ViewBuilder
    func TaskRow(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.name.uppercased())
                .ubuntu(size: 16)
                .foregroundColor(task.category.color)
            if !task.description.isEmpty {
                Text(task.description)
                    .ubuntu(size: 14, weight: .light)
            }
        }
        .hAlign(.leading)
        .padding(12)
        .background {
            Rectangle()
                .fill(task.category.color.opacity(0.25))
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(task.category.color)
                .frame(width: 4)
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 6.0) {
                    Text("Today")
                        .ubuntu(size: 30, weight: .light)
                    Text("Welcome, my friend!")
                }
                .hAlign(.leading)
                Button(action: {
                    addNewTask.toggle()
                }) {
                    Label("Add Task", systemImage: "plus")
                        .ubuntu(size: 15)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background {
                            Capsule()
                                .fill(Color.taskBlue.gradient)
                    }
                }
            }
            
            Text(Date().toString(format: "MMM YYYY"))
                .ubuntu(size: 16, weight: .medium)
                .hAlign(.leading)
            
            WeekRow()
        }
        .padding()
        .background(
            VStack(spacing: 0) {
                Color.white
                Rectangle()
                    .fill(.linearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 20)
            }
                .ignoresSafeArea()
        )
    }
    @ViewBuilder
    func WeekRow() -> some View {
        HStack(spacing: 0) {
            ForEach(Calendar.current.currentWeek) { day in
                let status = Calendar.current.isDate(day.date, inSameDayAs: currentDay)
                VStack(spacing: 6) {
                    Text(day.title.prefix(3))
                        .ubuntu(size: 12, weight: .medium)
                    Text(day.date.toString(format: "dd"))
                        .ubuntu(size: 16, weight: status ? .medium : .regular)
                }
                .hAlign(.center)
                .foregroundColor(status ? .taskBlue : .gray)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentDay = day.date
                    }
                }
            }
        }
        .padding(.horizontal, -15)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView()
        AddTaskView { task in }
    }
}

//MARK: View+Extension
enum Ubuntu {
    case light
    case bold
    case medium
    case regular
    
    var weght: Font.Weight {
        switch self {
        case .light: return .light
        case .bold: return .bold
        case .medium: return .medium
        case .regular: return .regular
        }
    }
}

extension View {
    func ubuntu(size: CGFloat, weight: Ubuntu = .regular) -> some View {
        self
            .font(.custom("Ubuntu", size: size))
            .fontWeight(weight.weght)
    }
    
    func hAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
}
//MARK: - Color
extension Color {
    static let taskBlue = Color("Blue")
    static let taskGray = Color("Gray")
    static let taskGreen = Color("Green")
    static let taskPink = Color("Pink")
    static let taskPurple = Color("Purple")
}
//MARK: - Date
extension Date {
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
//MARK: - Calendar
extension Calendar {
    var hours: [Date] {
        let startOfDay = self.startOfDay(for: Date())
        var hours: [Date] = []
        for index in 0..<24 {
            if let date = self.date(byAdding: .hour, value: index, to: startOfDay) {
                hours.append(date)
            }
        }
        return hours
    }
    var currentWeek: [WeekDay] {
        guard let firstWeekDay = self.dateInterval(of: .weekOfMonth, for: Date())?.start else { return [] }
        var week: [WeekDay] = []
        for index in 0..<7 {
            if let day = self.date(byAdding: .day, value: index, to: firstWeekDay) {
                let weekDaySymbol: String = day.toString(format: "EEEE")
                let isToday = self.isDateInToday(day)
                week.append(.init(title: weekDaySymbol, date: day, isToday: isToday))
            }
        }
        return week
    }
    
    struct WeekDay: Identifiable {
        var id = UUID()
        var title: String
        var date: Date
        var isToday = false
    }
}

struct Task: Identifiable {
    var id = UUID()
    var date: Date
    var name: String
    var description: String
    var category: Category
    
    static var sampleTasks: [Task] = [
        .init(date: Date(timeIntervalSince1970: 1673317532), name: "Edit YT Video", description: "", category: .general),
        .init(date: Date(timeIntervalSince1970: 1673319632), name: "Matched Geometry Effect(Issue)", description: "", category: .bug),
        .init(date: Date(timeIntervalSince1970: 1673326832), name: "Multi-ScrollView", description: "", category: .challenge),
        .init(date: Date(timeIntervalSince1970: 1673330432), name: "Loreal Ipsum", description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.", category: .idea),
        .init(date: Date(timeIntervalSince1970: 11673334032), name: "Complete UI Animation Challenge", description: "", category: .challenge),
        .init(date: Date(timeIntervalSince1970: 11673334032), name: "Fix Shadow issue on Mockup's", description: "", category: .bug),
        .init(date: Date(timeIntervalSince1970: 11673334032), name: "Add Shadow Effect in Mockview App", description: "", category: .idea),
        .init(date: Date(timeIntervalSince1970: 1673319632), name: "Twitter/Instagram Post", description: "", category: .general),
        .init(date: Date(timeIntervalSince1970: 1672923409), name: "Lorem Ipsum", description: "", category: .modifiers),
    ]

}

enum Category: String, CaseIterable {
    case general = "General"
    case bug = "Bug"
    case idea = "Idea"
    case modifiers = "Modifiers"
    case challenge = "Challenge"
    case coding = "Coding"
    
    var color: Color {
        switch self {
        case .general: return .taskGray
        case .bug: return .taskGreen
        case .idea: return .taskPink
        case .modifiers: return .taskBlue
        case .challenge: return .taskPurple
        case .coding: return .brown
        }
    }
}


