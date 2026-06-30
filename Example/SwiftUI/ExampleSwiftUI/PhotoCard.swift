//
//  PhotoCard.swift
//  ExampleSwiftUI
//
//  Created by Frank Schmitt on 5/3/23.
//

import SwiftUI
import ApptentiveKit

struct PhotoCard: View {
    @Binding var isFavorite: Bool
    let image: UIImage

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: self.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .containerRelativeFrame(
                    .horizontal
                ) { length, axis in
                    if axis == .vertical {
                        return length
                    } else {
                        return length / 1.1
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button(action: {
                self.isFavorite.toggle()
                Apptentive.shared.engage(event: "toggle_favorite")
            }) {
                if self.isFavorite {
                    Image(systemName: "heart.fill")
                } else {
                    Image(systemName: "heart")
                }
            }
            .padding(8)
            .background(.thinMaterial, in: Circle())
            .padding()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    PhotoCard(isFavorite: .constant(false), image: UIImage(named: "Placeholder")!)
}
