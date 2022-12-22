//
//  ContentView.swift
//  EasySheet
//
//  Created by Yevhenii Korsun on 22.12.2022.
//

import SwiftUI

struct ContentView: View {
    @State private var showFirst = false
    @State private var showSecond = false
    @State private var showThird = false
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            
            Button {
                showFirst = true
            } label: {
                Text("ShowFirst")
            }
        }
        .easySheet(isPresented: $showFirst) {
            FirstView(showSecond: $showSecond)
        }
        .easySheet(isPresented: $showSecond) {
            SecondView(showThird: $showThird)
        }
        .easySheet(isPresented: $showThird, detends: [.medium, .large, .small], dismissible: true, grabberColor: .white, backgroundColor: .blue){
            ThirdView()
        }
//        .sheet(isPresented: $showFirst) {
//            FirstView(showSecond: $showSecond)
//                .interactiveDismissDisabled()
//        }
        //        .sheet(isPresented: $showFirst) {
        //            SecondView(showThird: $showThird)
        //        }
        //        .sheet(isPresented: $showFirst) {
        //            ThirdView()
        //        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FirstView: View {
    @Binding var showSecond: Bool
    
    var body: some View {
        ZStack {
            Button {
                showSecond = true
            } label: {
                Text("ShowSecond")
            }
        }
    }
}

struct SecondView: View {
    @Binding var showThird: Bool
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            
            Button {
                showThird = true
            } label: {
                Text("ShowSecond")
            }
        }
    }
}

struct ThirdView: View {
    @Environment(\.easyDismiss) var easyDismiss
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            Button {
                easyDismiss()
            } label: {
                Text("Close")
                    .foregroundColor(.yellow)
            }
        }
    }
}
