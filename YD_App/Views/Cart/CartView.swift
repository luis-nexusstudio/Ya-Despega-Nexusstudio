//
//  CartView.swift
//  YD_App
//
//  Estructura final con manejo de errores consistente con HomeView y MyTicketsView
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @Binding var selectedTab: Int

    @State private var lastOrder: Order?
    @State private var showThankYou = false

    var totalTickets: Int {
        cartViewModel.totalTickets(for: eventViewModel.eventDetails)
    }

    var hasTicketsInCart: Bool {
        totalTickets > 0
    }

    var body: some View {
        BackgroundGeneralView {
            if eventViewModel.isLoading {
                loadingView
            } else if let appError = eventViewModel.currentAppError ?? cartViewModel.currentAppError {
                StandardErrorView(
                    error: appError,
                    isRetrying: eventViewModel.isRetrying,
                    onRetry: {
                        print("🔁 [CartView] Retry tapped - Error: \(appError.errorCode)")
                                    
                        // 🔐 SI ES ERROR DE EMAIL → Solo limpiar el error, NO recargar evento
                        if appError.errorCode == "CHE_012" {
                            print("📧 [CartView] Email verification completed - clearing error only")
                            cartViewModel.currentAppError = nil
                        } else {
                            // ✅ OTROS ERRORES → Sí hacer retry del evento
                            print("🔄 [CartView] Network/Data error - retrying event load")
                            eventViewModel.retryLoad()
                            cartViewModel.currentAppError = nil
                        }
                    }
                )

            } else if !hasTicketsInCart {
                emptyStateView
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Resumen de compra")
                                .font(.title.bold())
                                .padding(.bottom, 10)
                                .foregroundColor(Color("PrimaryColor"))

                            Divider()

                            ForEach(ticketSections, id: \.type) { section in
                                EditableOrderSection(
                                    image: section.type == "GENERAL"
                                        ? Image(systemName: "person.fill")
                                        : Image(systemName: "star.fill"),
                                    title: section.type,
                                    date: eventViewModel.eventDetails?.fecha_inicio.date.formatDateRange(to: eventViewModel.eventDetails?.fecha_fin.date ?? Date()) ?? "",
                                    location: eventViewModel.eventDetails?.ubicacionNombre ?? "",
                                    count: section.binding
                                )
                            }

                            if let details = eventViewModel.eventDetails {
                                DetailsView(details: details)
                            }

                            OrderSummaryView(
                                selectedTab: $selectedTab,
                                lastOrder: $lastOrder,
                                showThankYou: $showThankYou
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                    }
                }
            }
            
            // 🔧 MOVER EL POPUP FUERA DEL ZSTACK CONDICIONAL
            // Ahora el popup se renderiza independientemente del estado del carrito
            if showThankYou, let order = lastOrder {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .zIndex(1000) // Asegurar que esté por encima de todo
                    .overlay(
                        ConfirmationPopup(order: order) {
                            print("🔄 [CartView] Cerrando popup y navegando a tickets")
                            selectedTab = 2
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showThankYou = false
                                    lastOrder = nil // 🆕 Limpiar la orden también
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showThankYou)
                    )
            }
        }
        // 🔧 AGREGAR DEBUGGING PARA EL ESTADO DEL POPUP
        .onChange(of: showThankYou) { newValue in
            print("🎭 [CartView] showThankYou cambió a: \(newValue)")
            if newValue {
                print("🎭 [CartView] lastOrder: \(lastOrder?.id ?? "nil")")
            }
        }
        .onChange(of: lastOrder) { newOrder in
            print("🎭 [CartView] lastOrder cambió a: \(newOrder?.id ?? "nil")")
        }
    }

    private var ticketSections: [(type: String, binding: Binding<Int>)] {
        guard let details = eventViewModel.eventDetails else { return [] }
        return details.tickets.compactMap { ticket in
            let binding = Binding(
                get: { cartViewModel.ticketCounts[ticket.id] ?? 0 },
                set: { cartViewModel.ticketCounts[ticket.id] = $0 }
            )
            return (ticket.descripcion.uppercased(), binding)
        }
    }

    private var loadingView: some View {
        StandardLoadingView(message: "Cargando información del evento")
    }
    
    private var emptyStateView: some View {
        StandardEmptyStateView(
            title: "Tu carrito está vacío",
            message: "¡Agrega boletos para comenzar!",
            icon: "cart.badge.minus"
        )
    }
}

struct EditableOrderSection: View {
    let image: Image
    let title: String
    let date: String
    let location: String
    @Binding var count: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)

            HStack(alignment: .top, spacing: 15) {
                image
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.headline)
                    Text(date.capitalized).font(.subheadline).foregroundColor(.secondary)
                    Text(location).font(.subheadline).foregroundColor(.secondary)

                    HStack {
                        Button(action: { if count > 0 { count -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(count > 0 ? .red : .gray)
                        }
                        .disabled(count == 0)

                        Text("\(count)")
                            .frame(minWidth: 30)
                            .font(.body.monospacedDigit())

                        Button(action: { count += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(height: 200)
    }
}

struct DetailsView: View {
    let details: EventDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(details.detalles)
                .font(.subheadline)
                .foregroundColor(.gray)

            ForEach(details.terminos, id: \.self) { term in
                HStack(alignment: .top, spacing: 5) {
                    Text("•").foregroundColor(.gray)
                    Text(term).foregroundColor(.gray)
                }
            }
        }
    }
}

struct OrderSummaryView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @State private var isExpanded = true
    @Binding var selectedTab: Int
    @State private var showRedirecting = false
    @State private var safariURL: URL?
    
    // Estados para el popup
    @Binding var lastOrder: Order?
    @Binding var showThankYou: Bool
    
    // Computed Properties
    private var totalTickets: Int {
        cartViewModel.totalTickets(for: eventViewModel.eventDetails)
    }
    
    private var subTotalPrice: Double {
        cartViewModel.subTotalPrice(for: eventViewModel.eventDetails)
    }
    
    private var serviceFeeAmount: Double {
        cartViewModel.serviceFeeAmount(for: eventViewModel.eventDetails)
    }
    
    private var totalPrice: Double {
        cartViewModel.totalPrice(for: eventViewModel.eventDetails)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation {
                                scrollProxy.scrollTo("summaryBottom", anchor: .bottom)
                            }
                        }
                    }) {
                        HStack {
                            Text("Resumen del pedido")
                                .font(.headline)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }

                    if isExpanded {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Boletos").foregroundColor(.secondary)
                                Spacer()
                                Text("\(totalTickets)").bold()
                            }
                            HStack {
                                Text("Subtotal").foregroundColor(.secondary)
                                Spacer()
                                Text(subTotalPrice.formatted(.currency(code: "MXN")))
                                    .bold()
                                    .foregroundColor(Color("MoneyGreen"))
                            }
                            HStack {
                                Text("Cuota de servicio (4%)").foregroundColor(.secondary)
                                Spacer()
                                Text(serviceFeeAmount.formatted(.currency(code: "MXN")))
                                    .bold()
                                    .foregroundColor(Color("MoneyGreen"))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                        .transition(.opacity)
                    }

                    Divider()
                        .padding(.horizontal, isExpanded ? 0 : 16)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total").font(.subheadline).foregroundColor(.secondary)
                            Text(totalPrice.formatted(.currency(code: "MXN")))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color("MoneyGreen"))
                        }

                        Spacer()

                        Button(action: {
                            guard let eventDetails = eventViewModel.eventDetails else {
                                print("❌ [OrderSummary] No hay datos del evento")
                                return
                            }
                            
                            showRedirecting = true
                            cartViewModel.fetchCheckoutURL(eventDetails: eventDetails) { url in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showRedirecting = false
                                    if let finalURL = url {
                                        print("🔗 [DEBUG] URL de checkout:", finalURL.absoluteString)
                                        safariURL = finalURL
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image("mercado_pago_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                                Text("Pagar ahora")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 200, height: 50)
                            .background(Color(red: 0.0, green: 0.62, blue: 0.89))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .disabled(eventViewModel.eventDetails == nil)
                        .opacity(eventViewModel.eventDetails == nil ? 0.6 : 1.0)
                    }
                    .padding()
                    .id("summaryBottom")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .fullScreenCover(isPresented: $showRedirecting) {
            RedirectingView()
        }
        .fullScreenCover(item: $safariURL) { url in
            SafariView(url: url) {
                handleSafariDismiss()
            }
            .ignoresSafeArea()
        }
    }
    
    // 🔧 EXTRAER LA LÓGICA DE SAFARI A UNA FUNCIÓN SEPARADA
    private func handleSafariDismiss() {
        print("🎭 [OrderSummary] Safari cerrado, procesando resultado...")
        
        guard let ref = cartViewModel.latestExternalReference else {
            print("❌ [OrderSummary] No hay external reference")
            self.selectedTab = 2
            return
        }
        
        print("🔍 [OrderSummary] Buscando orden con ref: \(ref)")
        
        OrderService.fetchOrderByExternalReferenceWithRetry(ref: ref) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let order):
                    print("✅ [OrderSummary] Orden obtenida: \(order.id), status: \(order.status)")
                    
                    let status = order.status.lowercased()
                    
                    switch status {
                    case "approved":
                        print("✅ [OrderSummary] Pago aprobado - Configurando popup")
                        showSuccessPopup(order: order)
                        
                    case "pending":
                        print("✅ [OrderSummary] Pago pendiente - Configurando popup")
                        showSuccessPopup(order: order)
                        
                    case "created":
                        print("🚫 [OrderSummary] Usuario canceló - Status: created")
                        // NO hacer nada, mantener carrito
                        
                    case "rejected", "cancelled", "failure":
                        print("⚠️ [OrderSummary] Pago falló - Status: \(status)")
                        showFailurePopup(order: order)
                        
                    default:
                        print("❓ [OrderSummary] Estado desconocido: \(status)")
                        self.selectedTab = 2
                    }
                    
                case .failure(let error):
                    print("❌ [OrderSummary] Error obteniendo orden: \(error)")
                    self.selectedTab = 2
                }
            }
        }
    }
    
    // 🔧 FUNCIONES HELPER PARA MOSTRAR POPUP
    private func showSuccessPopup(order: Order) {
        print("🎭 [OrderSummary] Mostrando popup de éxito para orden: \(order.id)")
        
        // Configurar orden y mostrar popup
        self.lastOrder = order
        
        // Limpiar carrito
        cartViewModel.clearCart()
        
        // Enviar notificación para refrescar tickets
        NotificationCenter.default.post(name: NSNotification.Name("RefreshTickets"), object: nil)
        print("📤 [OrderSummary] Notificación RefreshTickets enviada (\(order.status))")
        
        // Mostrar popup con un pequeño delay para asegurar que se configure correctamente
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🎭 [OrderSummary] Activando showThankYou")
            self.showThankYou = true
        }
    }
    
    private func showFailurePopup(order: Order) {
        print("🎭 [OrderSummary] Mostrando popup de fallo para orden: \(order.id)")
        
        // Solo mostrar popup, NO limpiar carrito para fallos
        self.lastOrder = order
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🎭 [OrderSummary] Activando showThankYou para fallo")
            self.showThankYou = true
        }
    }
}

// MARK: - Resto de componentes sin cambios
struct ConfirmationPopup: View {
    let order: Order
    let onClose: () -> Void

    var mensaje: String {
        switch order.status.lowercased() {
        case "approved":
            return "Tu pago fue aprobado correctamente."
        case "pending":
            let metodo = order.payment_attempts?.first?.method?.lowercased() ?? ""
            if metodo.contains("spei") {
                return "Recuerda completar tu transferencia SPEI en las próximas horas."
            } else if metodo.contains("oxxo") {
                return "Ve a cualquier tienda OXXO y proporciona el código generado para completar tu pago."
            } else {
                return "Tu pago está pendiente. Sigue las instrucciones del método seleccionado."
            }
        case "rejected", "cancelled", "failure":
            return "Tu pago no se pudo completar: \(order.payment_attempts?.first?.status_detail ?? "")"
        default:
            return "Tu pago está siendo procesado. Verifica el estado en unos minutos."
        }
    }
    
    var iconName: String {
        switch order.status.lowercased() {
        case "approved": return "checkmark.circle.fill"
        case "pending": return "clock.circle.fill"
        case "rejected", "cancelled", "failure": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch order.status.lowercased() {
        case "approved": return .green
        case "pending": return .orange
        case "rejected", "cancelled", "failure": return .red
        default: return .blue
        }
    }
    
    var buttonText: String {
        switch order.status.lowercased() {
        case "approved", "pending":
            return "Ver mis tickets"
        default:
            return "Revisar tickets"
        }
    }

    var body: some View {
        BackgroundGeneralView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            Image(systemName: iconName)
                                .font(.system(size: 60))
                                .foregroundColor(iconColor)
                                .padding(.top, 8)

                            VStack(spacing: 16) {
                                Text("¡Gracias por tu compra!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text("Estado: \(order.localizedStatus)")
                                    .font(.headline)
                                    .foregroundColor(order.statusColor)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                    .frame(maxWidth: 200)
                            }

                            VStack(spacing: 12) {
                                ForEach(order.items.filter { !$0.name.lowercased().contains("cuota") }, id: \.self) { item in
                                    HStack {
                                        Text("\(item.qty) ×").foregroundColor(.secondary)
                                        Text(item.name).foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .font(.subheadline)
                                }

                                HStack {
                                    Text("Total:").fontWeight(.semibold)
                                    Spacer()
                                    Text(order.total.formatted(.currency(code: "MXN")))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("MoneyGreen"))
                                }
                                .font(.headline)
                                .padding(.top, 8)
                            }

                            Text(mensaje)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)

                            Button(action: {
                                print("🎭 [ConfirmationPopup] Botón presionado")
                                onClose()
                            }) {
                                Text(buttonText)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color("PrimaryColor"))
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                        )
                        .frame(width: min(geometry.size.width * 0.85, 340))
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            print("🎭 [ConfirmationPopup] Popup apareció para orden: \(order.id)")
        }
    }
}

struct RedirectingView: View {
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let logoWidth = isLandscape ? geometry.size.width * 0.45 : geometry.size.width * 0.4
            let fontSize = isLandscape ? geometry.size.width * 0.035 : geometry.size.width * 0.045

            BackgroundGeneralView {
                VStack(spacing: isLandscape ? 30 : 40) {
                    Image("mercado_pago_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoWidth)
                        .shadow(radius: 4)

                    Text("Conectando con Mercado Pago…")
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundColor(.white)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                        .scaleEffect(1.4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
            }
        }
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.minus")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 120)
                .padding()
                .foregroundColor(Color("PrimaryColor"))
            
            Text("Tu carrito está vacío")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Tu carrito está vacío. ¡Hora de llenarlo!")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CartView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        CartView(selectedTab: $selectedTab)
            .environmentObject(CartViewModel())
            .environmentObject(EventViewModel(eventId: "8avevXHoe4aXoMQEDOic"))
            .previewDevice("iPhone 15 Pro")
    }
}
