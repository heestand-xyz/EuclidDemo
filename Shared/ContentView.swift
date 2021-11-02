//
//  ContentView.swift
//  Shared
//
//  Created by Anton Heestand on 2021-10-12.
//

import SwiftUI
import RealityKit
import Euclid
import SceneKit

struct ContentView: View {
    
    @State var sphereEntity: Entity?
    @State var boxEntity: Entity?
    @State var euclidEntity: Entity?

    var body: some View {
        VStack {
            
            HStack {
                
                if let entity: Entity = sphereEntity {
                    RealityView(entity: entity)
                }
                
                Text("-")
                
                if let entity: Entity = boxEntity {
                    RealityView(entity: entity)
                }
                
                Text("=")
                
                if let entity: Entity = euclidEntity {
                    RealityView(entity: entity)
                } else {
                    ProgressView()
                        .padding(100)
                }
            }
            .font(.system(size: 100, weight: .bold, design: .monospaced))
            
            if euclidEntity == nil {
                VStack {
                    Text("Euclid is processing the bool operation.")
                    Text("This can take a couple minutes with large meshes...")
                }
                .padding(20)
            }
        }
        .onAppear {
            
            let sphereMesh: MeshResource = .generateSphere(radius: 0.75)
            let boxMesh: MeshResource = .generateBox(size: 1.0)
            
            sphereEntity = ModelEntity(mesh: sphereMesh)
            boxEntity = ModelEntity(mesh: boxMesh)
            
            let sphereEuclidMesh: Mesh = toEuclid(mesh: sphereMesh)
            let boxEuclidMesh: Mesh = toEuclid(mesh: boxMesh)
            
            DispatchQueue.global(qos: .userInitiated).async {
            
                print("Euclid Bool...")
                
                /// This can take a minute
                let euclidMesh: Mesh = sphereEuclidMesh.subtract(boxEuclidMesh)
                
                print("Euclid Done!")

                DispatchQueue.main.async {
                    
                    let finalMesh: MeshResource = try! fromEuclid(mesh: euclidMesh)
                    
                    euclidEntity = ModelEntity(mesh: finalMesh)
                }
            }
        }
    }
    
    func toEuclid(mesh: MeshResource) -> Mesh {
        
        var inPositions: [SIMD3<Float>] = []
        var inNormals: [SIMD3<Float>] = []
        var inIndices: [UInt32] = []
        var inCoords: [SIMD2<Float>] = []

        for model in mesh.contents.models {
            for part in model.parts {

                for position in part.positions.elements {
                    inPositions.append(position)
                }

                if let normals = part.normals {
                    for normal in normals.elements {
                        inNormals.append(normal)
                    }
                }

                if let triangles = part.triangleIndices {
                    for triangleIndex in triangles.elements {
                        inIndices.append(triangleIndex)
                    }
                }

                if let textureCoordinates = part.textureCoordinates {
                    for textureCoordinate in textureCoordinates.elements {
                        inCoords.append(textureCoordinate)
                    }
                }

            }
        }
        
        var sources: [SCNGeometrySource] = []
        var elements: [SCNGeometryElement] = []
        sources.append(SCNGeometrySource(vertices: inPositions.map({ vector in
            SCNVector3(vector.x, vector.y, vector.x)
        })))
        elements.append(SCNGeometryElement(indices: inIndices, primitiveType: .triangles))
        let geometry = SCNGeometry(sources: sources, elements: elements)
        
        return Mesh(geometry, materialLookup: nil)!
    }
    
    func fromEuclid(mesh: Mesh) throws -> MeshResource {
        
        var descriptor = MeshDescriptor(name: "test")
        descriptor.positions = MeshBuffers.Positions(
            mesh.polygons.flatMap({ polygon in
                polygon.vertices.map { vertex in
                    SIMD3<Float>(
                        x: Float(vertex.position.x),
                        y: Float(vertex.position.y),
                        z: Float(vertex.position.z)
                    )
                }
            })
        )
        descriptor.normals = MeshBuffers.Normals(
            mesh.polygons.flatMap({ polygon in
                polygon.vertices.map { vertex in
                    SIMD3<Float>(
                        x: Float(vertex.normal.x),
                        y: Float(vertex.normal.y),
                        z: Float(vertex.normal.z)
                    )
                }
            })
        )
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(
            mesh.polygons.flatMap({ polygon in
                polygon.vertices.map { vertex in
                    SIMD2<Float>(
                        x: Float(vertex.texcoord.x),
                        y: Float(vertex.texcoord.y)
                    )
                }
            })
        )
        var prims: [UInt32] = []
        var index: UInt32 = 0
        for _ in mesh.polygons {
            prims.append(contentsOf: [index, index + 1, index + 2])
            index += 3
        }
        descriptor.primitives = .triangles(prims)
        
        return try .generate(from: [descriptor])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
