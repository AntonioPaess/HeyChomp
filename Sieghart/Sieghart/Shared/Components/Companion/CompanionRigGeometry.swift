// Rounded companion family. The actor, pose clock and renderer share this geometry.
@preconcurrency import AppKit
@preconcurrency import SceneKit
import SwiftUI

extension CompanionAvatar {
    var color:NSColor {
        self == .ada ? rigRgb(0.24, 0.17, 0.30) : rigRgb(0.17, 0.17, 0.18)
    }
}
func rigRgb(_ r:Double,_ g:Double,_ b:Double)->NSColor {NSColor(srgbRed:r,green:g,blue:b,alpha:1)}
let rigJade = rigRgb(0.22, 0.80, 0.58)
let rigCream=rigRgb(1,0.94,0.82), rigCoral=rigRgb(0.96,0.55,0.44), rigMint=rigRgb(0.60,0.82,0.62), rigLilac=rigRgb(0.69,0.59,0.88), rigInk=rigRgb(0.07,0.09,0.09), rigGold=rigRgb(0.81,0.56,0.22)

private nonisolated(unsafe) var rigPaperTextures:[String:NSImage]=[:]
private let rigTextureLock = NSLock()
func rigTactileTexture(_ color:NSColor)->NSImage {
    rigTextureLock.lock(); defer { rigTextureLock.unlock() }
    let c=color.usingColorSpace(.sRGB)!,key="\(c.redComponent)-\(c.greenComponent)-\(c.blueComponent)"
    if let saved=rigPaperTextures[key] {return saved}
    let size=256,rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:size*4,bitsPerPixel:32)!
    var seed:UInt64=0xAB42
    for y in 0..<size {for x in 0..<size {
        seed=seed &* 6364136223846793005 &+ 1442695040888963407
        let grain=(Double((seed>>32)&255)/255-0.5)*0.028
        let offset=y*rep.bytesPerRow+x*4
        for (i,v) in [c.redComponent,c.greenComponent,c.blueComponent].enumerated() {rep.bitmapData![offset+i]=UInt8(max(0,min(255,(v+grain)*255)))}
        rep.bitmapData![offset+3]=255
    }}
    let image=NSImage(size:CGSize(width:size,height:size));image.addRepresentation(rep);rigPaperTextures[key]=image;return image
}

func rigMaterial(_ color:NSColor,metal:Double=0)->SCNMaterial {
    let m=SCNMaterial();m.lightingModel = .physicallyBased
    m.diffuse.contents=metal>0 ? color : rigTactileTexture(color);m.roughness.contents=metal>0 ? 0.36 : 0.66;m.metalness.contents=metal
    m.specular.contents=NSColor(white:0.34,alpha:1);m.isDoubleSided=true
    return m
}
func rigNsPath(_ path:Path)->NSBezierPath {
    let bezier=NSBezierPath();bezier.windingRule = .evenOdd;bezier.flatness=0.12
    func point(_ p:CGPoint)->CGPoint {CGPoint(x:p.x-48,y:48-p.y)}
    var current=CGPoint.zero
    path.cgPath.applyWithBlock { ptr in
        let element=ptr.pointee
        switch element.type {
        case .moveToPoint: current=point(element.points[0]);bezier.move(to:current)
        case .addLineToPoint:current=point(element.points[0]);bezier.line(to:current)
        case .addQuadCurveToPoint:
            let control=point(element.points[0]),end=point(element.points[1])
            let a=CGPoint(x:current.x+(control.x-current.x)*2/3,y:current.y+(control.y-current.y)*2/3)
            let b=CGPoint(x:end.x+(control.x-end.x)*2/3,y:end.y+(control.y-end.y)*2/3)
            bezier.curve(to:end,controlPoint1:a,controlPoint2:b);current=end
        case .addCurveToPoint:
            let end=point(element.points[2]);bezier.curve(to:end,controlPoint1:point(element.points[0]),controlPoint2:point(element.points[1]));current=end
        case .closeSubpath:bezier.close()
        @unknown default:break
        }
    }
    return bezier
}
func rigPolygon(_ points:[(Double,Double)],radius:Double=0)->Path {
    let points=points.map{CGPoint(x:$0.0,y:$0.1)}
    var p=Path()
    for i in points.indices {
        let current=points[i],prev=points[(i+points.count-1)%points.count],next=points[(i+1)%points.count]
        func toward(_ n:CGPoint)->CGPoint {
            let x=n.x-current.x,y=n.y-current.y,dist=hypot(x,y),f=min(radius/max(0.01,dist),0.45)
            return CGPoint(x:current.x+x*f,y:current.y+y*f)
        }
        let a=toward(prev),b=toward(next)
        if i==0 {p.move(to:a)} else {p.addLine(to:a)}
        p.addQuadCurve(to:b,control:current)
    }
    p.closeSubpath();return p
}
func rigBodyPath(_ hero: CompanionAvatar) -> Path {
    // Shape coordinates are shared by the avatar, accessory anchor points,
    // greeting camera and the weather silhouette.
    let shoulders: CGFloat = hero == .sig ? 23 : 25
    let base: CGFloat = hero == .gantt ? 79 : 77
    return Path { path in
        path.move(to: CGPoint(x: 11, y: 63))
        path.addCurve(to: CGPoint(x: 54, y: shoulders),
                      control1: CGPoint(x: 14, y: 43), control2: CGPoint(x: 36, y: shoulders))
        path.addCurve(to: CGPoint(x: 82, y: 60),
                      control1: CGPoint(x: 72, y: shoulders), control2: CGPoint(x: 82, y: 40))
        path.addCurve(to: CGPoint(x: 49, y: base),
                      control1: CGPoint(x: 84, y: 74), control2: CGPoint(x: 69, y: base))
        path.addCurve(to: CGPoint(x: 11, y: 63),
                      control1: CGPoint(x: 25, y: base), control2: CGPoint(x: 8, y: 75))
        path.closeSubpath()
    }
}

func rigDiamondPath(x: Double, y: Double, radius: Double) -> Path {
    Path { path in
        path.move(to: CGPoint(x: x, y: y - radius))
        path.addQuadCurve(to: CGPoint(x: x + radius, y: y), control: CGPoint(x: x + radius * 0.30, y: y - radius * 0.25))
        path.addQuadCurve(to: CGPoint(x: x, y: y + radius), control: CGPoint(x: x + radius * 0.25, y: y + radius * 0.30))
        path.addQuadCurve(to: CGPoint(x: x - radius, y: y), control: CGPoint(x: x - radius * 0.30, y: y + radius * 0.25))
        path.addQuadCurve(to: CGPoint(x: x, y: y - radius), control: CGPoint(x: x - radius * 0.25, y: y - radius * 0.30))
        path.closeSubpath()
    }
}

func rigShape(_ path:Path,color:NSColor,depth:Double=12,bevel:Double=3,side:NSColor?=nil)->SCNNode {
    let s=SCNShape(path:rigNsPath(path),extrusionDepth:depth);s.chamferRadius=bevel
    let front=rigMaterial(color),edge=rigMaterial(side ?? color)
    s.materials=[front,edge,edge,front,edge]
    let n=SCNNode(geometry:s);return n
}
func rigStroke(_ path:Path,color:NSColor,width:Double=2,depth:Double=1.4,metal:Double=0)->SCNNode {
    let root=SCNNode(),mat=rigMaterial(color,metal:metal)
    var current=CGPoint.zero,start=CGPoint.zero
    func add(_ end:CGPoint) {
        let dx=end.x-current.x,dy=end.y-current.y,d=hypot(dx,dy)
        if d>0.01 {
            let tube=SCNCapsule(capRadius:width/2,height:d+width);tube.radialSegmentCount=10;tube.capSegmentCount=3;tube.heightSegmentCount=1;tube.materials=[mat]
            let node=SCNNode(geometry:tube);node.position=SCNVector3((current.x+end.x)/2-48,48-(current.y+end.y)/2,0)
            node.eulerAngles.z=CGFloat(atan2(-dy,dx)-Double.pi/2);node.scale.z=CGFloat(depth/width);root.addChildNode(node)
        }
        current=end
    }
    path.cgPath.applyWithBlock {ptr in
        let e=ptr.pointee
        switch e.type {
        case .moveToPoint:current=e.points[0];start=current
        case .addLineToPoint:add(e.points[0])
        case .addQuadCurveToPoint:
            let a=current,b=e.points[0],c=e.points[1]
            for i in 1...12 {let t=Double(i)/12,u=1-t;add(CGPoint(x:u*u*a.x+2*u*t*b.x+t*t*c.x,y:u*u*a.y+2*u*t*b.y+t*t*c.y))}
        case .addCurveToPoint:
            let a=current,b=e.points[0],c=e.points[1],d=e.points[2]
            for i in 1...16 {let t=Double(i)/16,u=1-t;add(CGPoint(x:u*u*u*a.x+3*u*u*t*b.x+3*u*t*t*c.x+t*t*t*d.x,y:u*u*u*a.y+3*u*u*t*b.y+3*u*t*t*c.y+t*t*t*d.y))}
        case .closeSubpath:add(start)
        @unknown default:break
        }
    }
    // Segments never move relative to one another. Bake them into one mesh
    // so a ring does not issue dozens of separate draw commands every frame.
    return root.flattenedClone()
}

// Restore the earlier fixed badge with a travelling inner stroke. Only one
// shader uniform changes per frame; the badge and its silhouette never rotate.
func rigLoadingBadge(_ model: CompanionRigModel) -> (node: SCNNode, progress: SCNMaterial) {
    let node = SCNNode()
    if model.usesIllustration {
        let material=SCNMaterial(); material.lightingModel = .constant
        material.isDoubleSided=true; material.writesToDepthBuffer=false; material.blendMode = .alpha
        material.setValue(Float(0),forKey:"phase")
        material.shaderModifiers=[.fragment:"""
        #pragma arguments
        float phase;
        #pragma transparent
        #pragma body
        float2 uv=_surface.diffuseTexcoord;
        float alpha=0.0;
        for (int i=0; i<3; i++) {
            float2 center=float2(0.2+float(i)*0.3,0.5);
            float distance=length((uv-center)*float2(20.0,6.0));
            float coverage=1.0-smoothstep(1.0,1.25,distance);
            float pulse=0.48+0.38*cos(phase*6.283185-float(i)*0.85);
            alpha=max(alpha,coverage*pulse);
        }
        _output.color=float4(float3(0.19,0.65,0.46)*alpha,alpha);
        """]
        let plane=SCNPlane(width:20,height:6); plane.materials=[material]
        node.geometry=plane
        return (node,material)
    }
    let hero = model.hero
    let outer = CompanionLoadingShape(avatar: hero).path(in: CGRect(x: 38, y: 38, width: 20, height: 20))
    node.addChildNode(model.motionShape(outer, color: NSColor(hero.processingTint), depth: 1.5, bevel: 0.4))
    let outline = outer.strokedPath(StrokeStyle(lineWidth: 1.2, lineJoin: .round))
    let edge = model.motionShape(outline, color: rigRgb(0.14, 0.17, 0.16), depth: 0.5)
    edge.position.z = 1.5; node.addChildNode(edge)
    let inner = CompanionLoadingShape(avatar: hero).path(in: CGRect(x: 41, y: 41, width: 14, height: 14))
    var points: [CGPoint] = [], current = CGPoint.zero
    func append(_ p: CGPoint) {
        if let last = points.last, hypot(p.x - last.x, p.y - last.y) < 0.001 { return }
        points.append(p); current = p
    }
    inner.cgPath.applyWithBlock { pointer in
        let e = pointer.pointee
        switch e.type {
        case .moveToPoint, .addLineToPoint: append(e.points[0])
        case .addQuadCurveToPoint:
            let a = current, b = e.points[0], c = e.points[1]
            for i in 1...12 { let t = Double(i) / 12, u = 1 - t; append(CGPoint(x: u*u*a.x + 2*u*t*b.x + t*t*c.x, y: u*u*a.y + 2*u*t*b.y + t*t*c.y)) }
        case .addCurveToPoint:
            let a = current, b = e.points[0], c = e.points[1], d = e.points[2]
            for i in 1...16 { let t = Double(i) / 16, u = 1 - t; append(CGPoint(x: u*u*u*a.x + 3*u*u*t*b.x + 3*u*t*t*c.x + t*t*t*d.x, y: u*u*u*a.y + 3*u*u*t*b.y + 3*u*t*t*c.y + t*t*t*d.y)) }
        case .closeSubpath: break
        @unknown default: break
        }
    }
    if let first = points.first, let last = points.last, hypot(first.x-last.x, first.y-last.y) < 0.001 { points.removeLast() }
    let n = points.count
    var distances = [0.0]
    for i in 0..<n { let a = points[i], b = points[(i+1)%n]; distances.append(distances.last! + hypot(b.x-a.x, b.y-a.y)) }
    var vertices: [SCNVector3] = [], uv: [CGPoint] = [], indices: [Int32] = []
    func normal(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        let length = max(0.001, hypot(b.x-a.x, b.y-a.y))
        return CGPoint(x: -(b.y-a.y)/length, y: (b.x-a.x)/length)
    }
    for i in 0...n {
        let p = points[i%n], before = normal(points[(i+n-1)%n], p), after = normal(p, points[(i+1)%n])
        let length = max(0.001, hypot(before.x+after.x, before.y+after.y))
        let m = CGPoint(x: (before.x+after.x)/length, y: (before.y+after.y)/length)
        let width = min(1.8, 0.95 / max(0.25, m.x*after.x + m.y*after.y))
        for sign in [-1.0, 1] {
            vertices.append(SCNVector3(p.x - 48 + m.x*width*sign, 48 - p.y - m.y*width*sign, 2))
            uv.append(CGPoint(x: distances[i] / distances.last!, y: (sign+1)/2))
        }
        if i < n { let a = Int32(i*2); indices += [a,a+1,a+2,a+1,a+3,a+2] }
    }
    let progress = SCNMaterial(); progress.lightingModel = .constant
    progress.isDoubleSided = true; progress.writesToDepthBuffer = false; progress.blendMode = .alpha
    progress.setValue(Float(0), forKey: "phase")
    progress.shaderModifiers = [.fragment: """
    #pragma arguments
    float phase;
    #pragma transparent
    #pragma body
    float d = fract(_surface.diffuseTexcoord.x - phase + 1.0);
    float arc = 1.0 - step(0.29, d);
    float alpha = mix(0.14, 0.90, arc);
    // SceneKit's transparent fragment output is linear and premultiplied.
    _output.color = float4(float3(0.0174, 0.0245, 0.0220) * alpha, alpha);
    """]
    let mesh = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(textureCoordinates: uv)],
                           elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    mesh.materials = [progress]; node.addChildNode(SCNNode(geometry: mesh))
    return (node, progress)
}

func rigEyePath(rect: CGRect, joy: Double) -> Path {
    let j = min(1, max(0, joy))
    func mix(_ a:(Double,Double),_ b:(Double,Double))->CGPoint {CGPoint(x:rect.minX+(a.0+(b.0-a.0)*j)*rect.width,y:rect.minY+(a.1+(b.1-a.1)*j)*rect.height)}
    var p=Path();p.move(to:mix((0,0.5),(0,0.85)))
    p.addCurve(to:mix((0.5,0),(0.5,0.15)),control1:mix((0,0.22),(0,0.48)),control2:mix((0.22,0),(0.22,0.15)))
    p.addCurve(to:mix((1,0.5),(1,0.85)),control1:mix((0.78,0),(0.78,0.15)),control2:mix((1,0.22),(1,0.48)))
    p.addCurve(to:mix((0.5,1),(0.5,0.45)),control1:mix((1,0.78),(1,1)),control2:mix((0.78,1),(0.80,0.45)))
    p.addCurve(to:mix((0,0.5),(0,0.85)),control1:mix((0.22,1),(0.20,0.45)),control2:mix((0,0.78),(0,1)));p.closeSubpath();return p
}

// The atlas holds the approved illustration in unlit, transparent layers.
// SceneKit only supplies transforms, draw order and the existing pose clock.
private final class CompanionIllustration {
    struct Part {
        let image: CGImage
        let x: Double, y: Double
        let pixelsPerPoint: Double

        var width: Double { Double(image.width) / pixelsPerPoint }
        var height: Double { Double(image.height) / pixelsPerPoint }

        func plane() -> SCNPlane {
            let plane = SCNPlane(width: width, height: height)
            plane.materials = [CompanionIllustration.material(image)]
            return plane
        }

        func node(z: Double) -> SCNNode {
            let node = SCNNode(geometry: plane())
            node.position = SCNVector3(x, y, z)
            return node
        }
    }

    private static let index: [String: [String: [Double]]] = {
        guard let asset = NSDataAsset(name: "CompanionIllustrations"),
              let data = try? JSONDecoder().decode([String: [String: [Double]]].self, from: asset.data)
        else { return [:] }
        return data
    }()
    private nonisolated(unsafe) static let cache = NSCache<NSString, CompanionIllustration>()
    private let parts: [String: Part]

    subscript(_ part: String) -> Part? { parts[part] }

    private init(parts: [String: Part]) { self.parts = parts }

    static func load(_ avatar: CompanionAvatar) -> CompanionIllustration? {
        let key = avatar.rawValue as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let entry = index[avatar.rawValue],
              let image = NSImage(named: "Companion-\(avatar.rawValue)-illustration"),
              let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        var parts: [String: Part] = [:]
        for (name, values) in entry where values.count == 7 && values[6] > 0 {
            let region = CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
            guard let part = pixels.cropping(to: region) else { continue }
            parts[name] = Part(image: part, x: values[4], y: values[5], pixelsPerPoint: values[6])
        }
        guard parts["body"] != nil, parts["eye0"] != nil, parts["eye1"] != nil else { return nil }
        let illustration = CompanionIllustration(parts: parts)
        cache.setObject(illustration, forKey: key)
        return illustration
    }

    static func paint(_ path: Path, light: NSColor, shade: NSColor) -> SCNPlane? {
        let bounds = path.boundingRect.insetBy(dx: -0.5, dy: -0.5)
        let scale = 4.0
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let canvas = CGContext(data: nil, width: Int(ceil(bounds.width * scale)),
                                     height: Int(ceil(bounds.height * scale)), bitsPerComponent: 8,
                                     bytesPerRow: 0, space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        canvas.translateBy(x: -bounds.minX * scale, y: bounds.maxY * scale)
        canvas.scaleBy(x: scale, y: -scale)
        canvas.addPath(path.cgPath)
        canvas.clip(using: .evenOdd)
        let colors = [light.cgColor, shade.cgColor]
        if let paint = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) {
            canvas.drawLinearGradient(paint, start: CGPoint(x: bounds.midX, y: bounds.minY),
                                      end: CGPoint(x: bounds.midX, y: bounds.maxY), options: [])
        }
        guard let image = canvas.makeImage() else { return nil }
        let plane = SCNPlane(width: bounds.width, height: bounds.height)
        plane.materials = [material(image)]
        return plane
    }

    static func material(_ paint: Any) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = paint
        material.isDoubleSided = true
        material.blendMode = .alpha
        material.writesToDepthBuffer = false
        return material
    }
}

// Created before attachment; afterwards only the SceneKit render callback mutates this rig.
final class CompanionRigModel {
    let hero:CompanionAvatar
    private let illustration: CompanionIllustration?
    var usesIllustration: Bool { illustration != nil }
    var usesIntegratedIllustration: Bool { illustration?["composite"] != nil }
    private var paintedSurface: SCNMaterial?
    let root=SCNNode(),head=SCNNode(),accessory=SCNNode(),activity=SCNNode()
    var eyes:[SCNNode]=[]
    var front:Double=10
    var paper:SCNNode?
    var paperRight:SCNNode?
    private(set) var notebook: SCNNode?
    private(set) var notebookLid: SCNNode?
    private var restingDevice: SCNNode?
    private var notebookArtwork: SCNNode?
    var identityAccent: SCNNode?
    var marker:SCNNode?
    var loadingProgress: SCNMaterial?
    // Quantized meshes are cached per live actor, with a bounded cache.
    private(set) var eyeCache:[String:SCNGeometry]=[:]
    private var eyeKeys = ["", ""]
    private lazy var eyeMaterial: SCNMaterial = {
        let material = rigMaterial(rigCream)
        material.roughness.contents = 0.42
        material.specular.contents = NSColor(white: 0.55, alpha: 1)
        return material
    }()
    init(_ hero:CompanionAvatar) {
        self.hero = hero
        illustration = CompanionIllustration.load(hero)
        root.addChildNode(head)
        if let illustration, let surface = illustration["body"] {
            front = 12.3
            let body = surface.node(z: front)
            // Keep both painted eyes above the body when a pose turns sideways.
            body.renderingOrder = -10
            if usesIntegratedIllustration, let plane = body.geometry as? SCNPlane {
                // Deform one continuous drawing. Contact shadows, the face and
                // fitted wearables stay in the same coordinate space.
                plane.widthSegmentCount = 64
                plane.heightSegmentCount = 64
                paintedSurface = plane.firstMaterial
                configurePaintedSurface(illustration, origin: surface)
            }
            head.addChildNode(body)
        } else {
            let body = rigShape(rigBodyPath(hero), color: hero.color, depth: 23, bevel: 7)
            let roundedLighting="""
            #pragma body
            if (_geometry.normal.z > 0.99) {
                _geometry.normal = normalize(float3(_geometry.position.x * 0.010, _geometry.position.y * 0.014, 1.0));
        }
        """
        body.geometry?.shaderModifiers=[.geometry:roundedLighting]
        head.addChildNode(body);front=Double(body.boundingBox.max.z)+0.8
        }
        head.addChildNode(accessory);head.addChildNode(activity)
        if let illustration { addIllustratedAccessories(illustration) }
        else { addAccessory() }
        for _ in 0..<2 {
            let eye = SCNNode()
            eye.position.z = CGFloat(front + 1.4)
            if usesIllustration { eye.renderingOrder = 2 }
            head.addChildNode(eye)
            eyes.append(eye)
        }
        updateEyes(open:1,joy:0,gaze:.zero,wink:0,anger:0)
    }
    private func attach(_ node: SCNNode, z: Double? = nil) {
        node.position.z = CGFloat(z ?? front + 2)
        accessory.addChildNode(node)
    }

    private func addIllustratedAccessories(_ art: CompanionIllustration) {
        guard !usesIntegratedIllustration else { return }
        @discardableResult func place(_ name: String, at z: Double) -> SCNNode? {
            guard let piece = art[name] else { return nil }
            let node = piece.node(z: front + z)
            accessory.addChildNode(node)
            return node
        }
        place("leaves", at: 0.5)?.renderingOrder = -11
        place("hat", at: 3)?.renderingOrder = 3
        place("glasses", at: 3.4)?.renderingOrder = 3
        place("pause", at: 3.5)
        paper = place("back", at: 4)
        paperRight = place("phones", at: 3)
        identityAccent = place("accent", at: 6)
        identityAccent?.renderingOrder = 3
        if hero == .toni { paper = identityAccent }
        if hero == .ada {
            restingDevice = identityAccent
            notebookArtwork = place("notebook", at: 10)
            addNotebook()
            setNotebookProgress(0)
        }
    }

    func setNotebookProgress(_ progress: Double) {
        guard let restingDevice else { return }
        restingDevice.opacity = 1 - progress
        notebook?.opacity = progress
        notebookArtwork?.opacity = progress
    }

    func notebookKeyPosition(_ index: Int, tap: Double) -> SCNVector3 {
        if let artwork = notebookArtwork, let plane = artwork.geometry as? SCNPlane {
            // The keyboard is visible on the left side of the painted hinge.
            let x = plane.width * (index == 0 ? -0.33 : -0.20)
            let y = plane.height * -0.27 + 2.4 - tap * 2.2
            return artwork.convertPosition(SCNVector3(x, y, 0.6), to: head)
        }
        let key = SCNVector3(index == 0 ? -4.2 : 4.2, 4.2 - tap * 2.2, 8)
        return notebook?.convertPosition(key, to: head) ?? key
    }

    func setNotebookTilt(_ tilt: Double) {
        notebookLid?.eulerAngles.x = CGFloat(-0.16 - tilt)
        notebookArtwork?.eulerAngles.z = CGFloat(-tilt * 0.24)
    }

    func paintedHand(_ index: Int) -> SCNGeometry? {
        illustration?["hand\(index)"]?.plane()
    }

    func motionShape(_ path: Path, color: NSColor, depth: Double = 1.2, bevel: Double = 0.3) -> SCNNode {
        let light = color.blended(withFraction: 0.14, of: .white) ?? color
        let shade = color.blended(withFraction: 0.22, of: .black) ?? color
        guard usesIllustration, let plane = CompanionIllustration.paint(path, light: light, shade: shade) else {
            return rigShape(path, color: color, depth: depth, bevel: bevel)
        }
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(path.boundingRect.midX - 48, 48 - path.boundingRect.midY, 0)
        return node
    }

    func setChompAccent(alternate: Bool) {
        guard hero == .sig, let material = identityAccent?.geometry?.firstMaterial else { return }
        if usesIllustration {
            material.multiply.contents = alternate ? rigRgb(1, 0.70, 1) : NSColor.white
        } else {
            material.diffuse.contents = alternate ? rigLilac : rigJade
        }
    }

    private func addAccessory() {
        let violet = rigRgb(0.54, 0.36, 0.72)
        let leaf = rigRgb(0.37, 0.68, 0.25)
        switch hero {
        case .sig:
            let diamond = rigShape(rigDiamondPath(x: 75, y: 16, radius: 9), color: rigJade, depth: 5, bevel: 1.5)
            diamond.pivot = SCNMatrix4MakeTranslation(27, 32, 0)
            diamond.position = SCNVector3(27, 32, 0)
            attach(diamond)
            identityAccent = diamond
        case .rita:
            attach(Self.sprout(color: leaf), z: 3)
            let glasses = SCNNode()
            let material = rigMaterial(rigLilac)
            for x in [49.0, 66.0] {
                let ring = SCNTorus(ringRadius: 7.3, pipeRadius: 1.45)
                ring.ringSegmentCount = 32; ring.pipeSegmentCount = 8; ring.materials = [material]
                let frame = SCNNode(geometry: ring)
                frame.position.x = CGFloat(x - 48); frame.position.y = 2; frame.eulerAngles.x = .pi / 2
                glasses.addChildNode(frame)
            }
            glasses.addChildNode(Self.prop(x: 55, y: 45, width: 5, height: 2.8, radius: 1.4, color: rigLilac))
            attach(glasses, z: front + 4.4)
            let book = Self.prop(x: 59, y: 60, width: 26, height: 20, radius: 3, color: violet, depth: 5)
            let page = Self.prop(x: 61, y: 58, width: 22, height: 6, radius: 2, color: rigCream)
            page.position.z = 1; book.addChildNode(page)
            let seam = Self.prop(x: 71, y: 62, width: 1.6, height: 17, radius: 0.7, color: rigLilac)
            seam.position.z = 2.7; book.addChildNode(seam)
            book.pivot = SCNMatrix4MakeTranslation(24, -22, 0)
            book.position = SCNVector3(24, -22, 0)
            attach(book, z: front + 5)
            identityAccent = book
        case .ada:
            addNotebook()
        case .gantt:
            let yellow = rigRgb(0.96, 0.71, 0.26)
            let cap = Path { path in
                path.move(to: CGPoint(x: 23, y: 36))
                path.addQuadCurve(to: CGPoint(x: 49, y: 13), control: CGPoint(x: 25, y: 12))
                path.addQuadCurve(to: CGPoint(x: 73, y: 29), control: CGPoint(x: 66, y: 13))
                path.addQuadCurve(to: CGPoint(x: 23, y: 36), control: CGPoint(x: 45, y: 28))
                path.closeSubpath()
            }
            attach(rigShape(cap, color: yellow, depth: 7, bevel: 3), z: front)
            attach(rigShape(rigPolygon([(18, 34), (73, 24), (77, 29), (20, 40)], radius: 3),
                            color: yellow, depth: 5, bevel: 2), z: front + 5)
            let calendar = Self.prop(x: 61, y: 58, width: 23, height: 22, radius: 3, color: rigCream, depth: 3.5)
            for x in [66.0, 77.0] {
                let binding = Self.prop(x: x, y: 55, width: 2.5, height: 7, radius: 1.2, color: violet)
                binding.position.z = 2.3; calendar.addChildNode(binding)
            }
            for row in 0..<2 {
                for column in 0..<3 {
                    let day = Self.prop(x: 65 + Double(column) * 5, y: 64 + Double(row) * 5,
                                        width: 3.1, height: 3.1, radius: 0.7, color: row == 0 && column == 2 ? violet : rigLilac)
                    day.position.z = 2.1; calendar.addChildNode(day)
                }
            }
            attach(calendar, z: front + 5)
            let page = Self.prop(x: 64, y: 61, width: 17, height: 16, radius: 2, color: rigCream)
            page.pivot = SCNMatrix4MakeTranslation(0, -13, 0)
            attach(page, z: front + 8); page.position.y = -13
            paper = page; page.opacity = 0
        case .elinor:
            attach(Self.sprout(color: leaf), z: 3)
            let amber = rigRgb(1, 0.58, 0.13)
            let gem = rigShape(rigPolygon([(69, 58), (82, 58), (89, 67), (85, 78), (74, 82), (65, 74)], radius: 1.2),
                               color: amber, depth: 8, bevel: 2, side: rigGold)
            for (points, color) in [
                ([(69.0, 58.0), (82, 58), (78, 67), (70, 69)], rigRgb(1, 0.78, 0.29)),
                ([(78.0, 67.0), (89, 67), (85, 78), (74, 82)], rigRgb(0.84, 0.40, 0.07))
            ] {
                let facet = rigShape(rigPolygon(points), color: color, depth: 0.35, bevel: 0)
                facet.position.z = 4.1; gem.addChildNode(facet)
            }
            gem.pivot = SCNMatrix4MakeTranslation(29, -21, 0)
            gem.position = SCNVector3(29, -21, front + 4)
            accessory.addChildNode(gem); identityAccent = gem
        case .toni:
            let band = Path { path in
                path.move(to: CGPoint(x: 13, y: 51))
                path.addCurve(to: CGPoint(x: 82, y: 50), control1: CGPoint(x: 10, y: 9), control2: CGPoint(x: 81, y: 5))
            }
            attach(rigStroke(band, color: violet, width: 5, depth: 6), z: 6)
            for x in [8.0, 77.0] {
                let ear = Self.prop(x: x, y: 44, width: 11, height: 19, radius: 5, color: rigLilac, depth: 8)
                attach(ear, z: front - 1)
                if x > 70 { paperRight = ear }
            }
            let folder = rigShape(rigPolygon([(58, 62), (62, 59), (69, 59), (72, 62), (87, 62), (86, 81), (57, 81)], radius: 2),
                                  color: rigCream, depth: 4, bevel: 1.5)
            let seal = rigShape(rigPolygon((0..<12).map { index in
                let angle = Double(index) * .pi / 6
                let radius = index.isMultiple(of: 2) ? 5.8 : 5.1
                return (74 + cos(angle) * radius, 72 + sin(angle) * radius)
            }, radius: 0.8), color: violet, depth: 1.6, bevel: 0.7)
            seal.position.z = 2.5; folder.addChildNode(seal)
            folder.pivot = SCNMatrix4MakeTranslation(13, -14, 0)
            folder.position = SCNVector3(13, -14, front + 5)
            accessory.addChildNode(folder); paper = folder
        }
    }

    private static func prop(x: Double, y: Double, width: Double, height: Double,
                             radius: Double, color: NSColor, depth: Double = 1.5) -> SCNNode {
        rigShape(Path(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: radius),
                 color: color, depth: depth, bevel: min(depth / 2, radius / 2))
    }

    private static func sprout(color: NSColor) -> SCNNode {
        let root = SCNNode()
        let stem = Path { path in
            path.move(to: CGPoint(x: 43, y: 28))
            path.addQuadCurve(to: CGPoint(x: 49, y: 12), control: CGPoint(x: 40, y: 17))
        }
        root.addChildNode(rigStroke(stem, color: color, width: 2.5, depth: 2))
        for (start, end, c1, c2) in [
            ((43.0, 20.0), (28.0, 12.0), (35.0, 9.0), (28.0, 23.0)),
            ((45.0, 17.0), (58.0, 6.0), (46.0, 5.0), (60.0, 17.0))
        ] {
            let blade = Path { path in
                path.move(to: CGPoint(x: start.0, y: start.1))
                path.addQuadCurve(to: CGPoint(x: end.0, y: end.1), control: CGPoint(x: c1.0, y: c1.1))
                path.addQuadCurve(to: CGPoint(x: start.0, y: start.1), control: CGPoint(x: c2.0, y: c2.1))
                path.closeSubpath()
            }
            root.addChildNode(rigShape(blade, color: color, depth: 3, bevel: 1.3))
        }
        return root
    }

    private func addNotebook() {
        let hinge = SCNNode()
        hinge.position = SCNVector3(29, -21, front + 11)
        // The local +Z side is the keyboard and display. It points back
        // toward Ada; the camera sees the outside of the closed surface.
        hinge.eulerAngles.y = -2.04
        accessory.addChildNode(hinge)
        notebook = hinge

        let lid = SCNNode()
        lid.eulerAngles.x = -0.16
        hinge.addChildNode(lid)
        notebookLid = lid
        if notebookArtwork != nil { return }
        let chassis = rigRgb(0.23, 0.22, 0.30)
        let base = SCNBox(width: 28, height: 2.1, length: 15, chamferRadius: 0.8)
        base.materials = [rigMaterial(chassis)]
        let keyboard = SCNNode(geometry: base)
        keyboard.position = SCNVector3(0, -1.15, 7.2)
        hinge.addChildNode(keyboard)

        let key = SCNBox(width: 2.1, height: 0.3, length: 1.5, chamferRadius: 0.12)
        key.materials = [rigMaterial(rigRgb(0.36, 0.35, 0.44))]
        let keybed = SCNNode()
        for row in 0..<3 {
            for column in 0..<7 {
                let node = SCNNode(geometry: key)
                node.position = SCNVector3(Double(column - 3) * 2.7, 0.12, 3.5 + Double(row) * 2.7)
                keybed.addChildNode(node)
            }
        }
        hinge.addChildNode(keybed.flattenedClone())

        lid.addChildNode(Self.prop(x: 34, y: 33, width: 28, height: 16, radius: 3, color: chassis, depth: 3))
        let screen = Self.prop(x: 36, y: 35, width: 24, height: 12, radius: 2,
                               color: rigRgb(0.08, 0.26, 0.22), depth: 0.6)
        screen.position.z = 1.55
        lid.addChildNode(screen)

        let code = Path { path in
            path.move(to: CGPoint(x: 44, y: 39)); path.addLine(to: CGPoint(x: 41, y: 42)); path.addLine(to: CGPoint(x: 44, y: 45))
            path.move(to: CGPoint(x: 50, y: 39)); path.addLine(to: CGPoint(x: 47, y: 45))
            path.move(to: CGPoint(x: 52, y: 39)); path.addLine(to: CGPoint(x: 55, y: 42)); path.addLine(to: CGPoint(x: 52, y: 45))
        }
        let glyph = rigStroke(code, color: rigJade, width: 1.15, depth: 0.5)
        glyph.position.z = 2
        lid.addChildNode(glyph)
        let badge = rigStroke(code, color: rigRgb(0.37, 0.66, 0.55), width: 0.95, depth: 0.4)
        badge.eulerAngles.y = .pi
        badge.position.z = -1.65
        lid.addChildNode(badge)
    }

    func updateEyes(open:Double,joy:Double,gaze:CGSize,wink:Double,anger:Double) {
        if usesIntegratedIllustration, let illustration {
            let horizontal = max(hero == .rita ? 0 : -1.4, min(hero == .rita ? 0.40 : 1.4, gaze.width))
            let vertical = max(-0.5, min(0.5, gaze.height))
            for (index, eye) in eyes.enumerated() {
                guard let region = illustration["eye\(index)"] else { continue }
                let key = "integrated:\(index)"
                if eyeCache[key] == nil { eyeCache[key] = integratedEye(region) }
                eye.geometry = eyeCache[key]
                var opening = max(0.08, min(1.15, open * (index == 1 ? 1 - wink : 1)))
                if hero == .elinor { opening = 0.85 + opening * 0.15 }
                let expression = SCNVector4(opening, hero == .elinor ? 0 : min(1, max(0, joy)), min(1, max(0, anger / 18)), index == 0 ? -1 : 1)
                eye.geometry?.firstMaterial?.setValue(NSValue(scnVector4: expression), forKey: "eyePose")
                eye.scale = SCNVector3(1, 1, 1)
                eye.position = SCNVector3(region.x + horizontal, region.y - vertical, front + 1.4)
            }
            return
        }
        // Blinks and winks scale a persistent mesh. They never tessellate SCNShape
        // or dispose Metal buffers at display frequency. Expressions have 13 × 7
        // bounded variants per eye, independent of blink/open/gaze values.
        let joyStep = min(12, max(0, Int((joy * 12).rounded())))
        let angerStep = min(6, max(0, Int((anger / 3).rounded())))
        let j = Double(joyStep) / 12, a = Double(angerStep) * 3
        let baseHeight = 12.5
        let centers = hero == .sig ? [52.0, 67.0] : [49.0, 66.0]
        for (index, eye) in eyes.enumerated() {
            let paintedEye = illustration?["eye\(index)"]
            let useOriginal = angerStep == 0 && (joyStep == 0 || hero == .elinor)
            let key = "\(index):\(joyStep):\(angerStep)"
            if eyeKeys[index] != key || eye.geometry == nil {
                if eyeCache[key] == nil, let paintedEye, useOriginal {
                    eyeCache[key] = paintedEye.plane()
                }
                if eyeCache[key] == nil {
                    let width = 8.6 + j * 3.5
                    let expressionWidth = paintedEye.map { $0.width * (1 + j * 0.28) } ?? width
                    let expressionHeight = paintedEye?.height ?? baseHeight
                    let rect = CGRect(x: 48-expressionWidth/2, y: 48-expressionHeight/2,
                                      width: expressionWidth, height: expressionHeight)
                    var path = rigEyePath(rect: rect, joy: j)
                    if hero == .elinor && j < 0.25 {
                        path = rigEyePath(rect: rect, joy: 0.92)
                            .applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 96))
                    }
                    if a > 2 {
                        let drop = rect.height * 0.30 * a / 18
                        var cut = Path(); cut.move(to:CGPoint(x:rect.minX,y:rect.minY+(index == 0 ? 0 : drop)))
                        cut.addLine(to:CGPoint(x:rect.maxX,y:rect.minY+(index == 0 ? drop : 0)))
                        cut.addLine(to:CGPoint(x:rect.maxX,y:rect.midY))
                        cut.addCurve(to:CGPoint(x:rect.midX,y:rect.maxY),control1:CGPoint(x:rect.maxX,y:rect.maxY),control2:CGPoint(x:rect.midX+rect.width/3,y:rect.maxY))
                        cut.addCurve(to:CGPoint(x:rect.minX,y:rect.midY),control1:CGPoint(x:rect.midX-rect.width/3,y:rect.maxY),control2:CGPoint(x:rect.minX,y:rect.maxY)); cut.closeSubpath(); path = cut
                    }
                    let light = rigRgb(1, 0.98, 0.92)
                    let shade = rigRgb(0.88, 0.82, 0.71)
                    if paintedEye != nil, let expression = CompanionIllustration.paint(path, light: light, shade: shade) {
                        eyeCache[key] = expression
                    } else {
                        let geometry = SCNShape(path: rigNsPath(path), extrusionDepth: 0.9)
                        geometry.chamferRadius = 0.7
                        geometry.materials = [eyeMaterial]
                        eyeCache[key] = geometry
                    }
                }
                eye.geometry = eyeCache[key]; eyeKeys[index] = key
            }
            eye.scale.y = CGFloat(max(1.8/baseHeight, open * (index == 1 ? 1-wink : 1)))
            let behindGlasses = paintedEye != nil && hero == .rita
            let horizontal = behindGlasses ? max(-1, min(2.6, gaze.width)) : gaze.width
            let vertical = behindGlasses ? max(-1.7, min(1.7, gaze.height)) : gaze.height
            eye.position.x = (paintedEye?.x ?? centers[index] - 48) + horizontal
            eye.position.y = (paintedEye?.y ?? 2) - vertical
            eye.eulerAngles.z = 0
        }
    }

    private func integratedEye(_ region: CompanionIllustration.Part) -> SCNPlane {
        let plane = region.plane()
        plane.widthSegmentCount = 32
        plane.heightSegmentCount = 32
        guard let material = plane.firstMaterial else { return plane }
        material.setValue(NSValue(scnVector4: SCNVector4(1, 0, 0, 0)), forKey: "eyePose")
        material.setValue(NSValue(scnVector4: SCNVector4(region.width / 2, region.height / 2, 0, 0)), forKey: "eyeSize")
        // The eye paint comes from the complete portrait at its original
        // location. Chroma coverage excludes the surrounding face and frame;
        // only this small eye mesh bends, never the wearable or its shadow.
        material.shaderModifiers = [.geometry: """
        #pragma arguments
        float4 eyePose;
        float4 eyeSize;
        #pragma body
        float x = clamp(_geometry.position.x / eyeSize.x, -1.0, 1.0);
        float joy = eyePose.y;
        _geometry.position.y *= eyePose.x * (1.0 - joy * 0.72);
        _geometry.position.y += joy * eyeSize.y * 0.48 * (1.0 - x*x);
        _geometry.position.y += eyePose.z * eyePose.w * _geometry.position.x * 0.22;
        """, .fragment: """
        #pragma transparent
        #pragma body
        float3 paint = _surface.diffuse.rgb;
        float cream = smoothstep(0.22, 0.52, min(paint.r, paint.g));
        cream *= 1.0 - smoothstep(0.0, 0.08, paint.b - paint.g);
        _output.color *= cream;
        """]
        return plane
    }

    private func configurePaintedSurface(_ art: CompanionIllustration, origin: CompanionIllustration.Part) {
        guard let material = paintedSurface else { return }
        if let coverage = art["coverage"] {
            // Keep the generated RGBA art intact. Its matching silhouette mask
            // controls coverage independently of white-matte residue at edges.
            material.transparent.contents = coverage.image
            material.transparencyMode = .rgbZero
        }
        let prop = art["gesture"]
        material.setValue(NSValue(scnVector4: SCNVector4((prop?.x ?? 0) - origin.x, (prop?.y ?? 0) - origin.y, (prop?.width ?? 40) / 2, (prop?.height ?? 30) / 2)), forKey: "propRegion")
        material.setValue(NSValue(scnVector4: SCNVector4(0, 0, 0, 0)), forKey: "propPose")
        material.shaderModifiers = [.geometry: """
        #pragma arguments
        float4 propRegion;
        float4 propPose;
        #pragma body
        float2 original = _geometry.position.xy;
        float2 displacement = float2(0.0);
        // A small anchored flex gives the book/calendar/folder follow-through
        // without separating its painted contact edge from the body.
        float2 propLocal = (original - propRegion.xy) / max(propRegion.zw, float2(1.0));
        float propWeight = (1.0 - smoothstep(0.65, 1.15, abs(propLocal.x))) * (1.0 - smoothstep(0.65, 1.15, abs(propLocal.y)));
        displacement.x += propWeight * propPose.x * propLocal.y * 1.1;
        displacement.y += propWeight * propPose.x * 1.5;
        _geometry.position.xy += displacement;
        """]
    }

    func updateIllustratedGesture(fold: Double) {
        paintedSurface?.setValue(NSValue(scnVector4: SCNVector4(max(-1, min(1, fold)), 0, 0, 0)), forKey: "propPose")
    }
}
