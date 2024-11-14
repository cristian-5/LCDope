//
//  LCDopeApp.swift
//  LCDope
//
//  Created by Cristian on 14/11/24.
//

import SwiftUI

@main
struct LCDopeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: LCDopeDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
