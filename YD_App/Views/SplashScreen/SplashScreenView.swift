//
//  SplashScreenView.swift
//  YD_App
//
//  Created by Luis Melendez on 01/05/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scaleEffect: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                Image("SplashImage") // Imagen centrada
                    .resizable()
                    .scaledToFit()
                    .frame(width: 500, height: 500) // Ajuste de tamaño
                    .scaleEffect(scaleEffect)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.scaleEffect = 1.0
                            self.opacity = 1.0
                        }
                    }

                Spacer()

                Image("ImagenFooterYD") // Footer más pequeño y abajo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150) // Más pequeño
                    .scaleEffect(scaleEffect)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.scaleEffect = 1.0
                            self.opacity = 1.0
                        }
                    }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
            .previewDevice("iPhone 15 Pro")
    }
}
