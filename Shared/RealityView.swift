//
//  RealityView.swift
//  RealityNodesDemo
//
//  Created by Anton Heestand on 2021-10-10.
//

import SwiftUI
import RealityKit

struct RealityView: ViewRepresentable {
    
    let entity: Entity
    
    func makeView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)
        let anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        return arView
    }
    
    func updateView(_ view: ARView, context: Context) {}
    
}
