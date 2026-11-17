import AppKit
import SwiftUI
import Metal

@main enum ClimateRender {
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let out=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
        try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
        precondition(NSImage(named:"Companion-sig-weather-hand-left") != nil, "Missing production hand artwork")
        precondition(CompanionRigModel(.sig).usesIllustration, "Render validation requires the production illustration catalog")
        try verifyFreezing(out)
        let specs:[(CompanionWeatherMood,Double,Int)]=[(.frozen,-16,0),(.cold,10,0),(.comfortable,22,0),(.hot,33,0),(.rain,22,61),(.snow,-2,71),(.storm,19,95),(.hail,17,96),(.cloudy,22,3)]
        for (mood,temp,code) in specs {
            let observation=VoiceWeatherObservation(location:"Local de demonstração",temperature:temp,feelsLike:temp,date:Date(timeIntervalSince1970:1794000000),timezone:"America/Recife",code:code,isDay:true)
            let directory=out.appendingPathComponent(mood.rawValue,isDirectory:true)
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            for (theme,scheme) in [("claro",ColorScheme.light),("escuro",.dark)] {
                let view=CompanionWeatherScene(observation:observation,language:"pt-BR",animates:false,previewTime:(mood == .frozen || mood == .snow ? 10.5 : 2.65)).frame(width:610).environment(\.colorScheme,scheme)
                let renderer=ImageRenderer(content:view);renderer.scale=2
                try save(renderer.nsImage!,out.appendingPathComponent("card-\(mood.rawValue)-\(theme).png"))
            }
            for (i,t) in [0.0,1.3,2.65,4.0,7.0,11.0].enumerated() {
                let image=CompanionWeatherCharacter.snapshot(mood:mood,time:t,size:CGSize(width:288,height:288),intensity:.init(mood:mood,temperature:temp))
                try save(image,out.appendingPathComponent("\(mood.rawValue)-\(i).png"))
            }
            for frame in 0..<(CommandLine.arguments.contains("--stills") ? 0 : 288) {
                let t=Double(frame)/24
                let view=CompanionWeatherScene(observation:observation,language:"pt-BR",animates:false,previewTime:t)
                    .frame(width:610).environment(\.colorScheme,.dark)
                let renderer=ImageRenderer(content:view)
                renderer.scale=1
                guard let image=renderer.nsImage else { fatalError("No card") }
                try save(image,directory.appendingPathComponent(String(format:"%03d.png",frame)))
            }
            print("PASS: \(mood.rawValue), \(CommandLine.arguments.contains("--stills") ? 0 : 288) sequence frames, light/dark and six gesture phases")
        }
        for temp in [-16.0,-4,4,14,22,29,33,42] {
            let observation=VoiceWeatherObservation(location:"Temperatura de teste",temperature:temp,feelsLike:temp,date:Date(timeIntervalSince1970:1794000000),timezone:"America/Recife",code:0,isDay:true)
            let view=CompanionWeatherScene(observation:observation,language:"pt-BR",animates:false,previewTime:1.4).frame(width:610).environment(\.colorScheme,.dark)
            let renderer=ImageRenderer(content:view);renderer.scale=1
            try save(renderer.nsImage!,out.appendingPathComponent("temperature-\(Int(temp)).png"))
        }
    }
    /// This pixel check runs in the isolated render bundle containing Assets.car.
    /// The hostless contract test target intentionally has no app artwork.
    @MainActor static func verifyFreezing(_ out:URL) throws {
        func count(_ time:Double)->(ice:Int,eyes:Int) {
            let image=CompanionWeatherCharacter.snapshot(mood:.frozen,time:time,size:CGSize(width:128,height:128),intensity:.init(mood:.frozen,temperature:-16))
            let cg=image.cgImage(forProposedRect:nil,context:nil,hints:nil)!
            let bitmap=NSBitmapImageRep(cgImage:cg)
            var ice=0,eyes=0
            for y in stride(from:0,to:bitmap.pixelsHigh,by:2) {
                for x in stride(from:0,to:bitmap.pixelsWide,by:2) {
                    guard let c=bitmap.colorAt(x:x,y:y)?.usingColorSpace(.deviceRGB),c.alphaComponent>0.8 else {continue}
                    if c.blueComponent-c.redComponent>0.09 && c.greenComponent>c.redComponent {ice+=1}
                    if c.redComponent>0.8 && c.greenComponent>0.7 && c.redComponent-c.blueComponent>0.05 {eyes+=1}
                }
            }
            return (ice,eyes)
        }
        let before=count(0),after=count(10)
        precondition(after.ice>before.ice+200, "Frozen body did not gain icy pixels: \(before.ice) -> \(after.ice)")
        precondition(before.eyes>40 && after.eyes>40, "Cream eyes disappeared during freezing")
        let record:[String:Any] = ["productionArtwork":true,"iceBefore":before.ice,"iceAfter":after.ice,"creamBefore":before.eyes,"creamAfter":after.eyes,"temperature":-16,"times":[0,10]]
        try JSONSerialization.data(withJSONObject:record,options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("freezing-check.json"))
        print("PASS: production freezing pixels \(before.ice) -> \(after.ice); cream eyes \(before.eyes) -> \(after.eyes)")
    }
    @MainActor static func save(_ image:NSImage,_ url:URL) throws {
        let cg=image.cgImage(forProposedRect:nil,context:nil,hints:nil)!
        try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:url)
    }
}
