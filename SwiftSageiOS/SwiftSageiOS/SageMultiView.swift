//
//  SageWebView.swift
//  SwiftSageiOS
//
//  Created by Chris Dillard on 4/26/23.
//
#if !os(macOS)

import Foundation
import SwiftUI
import UIKit
import WebKit
enum ViewMode {
    case webView
    case editor
}
struct SageMultiView: View {

    public var webViewURL = URL(string: "https://chat.openai.com")!
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State var viewMode: ViewMode

    @EnvironmentObject var sageMultiViewModel: SageMultiViewModel


//    @State private var position: CGSize = CGSize.zero
    @State private var frame: CGRect = defSize
//    @State private var zoomScale: CGFloat = 1.0
//    @State private var isPinching: Bool = false

    @StateObject private var pinchHandler = PinchGestureHandler()
    @State var sourceEditorCode = """
    """

    var body: some View {
        ZStack {

            if viewMode == .editor { //&& settingsViewModel.isEditorVisible {

#if !os(macOS)
                VStack {
                    let viewModel = SourceCodeTextEditorViewModel()

                    SourceCodeTextEditor(text: $sageMultiViewModel.sourceCode, isEditing: $sageMultiViewModel.isEditing)
                        .ignoresSafeArea()
                        .modifier(ResizableViewModifier(frame: $frame, zoomScale: $pinchHandler.scale))
                        .environmentObject(viewModel)
//                        .scaleEffect(currentScale)
//                        .gesture(
//                            MagnificationGesture()
//                                .onChanged { scaleValue in
//                                    // Update the current scale based on the gesture's scale value
//                                    currentScale = lastScaleValue * scaleValue
//                                }
//                                .onEnded { scaleValue in
//                                    // Save the scale value when the gesture ends
//                                    lastScaleValue = currentScale
//                                }
//                        )
                }

#endif
            }
            else {
                let viewModel = WebViewViewModel()
                WebView(url:webViewURL, isPinching: $pinchHandler.isPinching)
                    .ignoresSafeArea()
                    .modifier(ResizableViewModifier(frame: $frame, zoomScale: $pinchHandler.scale))
                    .environmentObject(viewModel)
            }
        }
    }
   
}

class SourceCodeTextEditorViewModel: ObservableObject {
}
class WebViewViewModel: ObservableObject {
}

class PinchGestureHandler: ObservableObject {
    @Published var scale: CGFloat = 1.0
    var contentSize: CGSize = .zero
    var onContentSizeChange: ((CGSize) -> Void)?
    var isPinching: Bool = false
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isPinching: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    var webViewInstance: WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: self.url)

//        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36"
//        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        webView.load(request)
        return webView
    }

    func makeUIView(context: Context) -> WKWebView {
        return webViewInstance
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.scrollView.isScrollEnabled = !isPinching
    }


    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}

struct HandleView: View {
    var body: some View {
        Circle()
            .frame(width: SettingsViewModel.shared.middleHandleSize, height: SettingsViewModel.shared.middleHandleSize)
            .foregroundColor(Color.white.opacity(0.666))
    }
}
#endif

#if !os(macOS)

struct ResizableViewModifier: ViewModifier {
    @Binding var frame: CGRect
    @Binding var zoomScale: CGFloat

    var handleSize: CGFloat = SettingsViewModel.shared.cornerHandleSize

    func body(content: Content) -> some View {
        content
            .frame(width: frame.width, height: frame.height)
            .overlay(ResizingHandle(position: .topLeading, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
            .overlay(ResizingHandle(position: .topTrailing, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
            .overlay(ResizingHandle(position: .bottomLeading, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
            .overlay(ResizingHandle(position: .bottomTrailing, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
    }
}


struct ResizingHandle: View {
    enum Position {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    var position: Position
    @Binding var frame: CGRect
    var handleSize: CGFloat
    @State private var translation: CGSize = .zero
    @Binding var zoomScale: CGFloat

    var body: some View {
        Circle()
            .fill(SettingsViewModel.shared.buttonColor)
            .frame(width: handleSize, height: handleSize)
            .position(positionPoint(for: position))
            .opacity(0.666)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        translation = value.translation
                    }
                    .onEnded { _ in
                        updateFrame(with: translation)
                        translation = .zero
                    }
            )
    }

    private func positionPoint(for position: Position) -> CGPoint {
        switch position {
        case .topLeading:
            return CGPoint(x: frame.minX + translation.width / 2, y: frame.minY + translation.height / 2)
        case .topTrailing:
            return CGPoint(x: frame.maxX + translation.width / 2, y: frame.minY + translation.height / 2)
        case .bottomLeading:
            return CGPoint(x: frame.minX + translation.width / 2, y: frame.maxY + translation.height / 2)
        case .bottomTrailing:
            return CGPoint(x: frame.maxX + translation.width / 2, y: frame.maxY + translation.height / 2)
        }
    }

    private func updateFrame(with translation: CGSize) {
        let newWidth: CGFloat
        let newHeight: CGFloat

        switch position {
        case .topLeading:
            newWidth = frame.width - translation.width
            newHeight = frame.height - translation.height
        case .topTrailing:
            newWidth = frame.width + translation.width
            newHeight = frame.height - translation.height
        case .bottomLeading:
            newWidth = frame.width - translation.width
            newHeight = frame.height + translation.height
        case .bottomTrailing:
            newWidth = frame.width + translation.width
            newHeight = frame.height + translation.height
        }

        // Set minimum size constraints to avoid negative size values
        frame.size.width = newWidth
        frame.size.height = newHeight

//        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width , height: frame.size.height )

    }
}


class SageMultiViewModel: ObservableObject {
    @Published var windowInfo: WindowInfo
    @Published var sourceCode: String
    @Published var isEditing: Bool

    init(windowInfo: WindowInfo, isEditing: Bool) {
        self.windowInfo = windowInfo
        self.sourceCode = windowInfo.fileContents
        self.isEditing = isEditing
    }
}


#endif
//struct ZoomableScrollView: UIViewRepresentable {
//    //@Binding var zoomScale: CGFloat
//    let contentView: UIView
//    @ObservedObject var pinchHandler: PinchGestureHandler
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIView(context: Context) -> UIScrollView {
//        let scrollView = UIScrollView()
//        scrollView.delegate = context.coordinator
//        scrollView.minimumZoomScale = 0.75
//        scrollView.maximumZoomScale = 4.0
//        scrollView.addSubview(contentView)
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
//        ])
//        return scrollView
//    }
//
//    func updateUIView(_ uiView: UIScrollView, context: Context) {
//        uiView.setZoomScale(pinchHandler.scale, animated: false)
//
//    }
//
//    class Coordinator: NSObject, UIScrollViewDelegate {
//        var parent: ZoomableScrollView
//
//        init(_ parent: ZoomableScrollView) {
//            self.parent = parent
//        }
//
//        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//            return parent.contentView
//        }
//
//        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//            parent.pinchHandler.scale = scale
//            let newSize = CGSize(width: view?.frame.width ?? 0, height: view?.frame.height ?? 0)
//            parent.pinchHandler.contentSize = newSize
//            parent.pinchHandler.onContentSizeChange?(newSize)
//        }
//    }
//}

//struct WebView: UIViewRepresentable {

//    let url: URL

 //   func makeUIView(context: Context) -> WKWebView {
  //      let webView = WKWebView()
   //     webView.load(URLRequest(url: url))
 //       return webView
 //   }

//    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update the UIView (WKWebView) as needed
//    }
//}
