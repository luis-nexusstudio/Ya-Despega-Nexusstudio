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
        GeometryReader { geometry in
            BackgroundGeneralView {
                ZStack {
                    VStack(spacing: 20) {
                        Spacer()

                        // 🔺 Imagen "Él viene" aún más grande
                        Image("SplashImage")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geometry.size.width * 0.95,
                                height: geometry.size.height * 0.65
                            )
                            .scaleEffect(scaleEffect)
                            .opacity(opacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 1.2)) {
                                    self.scaleEffect = 1.0
                                    self.opacity = 1.0
                                }
                            }

                        Spacer()

                        Image("ImagenFooterYD")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geometry.size.width * 0.25,
                                height: geometry.size.height * 0.12
                            )
                            .scaleEffect(scaleEffect)
                            .opacity(opacity)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
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
    }
}


struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
            .previewDevice("iPhone 15 Pro")
    }
}
