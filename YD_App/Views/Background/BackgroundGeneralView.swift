//
//  BackgroundGeneral.swift
//  YD_App
//
//  Created by Luis Melendez on 20/05/25.
//

// BackgroundView.swift
import SwiftUI

struct BackgroundGeneralView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ScratchedMetalBackground()
            content
        }
    }
}

struct ScratchedMetalBackground: View {
    var body: some View {
        ZStack {
            // Base: acero quemado/mate con tonos fríos
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.02, green: 0.02, blue: 0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Capa de rayones random
            ScratchesOverlayView()
        }
    }
}

struct ScratchesOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for _ in 0..<600 { // ← DOBLE de rayones
                    let startX = CGFloat.random(in: 0...size.width)
                    let startY = CGFloat.random(in: 0...size.height)
                    let length = CGFloat.random(in: 40...180) // ← Más largos
                    let angle = Angle(degrees: Double.random(in: -80...80)).radians

                    let endX = startX + cos(angle) * length
                    let endY = startY + sin(angle) * length

                    var path = Path()
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))

                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(Double.random(in: 0.05...0.05))), // ← Más opacos visibles
                        lineWidth: CGFloat.random(in: 0.6...1.2) // ← Más gruesos
                    )
                }
            }
            .blendMode(.overlay)
            .blur(radius: 0.2) // ← Menos blur para que se noten más
            .ignoresSafeArea()
        }
    }
}
