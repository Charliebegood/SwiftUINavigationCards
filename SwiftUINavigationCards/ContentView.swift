import SwiftUI

struct LeftPage: View {
    var body: some View {
        ZStack() {
            Rectangle()
                .foregroundColor(Color.blue)
            Text("Left")
        }
    }
}

struct RightPage: View {
    var body: some View {
        ZStack() {
            Rectangle()
                .foregroundColor(Color.red)
            Text("Right")
        }
    }
}

struct CenterPage: View {
    var body: some View {
        ZStack() {
            Rectangle()
                .foregroundColor(Color.white)
            Text("Center")
        }
    }
}

enum DragDirection {
    case none, left, right
}

enum ViewState {
    case hidden, visible
}

struct ViewPositions {
    var left = ViewPosition.getViewStartOffset(.left)
    var center = ViewPosition.getViewStartOffset(.center)
    var right = ViewPosition.getViewStartOffset(.right)
}

struct ViewStates {
    var left: ViewState = .hidden
    var center: ViewState = .visible
    var right: ViewState = .hidden
}

enum ViewPosition {
    case left, center, right
    
    static func getViewStartOffset(_ position: ViewPosition) -> CGFloat {
        switch position {
        case .left:
            return -UIScreen.main.bounds.width
        case .center:
            return 0
        case .right:
            return UIScreen.main.bounds.width
        }
    }

    static func getViewEndOffset(_ position: ViewPosition) -> CGFloat {
        switch position {
        case .left:
            return 0
        case .center:
            return 0
        case .right:
            return 0
        }
    }
}

struct ContentView: View {
    @State var positions: ViewPositions = ViewPositions()
    @State var states: ViewStates = ViewStates()
    @State var position: ViewPosition = .center
    @State var animating: Bool = false
    @State var shadow: Double = 0
    @State var scale: CGFloat = 1
    @State var initalDirection: DragDirection = .none

    var animation: Animation {
        Animation.interpolatingSpring(mass: 0.9, stiffness: 400.0, damping: 50.0, initialVelocity: 10.0)
    }
    
    var timer: Timer? {
        return Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
            timer.invalidate()
            if (self.positions.left == ViewPosition.getViewStartOffset(.left)) {
                self.states.left = .hidden
            }
            if (self.positions.right == ViewPosition.getViewStartOffset(.right)) {
                self.states.right = .hidden
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack() {
                ZStack() {
                    CenterPage()
                        .cornerRadius(40)
                        .frame(width: geometry.size.width)
                        .scaleEffect(self.scale)
                        .animation(self.animating ? Animation.easeOut(duration: 0.3) : nil)
                    Rectangle().foregroundColor(Color.black)
                        .frame(width: geometry.size.width)
                        .opacity(self.shadow)
                        .animation(self.animating ? Animation.easeOut(duration: 0.5) : nil)
                }
                if (self.states.left == .visible) {
                    LeftPage()
                        .cornerRadius(40)
                        .frame(width: geometry.size.width)
                        .offset(x: self.positions.left)
                        .animation(self.animating ? self.animation : nil)
                }
                if (self.states.right == .visible) {
                    RightPage()
                        .cornerRadius(40)
                        .frame(width: geometry.size.width)
                        .offset(x: self.positions.right)
                        .animation(self.animating ? self.animation : nil)
                }
            }
            .gesture(DragGesture()
                .onChanged { value in
                    self.updateOffset(value: value)
                }
                .onEnded { value in
                    self.calculateFinalPositions(value: value)
                }
            )
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    func updateOffset(value: DragGesture.Value) {
        var offset = CGPoint(x: value.translation.width, y: value.translation.height)
        let direction: DragDirection = offset.x < 0 ? .left : .right

        self.animating = false
        if (self.initalDirection == .none) {
            self.initalDirection = direction
            if (self.position == .center && direction == .right) {
                self.states.left = .visible
            } else if (self.position == .center && direction == .left) {
                self.states.right = .visible
            }
        }
        if (self.position == .left) {
            let transformation = (UIScreen.main.bounds.width - abs(self.positions.left)) / UIScreen.main.bounds.width
            self.positions.left = min(0, offset.x)
            self.shadow = Double(transformation)
            self.scale = 1 - transformation / 8
        } else if (self.position == .right) {
            let transformation = 1 - self.positions.right / UIScreen.main.bounds.width
            self.shadow = Double(transformation)
            self.positions.right = max(0, offset.x)
            self.scale = 1 - transformation / 8
        } else if (self.initalDirection == .left) {
            if (direction == .right) {
                offset.x = min(0, offset.x)
            }
            self.positions.right = ViewPosition.getViewStartOffset(.right) + offset.x
            let transformation = 1 - self.positions.right / UIScreen.main.bounds.width
            self.shadow = min(1, Double(transformation))
            self.scale = 1 - ((1 - self.positions.right / UIScreen.main.bounds.width) / 8)
        } else if (self.initalDirection == .right) {
            if (direction == .left) {
                offset.x = max(0, offset.x)
            }
            self.positions.left = ViewPosition.getViewStartOffset(.left) + offset.x
            let transformation = (UIScreen.main.bounds.width - abs(self.positions.left)) / UIScreen.main.bounds.width
            self.shadow = min(1, Double(transformation))
            self.scale = 1 - (((UIScreen.main.bounds.width - abs(self.positions.left)) / UIScreen.main.bounds.width) / 8)
        }
    }
    
    func calculateFinalPositions(value: DragGesture.Value) {
        let offset = CGPoint(x: value.translation.width, y: value.translation.height)
        let prediction = value.predictedEndLocation

        if (self.position == .left && initalDirection == .left) {
            if (prediction.x <= ViewPosition.getViewStartOffset(.left) / 2 || offset.x <= ViewPosition.getViewStartOffset(.left) / 2) {
                self.changePosition(newPosition: .center, animate: false)
            } else {
                self.setPosition(position: .left, start: false)
            }
        } else if (self.position == .right && initalDirection == .right) {
            if (prediction.x >= ViewPosition.getViewStartOffset(.right) / 2 || offset.x >= ViewPosition.getViewStartOffset(.right) / 2) {
                self.changePosition(newPosition: .center, animate: false)
            } else {
                self.setPosition(position: .right, start: false)
            }
        } else {
            if (self.initalDirection == .right) {
                if (prediction.x >= ViewPosition.getViewStartOffset(.right) / 2 || offset.x >= ViewPosition.getViewStartOffset(.right) / 2) {
                    self.changePosition(newPosition: .left, animate: false)
                } else {
                    self.setPosition(position: .left, start: true)
                }
            } else if (self.initalDirection == .left){
                if (prediction.x <= ViewPosition.getViewStartOffset(.left) / 2 || offset.x <= ViewPosition.getViewStartOffset(.left) / 2) {
                    self.changePosition(newPosition: .right, animate: false)
                } else {
                    self.setPosition(position: .right, start: true)
                }
            }
        }
        self.initalDirection = .none
        _ = self.timer
        self.animating = true
    }
    
    func setPosition(position: ViewPosition, start: Bool) {
        if (position == .left) {
            self.positions.left = start ? ViewPosition.getViewStartOffset(position) : ViewPosition.getViewEndOffset(position)
            self.states.left = start ? self.states.left : .visible
        } else {
            self.positions.right = start ? ViewPosition.getViewStartOffset(position) : ViewPosition.getViewEndOffset(position)
            self.states.right = start ? self.states.right : .visible
        }
        if (start) {
            self.shadow = 0
            self.scale = 1
        } else {
            self.shadow = 1
            self.scale = 0.8
        }
    }
    
    func changePosition(newPosition: ViewPosition, animate: Bool) {
        if (self.position == newPosition) {
            return
        }
        if (self.position == .center) {
            self.setPosition(position: newPosition, start: false)
        } else if (self.position == .left && newPosition == .center) {
            self.setPosition(position: .left, start: true)
        } else if (self.position == .right && newPosition == .center) {
            self.setPosition(position: .right, start: true)
        }
        self.position = newPosition
        if (animate) {
            _ = self.timer
            self.animating = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
