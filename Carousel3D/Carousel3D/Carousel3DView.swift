import SwiftUI

struct Carousel3DView: View {
    @State private var cards: [Card] = []
    
    var body: some View {
        
        VStack(spacing: 100.0) {
            Carousel3D(cardSize: CGSize(width: Card.width, height: Card.height), items: cards, id: \.id, content: {
                CardView(card: $0)
            })
            
            HStack{
                addButton
                deleteButton
            }
        }
        .onAppear {
            for index in 1...7 {
                cards.append(.init(image: "pict\(index)"))
            }
        }
    }
    var addButton: some View {
        Button {
            if cards.count != 7 {
                cards.append(.init(image: "pict\(cards.count + 1)"))
            }
        } label: {
            Label("Add", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        .disabled(cards.count == 7)
    }
    var deleteButton: some View {
        Button {
            if !cards.isEmpty{
                cards.removeLast()
            }
        } label: {
            Label("Delete", systemImage: "xmark")
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .disabled(cards.isEmpty)
    }
}

struct CardView: View {
    var card: Card
    
    var body: some View {
        ZStack {
            Image(card.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(width: Card.width, height: Card.height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct Carousel3D<Content: View, ID, Item>: View where
Item: RandomAccessCollection,
Item.Element: Identifiable,
Item.Element: Equatable,
ID: Hashable {
    var cardSize: CGSize
    var items: Item
    var id: KeyPath<Item.Element, ID>
    var content: (Item.Element) -> Content
    
    var hostingViews: [UIView] = []
    
    @State var offset = 0.0
    @State var lastStoredOffset = 0.0
    @State var animationDuration = 0.0
    
    init(cardSize: CGSize, items: Item, id: KeyPath<Item.Element, ID>, @ViewBuilder content: @escaping (Item.Element) -> Content) {
        self.cardSize = cardSize
        self.items = items
        self.id = id
        self.content = content
        
        for item in items {
            let hostingView = convertToUIView(item: item).view!
            hostingViews.append(hostingView)
        }
    }
    
    var body: some View {
        CarouselHelper(views: hostingViews, cardSize: cardSize, offset: offset, animationDuration: animationDuration)
            .frame(width: cardSize.width, height: cardSize.height)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        animationDuration = 0
                        // MARK: Slowing Down
                        offset = (value.translation.width * 0.35) + lastStoredOffset
                    }).onEnded({ value in
                        guard items.count > 0 else{
                            lastStoredOffset = offset
                            return
                        }
                        
                        animationDuration = 0.2
                        let anglePerCard = 360.0 / CGFloat(items.count)
                        offset = CGFloat(Int((offset / anglePerCard).rounded())) * anglePerCard
                        lastStoredOffset = offset
                    })
            )
            .onChange(of: items.count) { newValue in
                guard newValue > 0 else{return}
                // MARK: Animating When Item is Removed or Inserted
                animationDuration = 0.2
                let anglePerCard = 360.0 / CGFloat(newValue)
                offset = CGFloat(Int((offset / anglePerCard).rounded())) * anglePerCard
                lastStoredOffset = offset
            }
    }
    
    func convertToUIView(item: Item.Element)->UIHostingController<Content>{
        let hostingView = UIHostingController(rootView: content(item))
        hostingView.view.frame.origin = .init(x: cardSize.width / 2, y: cardSize.height / 2)
        hostingView.view.backgroundColor = .clear
        
        return hostingView
    }
}

struct Card: Identifiable, Equatable {
    var id = UUID().uuidString
    var image: String
    static let width = 150.0
    static let height = 220.0
}

struct CarouselHelper: UIViewRepresentable {
    var views: [UIView]
    var cardSize: CGSize
    var offset: CGFloat
    var animationDuration: CGFloat
    
    func makeUIView(context: Context) -> UIView {
        UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let circleAngle = 360.0 / CGFloat(views.count)
        var angle: CGFloat = offset
        
        if uiView.subviews.count > views.count{
            uiView.subviews[uiView.subviews.count - 1].removeFromSuperview()
        }
        
        for (view,index) in zip(views, views.indices){
            if uiView.subviews.indices.contains(index){
                apply3DTransform(view: uiView.subviews[index], angle: angle)
                let completeRotation = CGFloat(Int(angle / 360)) * 360.0
                    uiView.subviews[index].isUserInteractionEnabled = (angle - completeRotation) == 0
                angle += circleAngle
            } else {
                let hostView = view
                hostView.frame = .init(origin: .zero, size: cardSize)
                
                uiView.addSubview(hostView)
                
                apply3DTransform(view: uiView.subviews[index], angle: angle)
                angle += circleAngle
            }
        }
    }
    
    func apply3DTransform(view: UIView,angle: CGFloat){
        var transform3D = CATransform3DIdentity
        transform3D.m34 = -1 / 500
        transform3D = CATransform3DRotate(transform3D, degToRad(deg: angle), 0, 1, 0)
        transform3D = CATransform3DTranslate(transform3D, 0, 0, cardSize.width)
        
        UIView.animate(withDuration: animationDuration) {
            view.transform3D = transform3D
        }
    }
}

func degToRad(deg: CGFloat) -> CGFloat{
    return (deg * .pi) / 180
}

struct Carousel3DView_Previews: PreviewProvider {
    static var previews: some View {
        Carousel3DView()
    }
}
