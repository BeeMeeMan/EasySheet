//
//  EasySheetScreenCover.swift
//  EasySheet
//
//  Created by Yevhenii Korsun on 22.12.2022.
//

import SwiftUI

// MARK: - SheetDetends

enum SheetDetends {
    case small
    case medium
    case large
    case fraction(Double)
    
    var value: Double {
        switch self {
        case .small: return 0.2
        case .medium: return 0.55
        case .large: return 0.93
        case .fraction(let value): return value
        }
    }
}

// MARK: - EasyDismiss

struct EasyDismiss {
    private var action: () -> Void
    public func callAsFunction() {
        action()
    }
    
    init(action: @escaping () -> Void = { }) {
        self.action = action
    }
}

struct EasyDismissKey: EnvironmentKey {
    public static var defaultValue: EasyDismiss = EasyDismiss()
}

extension EnvironmentValues {
    var easyDismiss: EasyDismiss {
        get { self[EasyDismissKey.self] }
        set { self[EasyDismissKey.self] = newValue }
    }
}

// MARK: - RoundedCorner

fileprivate extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

fileprivate struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - EasySheetScreenCover

private struct EasySheetScreenCover<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var scaleFactor: CGFloat
    var detends: [SheetDetends]
    var dismissible: Bool
    var grabberColor: Color?
    var backgroundColor: Color

    @State private var offset: CGFloat = .zero
    @State private var lastOffset: CGFloat = .zero
    @GestureState private var gestureOffset: CGFloat = .zero
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy -> AnyView in
            let height = proxy.frame(in: .global).height
            let detendsOffsets = detends.map{ -($0.value * height) }
            let lowestHeigth = detendsOffsets.max() ?? (height * SheetDetends.small.value)

            return AnyView (
                ZStack {
                    backgroundColor

                    VStack {
                        if let color = grabberColor {
                            Capsule()
                                .fill(color)
                                .frame(width: 60, height: 4)
                                .padding(.top)
                        }

                        content
                            .environment(\.easyDismiss, EasyDismiss {
                                close()
                            })
                    }
                }
                    .frame(height: -offset, alignment: .top)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .background {
                        GeometryReader { smallProxy -> Color in
                            let minY = smallProxy.frame(in: .global).minY
                            
                            DispatchQueue.main.async {
                                withAnimation {
                                    let startingHeight = height * (1 - SheetDetends.medium.value)
                                    let maxPadding = (height * (1 - SheetDetends.large.value))
                                    if minY > 0 && minY < startingHeight {
                                        let padding = (maxPadding - 8) * (startingHeight - minY) / startingHeight
                                        scaleFactor = 1 - (padding / height)
                                    } else {
                                        scaleFactor = 1
                                    }
                                }
                            }
                            return Color.clear
                        }
                    }
                    .offset(y: height)
                    .offset(y: offset)
                    .onAppear {
                        withAnimation {
                            offset = detendsOffsets.first ?? SheetDetends.large.value
                            lastOffset = offset
                        }
                    }
                    .gesture(DragGesture().updating($gestureOffset, body: { value, out, _ in
                        out = value.translation.height
                        onChange(change: -(height * 0.9))
                    }).onEnded({ _ in
                        withAnimation {
                            if offset > lowestHeigth / 2 && dismissible { close() }
                            offset = (closestMatch(values: detendsOffsets, inputValue: offset) ?? 0)
                        }
                        lastOffset = offset
                    }))
            )
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private func onChange(change: CGFloat) {
        DispatchQueue.main.async {
            let newOffset = gestureOffset + lastOffset
            if newOffset < (change - 40) {
                withAnimation {
                    self.offset = change
                }
            } else {
                self.offset = newOffset
            }
        }
    }

    private func closestMatch(values: [Double], inputValue: Double) -> Double? {
        var closest: Double?

        values.forEach { value in
            if closest == nil {
                closest = value
            } else if let closestUnwraped = closest {
                if abs(closestUnwraped - inputValue) > abs(value - inputValue) {
                    closest = value
                }
            }
        }

        return closest
    }

    private func close() {
        DispatchQueue.main.async {
            withAnimation {
                offset = 0
                scaleFactor = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - EasySheetContainer

private struct EasySheetContainer<Content: View, BackgroundContent: View>: View {
    @State private var scaleFactor: CGFloat = 1
    @Binding var isPresented: Bool
    var detends: [SheetDetends]
    var dismissible: Bool
    var grabberColor: Color?
    var backgroundColor: Color
    @ViewBuilder var content: Content
    @ViewBuilder var backgroundContent: BackgroundContent

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
            Color.clear.preferredColorScheme(scaleFactor > 0.99 ? nil : .dark)

            backgroundContent
                .overlay {
                    if scaleFactor < 0.99 {
                        Color.white.opacity(0.1)
                    }
                }
                .mask(RoundedRectangle(cornerRadius: scaleFactor < 1 ? 12 : 0).fill(Color.black))
                .scaleEffect(scaleFactor, anchor: .bottom)

            if isPresented {
                EasySheetScreenCover(isPresented: $isPresented, scaleFactor: $scaleFactor, detends: detends, dismissible: dismissible, grabberColor: grabberColor, backgroundColor: backgroundColor) {
                    content
                }
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func easySheet<Content>(isPresented: Binding<Bool>, detends: [SheetDetends] = [.large], dismissible: Bool = true, grabberColor: Color? = nil, backgroundColor: Color = .white, content: @escaping () -> Content) -> some View where Content : View {
        EasySheetContainer(isPresented: isPresented, detends: detends, dismissible: dismissible, grabberColor: grabberColor, backgroundColor: backgroundColor) {
            content()
        } backgroundContent: {
            self
        }
    }
}

struct ContentView1_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
