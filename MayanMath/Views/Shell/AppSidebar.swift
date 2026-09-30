//
//  AppSidebar.swift
//  MayanMath
//
//  Barra lateral con las 5 secciones. El fondo de la sección activa
//  se desliza entre botones (matchedGeometryEffect).
//

import SwiftUI

struct AppSidebar: View {
    @Binding var selection: AppSection
    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 10) {
            ForEach(AppSection.allCases) { section in
                let isActive = selection == section
                Button {
                    withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
                        selection = section
                    }
                } label: {
                    VStack(spacing: 8) {
                        section.icon(size: 30)
                            .frame(height: 32)
                            .symbolEffect(.bounce, value: isActive)
                        Text(section.label)
                            .font(.rounded(15, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(isActive ? Palette.navActiveText : Color(hex: 0x241B16))
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Palette.navActive)
                                .matchedGeometryEffect(id: "activeSection", in: namespace)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(LiftButtonStyle())
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .frame(width: Metrics.sidebarWidth)
        .background(Palette.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Palette.sidebarBorder).frame(width: 1)
        }
    }
}
