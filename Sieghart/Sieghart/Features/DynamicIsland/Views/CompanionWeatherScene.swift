import AppKit
import SwiftUI

enum CompanionWeatherMood: String, CaseIterable, Sendable {
    case frozen, cold, comfortable, hot, rain, snow, storm, hail, cloudy
    static func resolve(_ weather: VoiceWeatherObservation) -> Self {
        // Preserve the actual precipitation, even below zero. Surface freezing
        // is an independent input to the character, never inferred snowfall.
        switch weather.code ?? -1 {
        case 96, 99: return .hail
        case 95, 97: return .storm
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        default:
            if weather.temperature < 0 { return .frozen }
            if weather.feelsLike < 16 { return .cold }
            if weather.feelsLike >= 28 { return .hot }
            return [2, 3, 45, 48].contains(weather.code ?? -1) ? .cloudy : .comfortable
        }
    }

    var tint: Color {
        switch self {
        case .frozen, .cold, .snow: Color(red: 0.46, green: 0.80, blue: 1)
        case .rain, .storm, .hail: Color(red: 0.48, green: 0.62, blue: 0.92)
        case .hot: Color(red: 1, green: 0.69, blue: 0.28)
        case .cloudy: Color(red: 0.65, green: 0.75, blue: 0.85)
        case .comfortable: Color(red: 0.64, green: 0.85, blue: 0.67)
        }
    }
    func caption(english: Bool) -> String {
        switch self {
        case .frozen: english ? "Even my code is freezing." : "Tá frio até no meu código."
        case .cold: english ? "Scarf ready. Where's the hot chocolate?" : "Cachecol pronto. Cadê o chocolate quente?"
        case .hot: english ? "Who turned the sun all the way up?" : "Quem colocou o sol no máximo?"
        case .rain: english ? "A tiny companion. A very big raincloud." : "Um companheiro pequeno. Uma chuva enorme."
        case .snow: english ? "Pretty snow. Very cold little face." : "Neve bonita. Carinha congelando."
        case .storm: english ? "I'll just stay right here with you." : "Vou ficar bem aqui, pertinho de você."
        case .hail: english ? "That cloud brought ice. I brought a small head." : "A nuvem trouxe gelo. Eu trouxe uma cabecinha."
        case .cloudy: english ? "A little shade. A slower kind of day." : "Uma sombra boa. Um dia mais devagar."
        case .comfortable: english ? "My kind of operating temperature." : "Minha temperatura ideal de funcionamento."
        }
    }
}

/// The result takes over the Companion surface. All values and the scene come
/// from the same observation, independent of the city or the request's wording.
struct CompanionWeatherScene: View {
    static let height: CGFloat = 292
    let observation: VoiceWeatherObservation
    let language: String
    let animates: Bool
    var stop: (() -> Void)? = nil
    var previewTime: Double? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.islandPreview) private var preview
    @Environment(\.islandReduceMotion) private var islandReduceMotion
    @Environment(\.companionMotionEnabled) private var motionEnabled
    @State private var visible = false
    @State private var presented = false
    @State private var clock = WeatherPanelClock()
    private var en: Bool { language.hasPrefix("en") }
    private var mood: CompanionWeatherMood { .resolve(observation) }
    private var updateTime: String {
        let formatter = DateFormatter(); formatter.timeZone = TimeZone(identifier: observation.timezone)
        formatter.dateFormat = "HH:mm"; return formatter.string(from: observation.date)
    }
    private var moves: Bool {
        animates && motionEnabled && !reduceMotion && !islandReduceMotion && !preview && previewTime == nil && visible && presented
    }
    private var freezing: Bool { observation.temperature < 0 }
    private var chilly: Bool { freezing || observation.feelsLike < 16 }
    private var thermal:CompanionWeatherIntensity { CompanionWeatherIntensity(mood:mood,temperature:observation.temperature,feelsLike:observation.feelsLike) }
    private var heat: Double { min(1, max(0, (observation.feelsLike - 16) / 22)) }
    private var cloudAmount: Double {
        switch observation.code ?? -1 {
        case 3, 45, 48: 1
        case 2: 0.65
        case 1: 0.25
        case 51...99: 0.85
        default: 0
        }
    }
    private var condition: String {
        mood == .hail ? (en ? "Thunderstorm with hail" : "Trovoada com granizo") : observation.condition(language: language)
    }
    var body: some View {
        // Forecast metadata is stable during display ticks. In particular, do
        // not allocate a DateFormatter at the atmosphere's 30 Hz cadence.
        let timestamp = updateTime
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !moves)) { timeline in
            let time = previewTime.map { $0.isFinite ? max(0, $0) : 0 } ?? clock.time(at: timeline.date)
            ZStack {
                RoundedRectangle(cornerRadius:26).fill(colorScheme == .dark ? Color(red:0.075,green:0.09,blue:0.115) : Color(red:0.96,green:0.97,blue:0.98))
                RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [mood.tint.opacity(0.23), colorScheme == .dark ? Color.black.opacity(0.20) : Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                atmosphere(time: time, foreground: false).allowsHitTesting(false)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(en ? "Weather with Chomp" : "O tempo com o Chomp", systemImage: mood == .hail ? "cloud.hail.fill" : observation.symbol)
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(colorScheme == .dark ? mood.tint : Color.primary.opacity(0.72))
                        Spacer()
                        if let stop { Button(action: stop) { Image(systemName: "stop.circle") }.help(en ? "Stop speaking" : "Parar fala").padding(.trailing, 76) }
                        else { Color.clear.frame(width: 88, height: 24) }
                    }
                    HStack(spacing: 20) {
                        character.frame(width: 154, height: 156)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(observation.location).font(.system(size: 13, weight: .medium)).lineLimit(2).padding(.trailing, 60)
                            Text("\(Int(observation.temperature.rounded()))°").font(.system(size: 60, weight: .light, design: .rounded)).monospacedDigit()
                            Text(condition).font(.callout)
                            Text(en ? "Feels like \(Int(observation.feelsLike.rounded()))°C" : "Sensação de \(Int(observation.feelsLike.rounded()))°C")
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(observation.regionEstimate ? (en ? "Regional reference · conditions vary locally" : "Referência regional · varia conforme a cidade") : mood.caption(english: en)).font(.callout.weight(.medium)).lineLimit(2)
                    HStack {
                        Text("Open-Meteo · \(en ? "Estimate" : "Estimativa")").font(.system(size: 10))
                        Spacer()
                        Text(timestamp)
                            .font(.system(size: 10)).monospacedDigit()
                        Text(en ? "local · °C" : "local · °C").font(.system(size: 10))
                    }.foregroundStyle(.secondary)
                }.padding(20)
                atmosphere(time: time, foreground: true).allowsHitTesting(false)
            }.clipShape(RoundedRectangle(cornerRadius: 26)).foregroundStyle(.primary).buttonStyle(.plain)
        }.frame(height: Self.height)
            // Native visibility is absent from ImageRenderer exports; an unsupported
            // NSView in their background would draw a placeholder over the panel.
            .background {
                if !preview && previewTime == nil { WeatherPanelVisibility { visible = $0 } }
            }
            .onAppear { presented = true }
            .onDisappear { presented = false; clock.setPlaying(false) }
            .onChange(of: mood) { _, _ in clock.restart(playing:moves) }
            .onChange(of: moves, initial: true) { _, playing in clock.setPlaying(playing) }
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(mood.tint.opacity(0.25)))
    }
    private var character: some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(mood.tint.opacity(wet ? 0.12 : 0.08))
                .frame(width: 112, height: 7).blur(radius: 5).offset(y: -12)
            CompanionWeatherCharacter(mood: mood, animates: moves, previewTime: previewTime, freezing: freezing, temperature:observation.temperature, feelsLike:observation.feelsLike, animationClock:clock)
        }.accessibilityLabel(mood.caption(english: en))
    }
    private var wet: Bool { mood == .rain || mood == .storm || mood == .hail }
    private var snowy: Bool { mood == .snow }

    /// Painted atmosphere and deterministic depth layers share the character's clock.
    /// Clear space behind the reading protects text without cutting weather at a box edge.
    private func atmosphere(time: Double, foreground: Bool) -> some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let beat = WeatherChoreography.sample(time: time)
            let bounds = CGRect(origin: .zero, size: size)
            if !foreground {
                let light = CGPoint(x: size.width * 0.85, y: -20)
                let tint = wet ? Color(red: 0.37, green: 0.49, blue: 0.72) : mood.tint
                context.fill(Path(bounds), with: .radialGradient(Gradient(colors: [tint.opacity(0.24), .clear]), center: light, startRadius: 0, endRadius: size.width * 0.95))
                if !wet && !snowy { celestial(context: context, size: size, time: time) }
                if cloudAmount > 0 { paintedClouds(context: context, size: size, time: time, foreground: false) }
                if chilly { coldAir(context: context, size: size, time: time) }
                if mood == .hot { heatWaves(context: context, size: size, time: time) }
                if observation.isDay && !wet && !snowy { sunbeams(context: context, size: size, time: time) }
                if wet {
                    context.fill(Path(bounds), with: .linearGradient(Gradient(colors: [.clear, Color(red: 0.1, green: 0.2, blue: 0.32).opacity(colorScheme == .dark ? 0.25 : 0.08)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                }
            }
            if mood == .storm || mood == .hail {
                lightning(context: context, size: size, time: time, flash: beat.flash, foreground: foreground)
            }
            if wet || snowy { precipitation(context: context, size: size, time: time, foreground: foreground) }
            if mood == .hail { hail(context: context, size: size, time: time, foreground: foreground) }
            if foreground {
                if snowy { snowGround(context: context, size: size, time: time) }
                if freezing { frostEdges(context: context, size: size, time: time) }
                if wet { waterOnGlass(context: context, size: size, time: time) }
            }
        }.accessibilityHidden(true)
    }

    private func sprite(_ name: String, context: GraphicsContext, rect: CGRect, opacity: Double = 1, angle: Double = 0) {
        var layer = context
        layer.opacity = opacity
        layer.translateBy(x: rect.midX, y: rect.midY)
        layer.rotate(by: .radians(angle))
        layer.draw(Image("Weather-\(name)"), in: CGRect(x: -rect.width/2, y: -rect.height/2, width: rect.width, height: rect.height))
    }

    private func celestial(context: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width - 52, y: 42)
        let energy = 1 + sin(time * 0.65) * 0.025
        if observation.isDay {
            let r = (mood == .hot ? 30.0 : 25.0) * energy
            let halo = Color(red: 1, green: 0.73, blue: 0.32)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(Gradient(colors: [halo.opacity(0.19 + thermal.hot*0.13), .clear]), center: center, startRadius: r, endRadius: 190))
            sprite("sun", context: context, rect: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2), opacity: 0.96)
            for i in 0..<12 {
                let a = Double(i) * .pi/6 + time*0.025
                let inner = r+6, outer = r+10+thermal.hot*3
                var ray = Path(); ray.move(to: CGPoint(x: center.x+cos(a)*inner, y: center.y+sin(a)*inner))
                ray.addLine(to: CGPoint(x: center.x+cos(a)*outer, y: center.y+sin(a)*outer))
                context.stroke(ray, with: .color(halo.opacity(0.32)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            }
        } else {
            let r = 23.0
            var moon = Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2))
            moon.addEllipse(in: CGRect(x: center.x-10, y: center.y-30, width: r*2, height: r*2))
            var layer = context
            layer.clip(to: Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)))
            layer.fill(moon, with: .radialGradient(Gradient(colors: [.white, Color(red: 0.63, green: 0.75, blue: 0.92)]), center: CGPoint(x: center.x-12, y: center.y-15), startRadius: 0, endRadius: 48), style: FillStyle(eoFill: true))
            for i in 0..<15 {
                let seed = Double(i), x = 20 + fract(seed*0.618)*size.width
                let y = 8 + fract(seed*0.397)*size.height
                let a = (0.25 + pow(sin(time*0.4+seed),2)*0.4)*weatherVisibility(x:x,y:y,size:size)
                context.fill(Path(ellipseIn: CGRect(x:x,y:y,width:1.5,height:1.5)), with:.color(.white.opacity(a)))
            }
        }
    }

    private func paintedClouds(context: GraphicsContext, size: CGSize, time: Double, foreground: Bool) {
        let name = snowy ? "snow-cloud" : wet ? "storm" : "cloud"
        let gust = WeatherChoreography.sample(time: time).gust
        // Independent, slow paths have no visible wrap boundary.
        for i in 0..<3 {
            let seed = Double(i)
            let width = [250.0, 205, 178][i]
            let x = [size.width-165, size.width*0.40-80, -100][i] + sin(time*(0.13+seed*0.018)+seed*2.1)*(15+seed*4) - gust*5
            let y = [-35.0, -66, -55][i] + sin(time*0.19+seed)*4
            sprite(name, context: context, rect: CGRect(x:x,y:y,width:width,height:width*0.59), opacity: [0.82,0.30,0.22][i]*cloudAmount)
        }
        // Low distant veil moves behind the character and reading, never over the face.
        var veil = context; veil.addFilter(.blur(radius: 12)); veil.opacity = 0.10*cloudAmount
        sprite(name, context: veil, rect: CGRect(x:size.width*0.50+sin(time*0.12)*25,y:size.height-75,width:310,height:140))
    }

    private func sunbeams(context: GraphicsContext, size: CGSize, time: Double) {
        let source = CGPoint(x:size.width-52,y:25)
        for i in 0..<3 {
            let seed=Double(i), spread=25+sin(time*0.17+seed)*12
            let endX=size.width*(0.10+seed*0.29)+sin(time*0.12)*24
            var p=Path();p.move(to:source)
            p.addLine(to:CGPoint(x:endX-spread,y:size.height+40));p.addLine(to:CGPoint(x:endX+spread,y:size.height+40));p.closeSubpath()
            var glow=context;glow.addFilter(.blur(radius:14))
            glow.fill(p,with:.linearGradient(Gradient(colors:[Color(red:1,green:0.86,blue:0.55).opacity(mood == .hot ? 0.18 : 0.055),.clear]),startPoint:source,endPoint:CGPoint(x:endX,y:size.height)))
        }
    }

    private func weatherVisibility(x: Double, y: Double, size: CGSize) -> Double {
        let reading = rigSmooth((x-165)/45) * (1-rigSmooth((x-(size.width-92))/52))
        let rows = rigSmooth((y-58)/24) * (1-rigSmooth((y-194)/25))
        let footer = rigSmooth((y-217)/15) * (1-rigSmooth((y-263)/18))
        return (1-reading*rows*0.83)*(1-footer*0.75)
    }

    private func precipitation(context: GraphicsContext, size: CGSize, time: Double, foreground: Bool) {
        let count = snowy ? (foreground ? 19 : 42) : (foreground ? 38 : 70)
        let gust = WeatherChoreography.sample(time:time).gust
        for i in 0..<count {
            let seed=Double(i+(foreground ? 113 : 0)), depth=0.35+fract(seed*0.371)*0.65
            let speed=snowy ? 16+depth*22 : 180+depth*150
            let cycle=fract(time*speed/(size.height+60)+seed*0.719)
            let y = -30+cycle*(size.height+60)
            let base=fract(seed*0.61803398875)*(size.width+120)
            let drift=snowy ? sin(time*0.8+seed)*12+gust*20 : -y*(0.13+gust*0.14)
            let x=fract((base+drift+60)/(size.width+120))*(size.width+120)-60
            let alpha=weatherVisibility(x:x,y:y,size:size)*(foreground ? 0.65 : 0.30)
            if snowy {
                let r=(foreground ? 2.6 : 1.5)*depth
                var flake=context
                if foreground && depth>0.8 { flake.addFilter(.blur(radius:0.55)) }
                flake.fill(Path(ellipseIn:CGRect(x:x-r,y:y-r,width:r*2,height:r*2)),with:.radialGradient(Gradient(colors:[.white.opacity(alpha),Color(red:0.75,green:0.88,blue:1).opacity(alpha*0.2)]),center:CGPoint(x:x-r*0.25,y:y-r*0.25),startRadius:0,endRadius:r*1.5))
                if foreground && i%5==0 {
                    var crystal=Path()
                    for j in 0..<3 {
                        let angle=Double(j)*Double.pi/3+time*0.2+seed
                        crystal.move(to:CGPoint(x:x-cos(angle)*r*1.6,y:y-sin(angle)*r*1.6));crystal.addLine(to:CGPoint(x:x+cos(angle)*r*1.6,y:y+sin(angle)*r*1.6))
                    }
                    flake.stroke(crystal,with:.color(.white.opacity(alpha*0.75)),lineWidth:0.7)
                }
            } else {
                let len=10+depth*(foreground ? 18 : 12), dx=len*(0.13+gust*0.14)
                var drop=Path();drop.move(to:CGPoint(x:x+dx,y:y-len));drop.addLine(to:CGPoint(x:x,y:y))
                context.stroke(drop,with:.linearGradient(Gradient(colors:[.clear,Color(red:0.65,green:0.83,blue:1).opacity(alpha*0.72)]),startPoint:CGPoint(x:x+dx,y:y-len),endPoint:CGPoint(x:x,y:y)),style:StrokeStyle(lineWidth:foreground ? 0.9+depth*0.5 : 0.65,lineCap:.round))
            }
        }
        if wet && foreground {
            for i in 0..<18 {
                let seed=Double(i), p=fract(time*(1.15+fract(seed*0.31))+seed*0.319)
                let x=12+fract(seed*0.618)*(size.width-24), y=size.height-8-fract(seed*0.37)*9
                let r=2+p*10
                var ripple=Path(ellipseIn:CGRect(x:x-r,y:y-r*0.15,width:r*2,height:r*0.3))
                ripple.move(to:CGPoint(x:x,y:y));ripple.addQuadCurve(to:CGPoint(x:x+4*p,y:y),control:CGPoint(x:x+3*p,y:y-9*sin(p * .pi)))
                context.stroke(ripple,with:.color(Color(red:0.67,green:0.84,blue:1).opacity(pow(1-p,2)*0.35)),lineWidth:0.75)
            }
        }
    }

    private func lightning(context: GraphicsContext, size: CGSize, time: Double, flash: Double, foreground: Bool) {
        guard flash>0.001 else { return }
        if foreground {
            context.fill(Path(CGRect(origin:.zero,size:size)),with:.radialGradient(Gradient(colors:[Color(red:0.82,green:0.87,blue:1).opacity(flash*0.22),.clear]),center:CGPoint(x:size.width-80,y:0),startRadius:0,endRadius:size.width*0.9))
            return
        }
        let x=size.width-75
        var bolt=Path();bolt.move(to:CGPoint(x:x,y:45));bolt.addLine(to:CGPoint(x:x-17,y:82));bolt.addLine(to:CGPoint(x:x-3,y:78));bolt.addLine(to:CGPoint(x:x-30,y:126))
        var glow=context;glow.addFilter(.blur(radius:5))
        glow.stroke(bolt,with:.color(Color(red:0.62,green:0.72,blue:1).opacity(flash*0.7)),style:StrokeStyle(lineWidth:8,lineCap:.round,lineJoin:.round))
        context.stroke(bolt,with:.color(Color(red:0.9,green:0.94,blue:1).opacity(flash)),style:StrokeStyle(lineWidth:1.5,lineCap:.round,lineJoin:.round))
    }

    private func coldAir(context: GraphicsContext, size: CGSize, time: Double) {
        let gust=WeatherChoreography.sample(time:time).gust
        for i in 0..<3 {
            let seed=Double(i), y=110+seed*75
            let x = -180+sin(time*0.19+seed*2)*70+gust*50
            var mist=context;mist.addFilter(.blur(radius:18))
            mist.fill(Path(ellipseIn:CGRect(x:x,y:y,width:size.width+140,height:28)),with:.color(Color(red:0.72,green:0.87,blue:0.96).opacity((0.035+thermal.cold*0.06)*(0.5+gust))))
        }
        if freezing {
            context.fill(Path(CGRect(origin:.zero,size:size)),with:.radialGradient(Gradient(colors:[.clear,Color(red:0.45,green:0.76,blue:0.95).opacity(0.12+thermal.frost*0.12)]),center:CGPoint(x:size.width*0.48,y:size.height*0.48),startRadius:100,endRadius:size.width*0.6))
        }
    }

    private func frostEdges(context: GraphicsContext, size: CGSize, time: Double) {
        let growth=rigSmooth(time/7)*(0.45+thermal.frost*0.55)
        // Crystalline silhouettes grow from the actual card boundary.
        for side in 0..<2 {
            for i in 0..<3 {
                let progress=rigSmooth((time-Double(i)*1.2)/5.8)
                let height=(31+Double(i%2)*12)*growth*progress
                let y=35+Double(i)*92
                var layer=context
                layer.translateBy(x:side==0 ? -2 : size.width+2,y:y)
                layer.rotate(by:.degrees(side==0 ? 90 : -90))
                sprite("frost",context:layer,rect:CGRect(x:-46,y:-height,width:92,height:height),opacity:0.4+growth*0.48)
            }
        }
        for i in 0..<4 {
            let h=(i%2==0 ? 30.0 : 19.0)*growth
            sprite("frost",context:context,rect:CGRect(x:Double(i)*size.width/3-42,y:size.height-h+5,width:125,height:h),opacity:0.65)
        }
    }

    private func snowGround(context: GraphicsContext, size: CGSize, time: Double) {
        let growth=rigSmooth(time/9)
        for i in 0..<3 {
            let w=size.width*0.5
            sprite("snow-bank",context:context,rect:CGRect(x:Double(i)*size.width*0.4-45,y:size.height-8-growth*12,width:w,height:18+growth*18),opacity:0.8)
        }
    }

    private func heatWaves(context: GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<4 {
            let seed=Double(i), travel=fract(time*(0.11+thermal.hot*0.06)+seed*0.251)
            let x=35+seed*size.width/3+sin(time*0.6+seed)*12, y=size.height*(1.2-travel*1.4)
            let w=55+sin(time*0.7+seed)*15
            var heat=context;heat.addFilter(.blur(radius:15))
            heat.fill(Path(ellipseIn:CGRect(x:x-w/2,y:y-60,width:w,height:120)),with:.linearGradient(Gradient(colors:[.clear,Color(red:1,green:0.65,blue:0.22).opacity(sin(travel * .pi)*(0.10+thermal.hot*0.18)),.clear]),startPoint:CGPoint(x:x,y:y-60),endPoint:CGPoint(x:x,y:y+60)))
        }
    }

    private func waterOnGlass(context: GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<8 {
            let seed=Double(i), cycle=fract(time*0.085+seed*0.197)
            let x = i%2==0 ? 5+fract(seed*0.37)*12 : size.width-6-fract(seed*0.37)*13
            let y = 30+cycle*(size.height-60), r=1.3+fract(seed*0.43)*1.6
            let opacity=sin(cycle * .pi)*0.35
            let p=Path(ellipseIn:CGRect(x:x-r,y:y-r*1.5,width:r*2,height:r*3))
            context.fill(p,with:.linearGradient(Gradient(colors:[.white.opacity(opacity),Color(red:0.41,green:0.65,blue:0.85).opacity(opacity*0.35)]),startPoint:CGPoint(x:x-r,y:y-r),endPoint:CGPoint(x:x+r,y:y+r)))
        }
    }

    private func hail(context: GraphicsContext, size: CGSize, time: Double, foreground: Bool) {
        for i in 0..<(foreground ? 15 : 22) {
            let seed=Double(i+(foreground ? 31 : 0)), depth=0.55+fract(seed*0.371)*0.45
            let phase=fract(time/(1.1+depth*0.7)+seed*0.137)
            let fall=min(1,phase/0.72), bounce=max(0,(phase-0.72)/0.28)
            let baseX=fract(seed*0.618)*size.width
            let x=baseX+fall*20+bounce*15
            let y=phase<0.72 ? -14+fall*fall*(size.height+4) : size.height-10-sin(bounce * .pi)*(16+depth*14)
            let r=(foreground ? 3.1 : 1.9)*depth
            let a=weatherVisibility(x:x,y:y,size:size)*(1-bounce)*(foreground ? 0.9 : 0.4)
            context.fill(Path(ellipseIn:CGRect(x:x-r,y:y-r,width:2*r,height:2*r)),with:.radialGradient(Gradient(colors:[.white.opacity(a),Color(red:0.51,green:0.73,blue:0.87).opacity(a)]),center:CGPoint(x:x-r*0.4,y:y-r*0.4),startRadius:0,endRadius:2*r))
        }
    }
    private func fract(_ x: Double) -> Double { x-floor(x) }
}

struct WeatherPanelClock: Sendable {
    private var started: Date?
    private var elapsed = 0.0
    func time(at date: Date) -> Double { elapsed + (started.map { max(0,date.timeIntervalSince($0)) } ?? 0) }
    mutating func restart(playing:Bool) { elapsed=0; started=playing ? Date() : nil }
    mutating func setPlaying(_ playing: Bool) {
        if playing, started == nil { started = Date() }
        else if !playing, let start = started { elapsed += max(0,Date().timeIntervalSince(start)); started = nil }
    }
}

/// Window events gate the Canvas schedule too. No new polling timer; the native
/// character retains its existing renderer visibility safeguards independently.
private struct WeatherPanelVisibility: NSViewRepresentable {
    var changed: (Bool) -> Void
    func makeNSView(context: Context) -> VisibilityView { let view = VisibilityView(); view.changed = changed; return view }
    func updateNSView(_ view: VisibilityView, context: Context) { view.changed = changed }
    static func dismantleNSView(_ view: VisibilityView, coordinator: ()) { view.stop() }
    final class VisibilityView: NSView {
        var changed: ((Bool) -> Void)?
        private var observers: [NSObjectProtocol] = []
        private var last: Bool?
        private var generation = 0
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override var isHidden: Bool { didSet { publish() } }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); removeObservers()
            let generation = self.generation
            if let window {
                for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                             NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification] {
                    observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] note in
                        let closing = note.name == NSWindow.willCloseNotification
                        Task { @MainActor [weak self] in
                            guard let self, self.generation == generation else { return }
                            self.publish(closing: closing)
                        }
                    })
                }
            }
            publish()
        }
        private func publish(closing: Bool = false) {
            let visible = !closing && !isHiddenOrHasHiddenAncestor && (window.map { $0.isVisible && !$0.isMiniaturized && $0.occlusionState.contains(.visible) } ?? false)
            guard visible != last else { return }; last = visible
            Task { @MainActor [weak self] in
                guard let self, self.last == visible else { return }
                self.changed?(visible)
            }
        }
        func stop() { changed = nil; removeObservers() }
        private func removeObservers() { generation += 1; observers.forEach { NotificationCenter.default.removeObserver($0) }; observers.removeAll() }
        isolated deinit { removeObservers() }
    }
}
