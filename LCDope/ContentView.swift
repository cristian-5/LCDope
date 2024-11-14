//
//  ContentView.swift
//  LCDope
//
//  Created by Cristian on 14/11/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: LCDopeDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(LCDopeDocument()))
}
