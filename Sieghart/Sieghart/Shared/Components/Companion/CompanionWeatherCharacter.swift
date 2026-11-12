import AppKit
import Metal
@preconcurrency import SceneKit
import SwiftUI

/// Weather changes the approved Sig rig, including its face and attached cloth.
/// The surrounding weather scene owns precipitation, captions and the forecast.
/// Temperature changes the intensity of the performance, independently of the
/// precipitation code. A snowy -2°C day and -14°C cold therefore stay distinct.
struct CompanionWeatherIntensity: Sendable, Equatable {
    let temperature: Double
    let feelsLike: Double
    init(mood:CompanionWeatherMood,temperature:Double?=nil,feelsLike:Double?=nil) {
        let nominal:Double = switch mood { case .frozen:-4; case .cold:10; case .hot:33; case .snow:-2; default:22 }
        self.temperature=temperature.flatMap { $0.isFinite ? $0 : nil } ?? nominal
        self.feelsLike=feelsLike.flatMap { $0.isFinite ? $0 : nil } ?? self.temperature
    }
    var cold:Double { min(1,max(0,(16-feelsLike)/26)) }
    var hot:Double { min(1,max(0,(feelsLike-26)/16)) }
    var frost:Double { min(1,max(0,-temperature/14)) }
}

struct CompanionWeatherCharacter: View {
    let mood: CompanionWeatherMood
    let animates: Bool
    let previewTime: Double?
    let freezing: Bool
    let intensity: CompanionWeatherIntensity
    let animationClock: WeatherPanelClock?
    @Environment(\.islandPreview) private var preview
    @Environment(\.islandReduceMotion) private var islandReduceMotion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.companionMotionEnabled) private var motionEnabled

    init(mood: CompanionWeatherMood, animates: Bool, previewTime: Double? = nil, freezing: Bool? = nil, temperature:Double?=nil, feelsLike:Double?=nil, animationClock:WeatherPanelClock?=nil) {
        self.mood = mood; self.animates = animates; self.previewTime = previewTime
        self.freezing = freezing ?? (mood == .frozen)
        self.intensity=CompanionWeatherIntensity(mood:mood,temperature:temperature,feelsLike:feelsLike)
        self.animationClock=animationClock
    }

    private var moves: Bool {
        animates && motionEnabled && !reduceMotion && !islandReduceMotion && !preview && previewTime == nil
    }

    var body: some View {
        GeometryReader { proxy in
            if moves {
                WeatherCharacterScene(mood: mood, freezing: freezing, intensity:intensity, clock:animationClock)
            } else {
                // ImageRenderer cannot draw SCNView. Render the same geometry,
                // at the destination's backing size, once per cached still.
                Image(nsImage: Self.snapshot(mood: mood, time: previewTime ?? (freezing ? 5.5 : 0), size: proxy.size, freezing: freezing, intensity:intensity))
                    .resizable().interpolation(.high).scaledToFit()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true) // The parent supplies the localized caption.
    }

    /// `size` is in points; the returned image carries a 2× alpha bitmap.
    /// Explicit preview times are deterministic and never start a display clock.
    @MainActor static func snapshot(mood: CompanionWeatherMood, time: Double, size: CGSize, freezing: Bool? = nil, intensity:CompanionWeatherIntensity?=nil) -> NSImage {
        WeatherCharacterSnapshots.image(mood: mood, time: time, size: size, freezing: freezing ?? (mood == .frozen), intensity:intensity ?? CompanionWeatherIntensity(mood:mood))
    }
}

private struct WeatherCharacterInput: Sendable {
    var mood: CompanionWeatherMood
    var freezing: Bool
    var intensity: CompanionWeatherIntensity
    var clock: WeatherPanelClock?
}

private struct WeatherCharacterScene: NSViewRepresentable {
    let mood: CompanionWeatherMood
    let freezing: Bool
    let intensity: CompanionWeatherIntensity
    let clock: WeatherPanelClock?

    final class Coordinator: NSObject, SCNSceneRendererDelegate, @unchecked Sendable {
        let rig: WeatherCharacterRig
        private let lock = NSLock()
        private var input: WeatherCharacterInput
        private var currentMood: CompanionWeatherMood
        private var currentIntensity: CompanionWeatherIntensity
        private var elapsed = 0.0
        private var lastFrame: Double?
        private var transition: WeatherCharacterPose?
        private var lastPose: WeatherCharacterPose
        private(set) var frostLevel = 0.0

        @MainActor init(mood: CompanionWeatherMood, freezing: Bool, intensity:CompanionWeatherIntensity, clock:WeatherPanelClock?) {
            rig = WeatherCharacterRig()
            currentIntensity=intensity
            input = WeatherCharacterInput(mood: mood, freezing: freezing, intensity:intensity, clock:clock); currentMood = mood
            lastPose = WeatherCharacterPose.sample(mood, time: 0, intensity:intensity)
            super.init()
            rig.apply(mood: mood, time: 0, pose: lastPose, intensity:intensity)
        }

        func configure(mood: CompanionWeatherMood, freezing: Bool, intensity:CompanionWeatherIntensity, clock:WeatherPanelClock?) {
            lock.lock(); input = WeatherCharacterInput(mood: mood, freezing: freezing, intensity:intensity, clock:clock); lock.unlock()
        }

        func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
            lock.lock(); let input = self.input; lock.unlock()
            let mood = input.mood
            if mood != currentMood || input.intensity != currentIntensity {
                transition = lastPose; currentMood = mood; currentIntensity=input.intensity; elapsed = 0; lastFrame = nil
            }
            // A hidden/occluded SCNView has no callbacks. Resume from the held
            // pose, without catching up an offscreen sequence or wall clock.
            let gap = lastFrame.map { max(0,time-$0) } ?? 0
            let delta = gap < 0.25 ? gap : 0
            elapsed += delta; lastFrame = time
            frostLevel = min(1,max(0,frostLevel + delta * (input.freezing ? 1/WeatherSurfaceMotion.freezeDuration(input.intensity) : -1/2.6)))
            let sceneTime=input.clock?.time(at:Date()) ?? elapsed
            var pose = WeatherCharacterPose.sample(mood, time: sceneTime, intensity:input.intensity)
            if let source = transition {
                let blend = rigSmooth(elapsed / 0.35)
                pose = source.mixed(with: pose, fraction: blend)
                if blend == 1 { transition = nil }
            }
            lastPose = pose
            // The renderer owns all mutable nodes while attached. SwiftUI only
            // writes the locked mood mailbox; it never submits display ticks.
            rig.apply(mood: mood, time: sceneTime, pose: pose, frost: rigSmooth(frostLevel), intensity:input.intensity)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(mood: mood, freezing: freezing, intensity:intensity, clock:clock) }
    func makeNSView(context: Context) -> CompanionRenderView {
        let view = CompanionRenderView(frame: .zero)
        CompanionSceneLighting.configure(view, scene: context.coordinator.rig.scene,
                                         camera: context.coordinator.rig.camera)
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        view.animationEnabled = true
        return view
    }
    func updateNSView(_ view: CompanionRenderView, context: Context) {
        context.coordinator.configure(mood: mood, freezing: freezing, intensity:intensity, clock:clock)
        view.animationEnabled = true
    }
    static func dismantleNSView(_ view: CompanionRenderView, coordinator: Coordinator) {
        view.stopRendering()
    }
}

/// One authored timeline drives weather events and the companion's response.
/// The slow cycle includes quiet holds; impacts have a short attack and soft recovery.
enum WeatherChoreography {
    struct Beat {
        var gust: Double
        var flash: Double
        var startle: Double
        var impact: Double
        var exhale: Double
    }
    static func sample(time: Double) -> Beat {
        let t = max(0,time).truncatingRemainder(dividingBy:12)
        func pulse(_ start: Double, _ duration: Double) -> Double {
            WeatherCharacterPose.pulse(t,start,duration)
        }
        func response(_ start: Double, _ attack: Double, _ recovery: Double) -> Double {
            let v=t-start
            guard v>0, v<attack+recovery else { return 0 }
            return v<attack ? rigSmooth(v/attack) : 1-rigSmooth((v-attack)/recovery)
        }
        return Beat(gust:pulse(0.65,3.2)*0.85+pulse(7.7,2.5)*0.6,
                    flash:pulse(2.2,0.18)*0.6+pulse(2.53,0.32)+pulse(9.1,0.3)*0.65,
                    startle:response(2.3,0.16,1.35)+response(9.2,0.16,1.1)*0.65,
                    impact:response(0.95,0.2,1.0)+response(4.2,0.2,0.9)*0.7+response(8.2,0.2,1.1)*0.8,
                    exhale:pulse(4.7,2.1))
    }
}

struct WeatherCharacterPose {
    var x = 0.0, y = 0.0, sx = 1.0, sy = 1.0
    var roll = 0.0, yaw = -0.09, pitch = 0.0
    var open = 1.0, joy = 0.0, gazeX = 0.0, gazeY = 0.0, wink = 0.0
    var handLX = -34.0, handLY = -14.0, handLZ = 16.0, handLRoll = 0.0
    var handRX = 34.0, handRY = -14.0, handRZ = 16.0, handRRoll = 0.0
    var hands = 0.0, tail = 0.0

    static func sample(_ mood:CompanionWeatherMood,time:Double,intensity:CompanionWeatherIntensity?=nil) -> Self {
        let t=max(0,time), thermal=intensity ?? CompanionWeatherIntensity(mood:mood)
        let breath=sin(t*1.35), phase=t.truncatingRemainder(dividingBy:12)
        let beat=WeatherChoreography.sample(time:t)
        var p=Self(); p.yaw=0
        p.sy += breath*0.007; p.y=34*(p.sy-1)
        let blink=1-pulse(t.truncatingRemainder(dividingBy:6.1),5.15,0.3)*0.94
        p.open=blink
        switch mood {
        case .comfortable:
            let welcome=pulse(phase,1.1,2.8)
            p.joy=0; p.roll=sin(t*2.1)*welcome*0.035
            p.y += welcome*1.5
            p.hands=welcome; p.handLX = -31; p.handLY = -17
            p.handRX=34; p.handRY=2+sin(t*7)*welcome*2; p.handRRoll=0.65+sin(t*7)*0.25
        case .cloudy:
            let look=pulse(phase,0.6,3.2), nod=pulse(phase,4.2,1.5)
            p.gazeX = -look*2; p.gazeY = -look*1.4; p.roll=look*0.045-nod*0.035
            p.open=blink*(1-nod*0.4); p.y -= nod*1.2
        case .cold,.frozen,.snow:
            let severity=max(mood == .frozen ? 0.5 : 0.15,thermal.cold)
            let shiver=beat.gust
            let hug=0.55+shiver*0.4
            p.sy -= 0.025+severity*0.045; p.sx += severity*0.012; p.y=34*(p.sy-1)
            p.x=sin(t*2 * .pi*5.4)*shiver*(0.35+severity*1.1)
            p.roll=sin(t*2 * .pi*5.4)*shiver*(0.008+severity*0.014)-0.012
            p.open=blink*(0.96-shiver*0.22); p.gazeY=0.5
            p.tail=sin(t*2.1)*0.45+sin(t*8)*shiver*0.65
            p.hands=1; p.handLX = -13+hug*2; p.handLY = -22; p.handLRoll = -0.38
            p.handRX=17-hug*3; p.handRY = -24; p.handRRoll=0.4
            if mood == .cold {
                let tuck=pulse(phase,4.7,1.9)
                p.handRX += tuck*4; p.handRY += tuck*4; p.handRRoll += tuck*0.2
            }
            if mood == .snow {
                let catchSnow=pulse(phase,2.7,2.5)
                p.gazeY -= catchSnow*2.3; p.gazeX=catchSnow*1.4; p.roll+=catchSnow*0.05
                p.open += catchSnow*0.15; p.handRX += catchSnow*19
                p.handRY += catchSnow*18; p.handRRoll -= catchSnow*0.6; p.joy=0
            }
        case .hot:
            let heat=max(0.25,thermal.hot), fan=pulse(phase,0.7,4.3)+pulse(phase,7.4,3.5)*0.85
            let exhale=beat.exhale
            p.sy -= 0.035+heat*0.025+exhale*0.025; p.y=34*(p.sy-1)
            p.open=blink*(0.87-heat*0.18-exhale*0.18); p.roll = -0.035-exhale*0.025
            p.hands=1; p.handLX = -30; p.handLY = -25; p.handLRoll = -0.2
            p.handRX=35+sin(t*(9+heat*4))*fan*2.2; p.handRY = -11+fan*15
            p.handRRoll=0.45+sin(t*(9+heat*4))*fan*0.5; p.gazeX = -0.7; p.gazeY=0.6
        case .rain:
            let shake=pulse(phase,5.5,1.25)
            p.roll = -0.035+sin(t*11)*shake*0.065
            p.open=blink*(0.92-shake*0.35); p.gazeX = -1.2; p.gazeY = -1.1
            p.hands=1; p.handLX = -4-beat.gust*3; p.handLY=12+beat.gust*2; p.handLRoll = -0.16
            p.handRX=30; p.handRY = -19; p.handRRoll=0.35
        case .storm:
            let flinch=beat.startle, recover=pulse(phase,4.0,2.3)
            p.sy -= 0.025+flinch*0.055; p.y=34*(p.sy-1)
            p.x = -flinch*1.7; p.open=blink*(0.96-flinch*0.64)
            p.roll = -0.02-flinch*0.045+recover*0.025
            p.gazeX = -recover*1.5; p.gazeY = -recover
            p.hands=1; p.handLX = -4-flinch*7; p.handLY=11+flinch*3; p.handLRoll = -0.2-flinch*0.25
            p.handRX=30-flinch*5; p.handRY = -17+flinch*22; p.handRRoll=0.4+flinch*0.3
        case .hail:
            let duck=beat.impact
            p.sy -= 0.02+duck*0.07; p.sx += duck*0.025; p.y=34*(p.sy-1)
            p.open=blink*(0.98-duck*0.65); p.roll=duck*0.035; p.gazeY = -1.2
            p.hands=1; p.handLX = -8; p.handLY=15+duck*3; p.handLRoll = -0.28
            p.handRX=21; p.handRY=17+duck*3; p.handRRoll=0.3
        }
        p.open=max(0.06,p.open)
        return p
    }

    static func pulse(_ time: Double, _ start: Double, _ duration: Double) -> Double {
        guard time > start, time < start + duration else { return 0 }
        return pow(sin((time - start) / duration * .pi), 2)
    }

    func mixed(with b: Self, fraction f: Double) -> Self {
        func m(_ a: Double, _ b: Double) -> Double { a + (b - a) * f }
        var p = b
        p.x = m(x,b.x); p.y = m(y,b.y); p.sx = m(sx,b.sx); p.sy = m(sy,b.sy)
        p.roll = m(roll,b.roll); p.yaw = m(yaw,b.yaw); p.pitch = m(pitch,b.pitch)
        p.open = m(open,b.open); p.joy = m(joy,b.joy)
        p.gazeX = m(gazeX,b.gazeX); p.gazeY = m(gazeY,b.gazeY); p.wink = m(wink,b.wink)
        p.handLX = m(handLX,b.handLX); p.handLY = m(handLY,b.handLY); p.handLZ = m(handLZ,b.handLZ)
        p.handRX = m(handRX,b.handRX); p.handRY = m(handRY,b.handRY); p.handRZ = m(handRZ,b.handRZ)
        p.handLRoll = m(handLRoll,b.handLRoll); p.handRRoll = m(handRRoll,b.handRRoll)
        p.hands = m(hands,b.hands); p.tail = m(tail,b.tail)
        return p
    }
}

/// Surface events use smooth lifetimes and actual paths across the painted body.
/// They never reuse the legacy teardrop glyph or the three geometric snow caps.
enum WeatherSurfaceMotion {
    struct Drop {
        var x: Double, y: Double, size: Double, stretch: Double, opacity: Double, roll: Double
    }
    struct Flake {
        var x: Double, y: Double, size: Double, opacity: Double
    }
    static func ridge(_ x: Double) -> Double {
        // Upper contour measured from the approved winter portrait in 96-point space.
        (((-0.00000595345*x-0.0000712334)*x-0.0127711)*x+0.188933)*x+19.7835
    }
    static func snowLevel(time: Double) -> Double { rigSmooth((time-1.5)/12) }
    static func freezeDuration(_ intensity: CompanionWeatherIntensity) -> Double { 8-2.4*intensity.frost }
    static func drop(index: Int, time: Double, hot: Bool, intensity: Double) -> Drop {
        let seed=Double(index), elapsed=max(0,time-seed*(hot ? 0.87 : 0.39))
        let period=(hot ? 6.8-intensity*1.7 : 3.8)+seed*0.37
        let phase=elapsed.truncatingRemainder(dividingBy:period)/period
        let grow=rigSmooth(phase/0.27), slide=rigSmooth((phase-0.22)/0.58)
        let fall=max(0,(phase-0.80)/0.20), side=index%2==0 ? -1.0 : 1.0
        let startX=side<0 ? -10.0-Double(index/2)*3.1 : 28.0+Double(index/2)*1.1
        let bendX=side<0 ? -27.0 : 36.0, endX=side<0 ? -32.0 : 32.0
        let x=pow(1-slide,2)*startX+2*(1-slide)*slide*bendX+slide*slide*endX+fall*side*2
        let startY=13.0-Double(index/2)*3.7
        let y=startY-(startY+30)*pow(slide,1.3)-fall*fall*18
        let appear=rigSmooth(phase/0.12), disappear=1-rigSmooth((phase-0.87)/0.13)
        return Drop(x:x,y:y,size:(0.32+grow*0.68)*(hot ? 0.94 : 0.65+seed*0.045),
                    stretch:1+sin(slide * .pi)*0.45+fall*0.8,
                    opacity:time<seed*(hot ? 0.87 : 0.39) ? 0 : appear*disappear*(hot ? 0.88 : 0.65),
                    roll:side*0.13*(1-slide))
    }
    static func flake(index: Int, time: Double) -> Flake {
        let seed=Double(index), delay=seed*0.47, elapsed=time-delay
        guard elapsed>0 else { return Flake(x:0,y:60,size:0,opacity:0) }
        let period=3.7+seed*0.13, phase=elapsed.truncatingRemainder(dividingBy:period)
        let target=[-17.0,-7,5,17,26,10][index%6]
        let landing=1.5+seed*0.06, flight=min(1,phase/landing)
        let settle=max(0,(phase-landing)/0.32)
        let top=ridge(target)+snowLevel(time:time)*3
        let drift=(1-flight)*(sin(phase*2.1+seed)*2.8+sin(seed)*3)
        let y=top+(1-flight)*(24+seed*0.5)
        return Flake(x:target+drift,y:y,size:(0.65+Double(index%3)*0.14)*(1+min(1,settle)*0.5),
                     opacity:rigSmooth(phase/0.18)*(1-rigSmooth(settle)))
    }
}

private enum WeatherSurfaceShaders {
    static let body = """
    #pragma arguments
    float4 weatherRect;
    float4 weatherState;
    float4 handShadow0;
    float4 handShadow1;
    float handPresence;
    #pragma body
    float2 uv=_surface.diffuseTexcoord;
    float2 p=float2((uv.x-0.5)*weatherRect.z,(0.5-uv.y)*weatherRect.w)+weatherRect.xy;
    float3 paint=_output.color.rgb;
    float2 q0=p-handShadow0.xy;
    float2 q1=p-handShadow1.xy;
    q0=float2(q0.x*handShadow0.z+q0.y*handShadow0.w,-q0.x*handShadow0.w+q0.y*handShadow0.z)/float2(6.4,2.35);
    q1=float2(q1.x*handShadow1.z+q1.y*handShadow1.w,-q1.x*handShadow1.w+q1.y*handShadow1.z)/float2(6.4,2.35);
    float shadow=(exp(-dot(q0,q0)*1.8)+exp(-dot(q1,q1)*1.8))*handPresence*0.28;
    paint*=1.0-min(0.34,shadow);
    float grain=fract(sin(dot(p,float2(127.1,311.7)))*43758.5453);
    float height=(p.y+43.0)/65.0;
    float front=weatherState.x*1.22-0.08;
    float edge=sin(p.x*0.24+sin(p.y*0.16))*0.035+sin(p.x*0.71)*0.009;
    float ice=(1.0-smoothstep(front-0.055,front+0.08,height+edge))*smoothstep(0.0,0.12,weatherState.x);
    float light=sqrt(max(0.0,dot(paint,float3(0.299,0.587,0.114))));
    float3 icePaint=float3(0.25,0.49,0.61)*(0.35+light*2.4);
    icePaint+=float3(0.006,0.008,0.009)*(grain-0.5);
    float rim=pow(clamp(abs(p.x-3.0)/39.0,0.0,1.0),4.0);
    icePaint+=float3(0.12,0.16,0.18)*rim;
    paint=mix(paint,icePaint,ice*weatherState.z);
    // A thin powdered contact edge belongs to the upper contour, not three lumps.
    float ridge=(((-0.00000595345*p.x-0.0000712334)*p.x-0.0127711)*p.x+0.188933)*p.x+19.7835;
    float snowEdge=smoothstep(-27.0,-20.0,p.x)*(1.0-smoothstep(25.0,31.0,p.x));
    float dust=smoothstep(ridge-1.5-weatherState.y*1.8,ridge-0.1,p.y)*snowEdge*weatherState.y;
    paint=mix(paint,float3(0.78,0.86,0.89)+grain*0.035,dust*0.8);
    _output.color.rgb=paint*_output.color.a;
    """
    static let water = """
    #pragma transparent
    #pragma body
    float2 p=_surface.diffuseTexcoord*2.0-1.0;
    float width=0.54+0.09*p.y;
    float2 q=float2(p.x/width,(p.y-0.07)/0.76);
    float r=dot(q,q);
    float edge=1.0-smoothstep(0.88,1.0,r);
    float highlight=exp(-dot((p-float2(-0.16,-0.26))/float2(0.13,0.20),(p-float2(-0.16,-0.26))/float2(0.13,0.20))*2.0);
    float rim=pow(clamp(r,0.0,1.0),5.0);
    float lower=exp(-dot((p-float2(0.13,0.48))/float2(0.30,0.12),(p-float2(0.13,0.48))/float2(0.30,0.12)));
    float3 color=mix(float3(0.17,0.25,0.29),float3(0.68,0.79,0.84),rim*0.6+lower*0.4);
    color=mix(color,float3(0.94,0.98,1.0),highlight*0.90);
    float alpha=edge*min(1.0,0.14+rim*0.32+highlight*0.74+lower*0.2);
    _output.color=float4(color*alpha,alpha);
    """
    static let flake = """
    #pragma transparent
    #pragma body
    float2 p=_surface.diffuseTexcoord*2.0-1.0;
    float r=length(p);
    float grain=fract(sin(dot(p,float2(127.1,311.7)))*43758.5453);
    float a=(1.0-smoothstep(0.35,0.95,r))*(0.8+grain*0.2);
    _output.color=float4(mix(float3(0.71,0.82,0.90),float3(0.99,0.99,0.98),0.7-p.y*0.3)*a,a);
    """
    static let snow = """
    #pragma arguments
    float snowLevel;
    #pragma transparent
    #pragma body
    float2 p=float2((_surface.diffuseTexcoord.x-0.5)*96.0,(0.5-_surface.diffuseTexcoord.y)*96.0);
    float ridge=(((-0.00000595345*p.x-0.0000712334)*p.x-0.0127711)*p.x+0.188933)*p.x+19.7835;
    float span=smoothstep(-27.0,-18.0,p.x)*(1.0-smoothstep(23.0,31.0,p.x));
    float grain=fract(sin(dot(p,float2(127.1,311.7)))*43758.5453);
    float drifts=0.76+0.13*sin(p.x*0.43)+0.08*sin(p.x*0.91+1.4);
    float thickness=(0.5+snowLevel*3.8)*span*drifts;
    float d=p.y-ridge;
    float top=thickness+(grain-0.5)*0.16;
    float a=smoothstep(-1.3,-0.4,d)*(1.0-smoothstep(top-0.35,top+0.25,d))*span*smoothstep(0.0,0.08,snowLevel);
    float lighting=clamp((d+0.8)/max(1.0,thickness+0.8),0.0,1.0);
    float3 color=mix(float3(0.64,0.75,0.81),float3(0.98,0.985,0.97),lighting);
    color+=(grain-0.5)*0.035;
    _output.color=float4(color*a,a);
    """
}

/// Only the original painted hands remain; shadows are shaded into the body.
/// Surface particles and snow use persistent planes, with no legacy SCNShape props.
private final class WeatherCharacterRig {
    let scene=SCNScene()
    let camera: SCNNode
    let model: CompanionRigModel
    private var regularBody: SCNNode?
    private var winterBody: SCNNode?
    private var breath: [SCNNode]=[], drops: [SCNNode]=[], flakes: [SCNNode]=[]
    private let hands=[SCNNode(),SCNNode()]
    private var snowMantle=SCNNode()

    @MainActor init() {
        model=CompanionRigModel(.sig)
        camera=CompanionSceneLighting.configure(scene,scale:54)
        model.root.position.y=5; scene.rootNode.addChildNode(model.root)
        regularBody=model.head.childNodes.first
        if let image=NSImage(named:"Companion-sig-winter") {
            let plane=SCNPlane(width:96,height:96)
            plane.widthSegmentCount=32; plane.heightSegmentCount=32
            let material=SCNMaterial(); material.lightingModel = .constant
            material.diffuse.contents=image; material.isDoubleSided=true
            material.blendMode = .alpha; material.writesToDepthBuffer=false
            material.shaderModifiers=[.geometry:"""
            #pragma arguments
            float clothSway;
            #pragma body
            float tail=smoothstep(8.0,26.0,_geometry.position.x)*(1.0-smoothstep(-35.0,-19.0,_geometry.position.y));
            _geometry.position.x+=tail*clothSway*0.65;
            _geometry.position.y+=tail*clothSway*0.25;
            """]
            material.setValue(Float(0),forKey:"clothSway"); plane.materials=[material]
            let node=SCNNode(geometry:plane)
            node.position.z=regularBody?.position.z ?? 0; node.renderingOrder = -10
            node.isHidden=true; model.head.addChildNode(node); winterBody=node
        }
        for body in [regularBody,winterBody] {
            guard let body, let plane=body.geometry as? SCNPlane, let material=plane.firstMaterial else { continue }
            var shaders=material.shaderModifiers ?? [:];shaders[.fragment]=WeatherSurfaceShaders.body;material.shaderModifiers=shaders
            material.setValue(NSValue(scnVector4:SCNVector4(body.position.x,body.position.y,plane.width,plane.height)),forKey:"weatherRect")
            material.setValue(NSValue(scnVector4:SCNVector4(0,0,0,0)),forKey:"weatherState")
            material.setValue(NSValue(scnVector4:SCNVector4(0,0,1,0)),forKey:"handShadow0")
            material.setValue(NSValue(scnVector4:SCNVector4(0,0,1,0)),forKey:"handShadow1")
            material.setValue(Float(0),forKey:"handPresence")
        }
        for (index,name) in ["left","right"].enumerated() {
            if let image=NSImage(named:"Companion-sig-weather-hand-\(name)") {
                let plane=SCNPlane(width:18,height:9)
                let material=SCNMaterial();material.lightingModel = .constant
                material.diffuse.contents=image;material.isDoubleSided=true
                material.blendMode = .alpha;material.writesToDepthBuffer=false
                plane.materials=[material];hands[index].geometry=plane
            }
            hands[index].renderingOrder=4;model.head.addChildNode(hands[index])
        }
        snowMantle=Self.effect(width:96,height:96,shader:WeatherSurfaceShaders.snow)
        snowMantle.geometry?.firstMaterial?.setValue(Float(0),forKey:"snowLevel")
        snowMantle.position.z=CGFloat(model.front+1);snowMantle.renderingOrder=1;model.head.addChildNode(snowMantle)
        for _ in 0..<6 {
            let node=Self.effect(width:4.5,height:6.3,shader:WeatherSurfaceShaders.water)
            node.position.z=CGFloat(model.front+2);node.renderingOrder=3;model.head.addChildNode(node);drops.append(node)
        }
        for _ in 0..<6 {
            let node=Self.effect(width:2.4,height:2.4,shader:WeatherSurfaceShaders.flake)
            node.position.z=CGFloat(model.front+2);node.renderingOrder=3;model.head.addChildNode(node);flakes.append(node)
        }
        for _ in 0..<3 {
            let material=SCNMaterial();material.lightingModel = .constant
            material.diffuse.contents=CompanionGreetingRig.glowTexture();material.multiply.contents=rigRgb(0.78,0.86,0.9)
            material.isDoubleSided=true;material.writesToDepthBuffer=false
            let node=SCNNode(geometry:SCNPlane(width:12,height:8));node.geometry?.materials=[material]
            model.head.addChildNode(node);breath.append(node)
        }
    }
    private static func effect(width:Double,height:Double,shader:String)->SCNNode {
        let plane=SCNPlane(width:width,height:height),material=SCNMaterial()
        material.lightingModel = .constant;material.diffuse.contents=NSColor.white
        material.isDoubleSided=true;material.blendMode = .alpha;material.writesToDepthBuffer=false
        material.shaderModifiers=[.fragment:shader];plane.materials=[material]
        return SCNNode(geometry:plane)
    }
    func apply(mood:CompanionWeatherMood,time:Double,pose p:WeatherCharacterPose,frost:Double=0,intensity:CompanionWeatherIntensity?=nil) {
        SCNTransaction.begin();SCNTransaction.animationDuration=0
        let thermal=intensity ?? CompanionWeatherIntensity(mood:mood)
        let frozen=frost
        model.head.position=SCNVector3(p.x*(1-frozen*0.6),p.y,0)
        model.head.scale=SCNVector3(p.sx*(1-frozen*0.012),p.sy*(1-frozen*0.025),1)
        model.head.eulerAngles=SCNVector3(0,0,p.roll*(1-frozen*0.65))
        model.updateEyes(open:p.open,joy:p.joy,gaze:CGSize(width:p.gazeX,height:p.gazeY),wink:p.wink,anger:0)
        for (i,hand) in hands.enumerated() {
            hand.opacity=p.hands;hand.scale=SCNVector3(0.78,0.85,1)
            hand.position=i==0 ? SCNVector3(p.handLX,p.handLY,model.front+5) : SCNVector3(p.handRX,p.handRY,model.front+6)
            hand.eulerAngles.z=CGFloat(i==0 ? p.handLRoll : p.handRRoll)
            hand.geometry?.firstMaterial?.multiply.contents=rigRgb(1-frozen*0.24,1-frozen*0.10,1)
        }
        let snow=mood == .snow ? WeatherSurfaceMotion.snowLevel(time:time) : 0
        snowMantle.opacity=snow>0 ? 1 : 0
        snowMantle.geometry?.firstMaterial?.setValue(Float(snow),forKey:"snowLevel")
        let chilly=thermal.cold>0.1 || mood == .cold || mood == .frozen || mood == .snow || frost>0.01
        regularBody?.isHidden=chilly && winterBody != nil;winterBody?.isHidden = !chilly
        winterBody?.geometry?.firstMaterial?.setValue(Float(p.tail*(1-frozen*0.65)),forKey:"clothSway")
        let flash=(mood == .storm || mood == .hail) ? WeatherChoreography.sample(time:time).flash : 0
        let shade=(mood == .storm || mood == .hail) ? 0.92+flash*0.08 : 1.0
        for body in [regularBody,winterBody] {
            guard let mat=body?.geometry?.firstMaterial else {continue}
            mat.setValue(NSValue(scnVector4:SCNVector4(frozen,snow,mood == .snow ? 0.28+thermal.frost*0.2 : 0.68+thermal.frost*0.12,time)),forKey:"weatherState")
            mat.setValue(NSValue(scnVector4:SCNVector4(p.handLX,p.handLY-1.5,cos(p.handLRoll),sin(p.handLRoll))),forKey:"handShadow0")
            mat.setValue(NSValue(scnVector4:SCNVector4(p.handRX,p.handRY-1.5,cos(p.handRRoll),sin(p.handRRoll))),forKey:"handShadow1")
            mat.setValue(Float(p.hands),forKey:"handPresence")
            mat.multiply.contents=rigRgb(shade,shade,min(1,shade+0.025))
        }
        for (i,node) in breath.enumerated() {
            let phase=(max(0,time)-Double(i)*0.17).truncatingRemainder(dividingBy:12),v=(phase-4.7)/2.1
            node.opacity=chilly && v>0 && v<1 ? sin(v * .pi)*0.40 : 0
            node.position=SCNVector3(-25-v*19,-7+v*8,model.front+3);node.scale=SCNVector3(0.6+v*1.1,0.6+v*0.8,1)
        }
        let wet=mood == .rain || mood == .storm || mood == .hail
        for (i,node) in drops.enumerated() {
            let drop=WeatherSurfaceMotion.drop(index:i,time:time,hot:mood == .hot,intensity:thermal.hot)
            node.opacity=(wet || mood == .hot) && (mood != .hot || i<3) ? drop.opacity : 0
            node.position=SCNVector3(drop.x,drop.y,model.front+2);node.scale=SCNVector3(drop.size,drop.size*drop.stretch,1)
            node.eulerAngles.z=CGFloat(drop.roll)
        }
        for (i,node) in flakes.enumerated() {
            let flake=WeatherSurfaceMotion.flake(index:i,time:time)
            node.opacity=mood == .snow ? flake.opacity : 0;node.position=SCNVector3(flake.x,flake.y,model.front+2)
            node.scale=SCNVector3(flake.size,flake.size,1)
        }
        SCNTransaction.commit()
    }
}

@MainActor private enum WeatherCharacterSnapshots {
    private static var cache: [String: NSImage] = [:]
    private static var order: [String] = []

    static func image(mood: CompanionWeatherMood, time: Double, size: CGSize, freezing: Bool, intensity:CompanionWeatherIntensity) -> NSImage {
        let width = Int(min(512, max(1, size.width.isFinite ? size.width : 154)) * 2)
        let height = Int(min(512, max(1, size.height.isFinite ? size.height : 156)) * 2)
        let safeTime = time.isFinite ? min(86_400, max(0, time)) : 0
        let frame = Int((safeTime * 24).rounded()), t = Double(frame) / 24
        let key = "\(mood.rawValue):\(intensity.temperature):\(intensity.feelsLike):\(freezing):\(frame):\(width):\(height)"
        if let cached = cache[key] { return cached }
        let rig = WeatherCharacterRig()
        rig.apply(mood: mood, time: t, pose: WeatherCharacterPose.sample(mood, time: t, intensity:intensity),
                  frost: freezing ? rigSmooth(t/WeatherSurfaceMotion.freezeDuration(intensity)) : 0, intensity:intensity)
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = rig.scene; renderer.pointOfView = rig.camera
        renderer.autoenablesDefaultLighting = false
        let rendered = renderer.snapshot(atTime: t, with: CGSize(width: width, height: height), antialiasingMode: .multisampling4X)
        let image = NSImage(size: CGSize(width: CGFloat(width)/2, height: CGFloat(height)/2))
        guard let cg = rendered.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // A headless/Metal-unavailable host may not produce a scene image.
            // Keep the approved silhouette when bundled; do not cache a failed render.
            return NSImage(named: "Companion-sig") ?? image
        }
        let rep = NSBitmapImageRep(cgImage: cg); rep.size = image.size; image.addRepresentation(rep)
        cache[key] = image; order.append(key)
        // Bound raster memory by both count and pixels (approximately 8 MiB).
        func pixels() -> Int { cache.values.reduce(0) { $0 + Int($1.size.width * $1.size.height * 4) } }
        while order.count > 14 || pixels() > 2_097_152 {
            cache.removeValue(forKey: order.removeFirst())
        }
        return image
    }
}
