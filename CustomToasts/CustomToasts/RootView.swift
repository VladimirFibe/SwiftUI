import SwiftUI

struct RootView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var overlayWindow: UIWindow?
    var body: some View {
        content
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   overlayWindow == nil {
                    let window = PassthroughWindow(windowScene: windowScene)
                    let rootController = UIHostingController(rootView: ToastGroup())
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    window.backgroundColor = .clear
                    window.rootViewController = rootController
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    overlayWindow = window
                }
            }
    }
}

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil}
        return rootViewController?.view == view ? nil : view
    }
}

@Observable class Toast {
    static let shared = Toast()
    fileprivate var toasts: [ToastItem] = []

    func present(
        title: String,
        symbol: String?,
        tint: Color = .primary,
        isUserInteractionEnable: Bool = false,
        timing: ToastTime = .medium
    ) {
        withAnimation(.snappy) {
            toasts.append(.init(
                title: title,
                symbol: symbol,
                tint: tint,
                isUserInteractionEnable: isUserInteractionEnable,
                timing: timing
            ))
        }
    }
}

struct ToastItem: Identifiable {
    let id: UUID = .init()
    var title: String
    var symbol: String?
    var tint: Color
    var isUserInteractionEnable: Bool
    var timing: ToastTime = .medium
}

enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.5
}

fileprivate struct ToastGroup: View {
    var model = Toast.shared
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeAreas = $0.safeAreaInsets
            ZStack {
                ForEach(model.toasts) { item in
                    ToastView(size: size, item: item)
                        .scaleEffect(scale(item))
                        .offset(y: offsetY(item))
                }
            }
            .padding(.bottom, safeAreas.top == .zero ? 15 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    func offsetY(_ item: ToastItem) -> CGFloat {
        guard let index = model.toasts.firstIndex(where: { $0.id == item.id }) else { return 0}
        let number = CGFloat(model.toasts.count - 1 - index)
        return number >= 2 ? -20 : -10 * number
    }

    func scale(_ item: ToastItem) -> CGFloat {
        guard let index = model.toasts.firstIndex(where: { $0.id == item.id }) else { return 1}
        let number = CGFloat(model.toasts.count - 1 - index)
        return 1 - (number >= 2 ? 0.2 : 0.1 * number)
    }
}

fileprivate struct ToastView: View {
    var size: CGSize
    var item: ToastItem
    var body: some View {
        HStack(spacing: 10) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.title3)
            }
            Text(item.title).lineLimit(1)
        }
        .foregroundStyle(item.tint)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            .background
                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
            in: .capsule
        )
        .contentShape(.capsule)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    guard item.isUserInteractionEnable else { return }
                    let endY = value.translation.height
                    let velocityY = value.velocity.height
                    if (endY + velocityY) > 100 {
                        removeToast()
                    }
                }
        )
        .frame(maxWidth: size.width * 0.7)
        .transition(.offset(y: 150))
    }

    func removeToast() {
        withAnimation(.snappy) {
            Toast.shared.toasts.removeAll(where: { $0.id == item.id })
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
