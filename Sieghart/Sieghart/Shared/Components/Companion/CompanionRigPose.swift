import AppKit
import SceneKit
import SwiftUI

enum CompanionRigState:Int,CaseIterable {
    case hello,idle,look,stroll,preparing,listening,thinking,working,speaking,understood,happy,celebrating,annoyed,startled,failure,sleeping,waking
    var title:String {["ALÔ / PRIMEIRA ABERTURA","REPOUSO","OLHAR","PASSEAR","PREPARANDO","ESCUTANDO","LOADING / PENSANDO","ATIVIDADE PRÓPRIA","FALANDO","ENTENDI","CONTENTE","COMEMORANDO","IRRITADO","SUSTO","ALGO DEU ERRADO","DORMINDO","DESPERTANDO"][rawValue]}
    var duration:Double {[4,2,2,2,2,2,3,4,2,2,2,3,2,1.5,2,3,2.5][rawValue]}
    // Waking is handled explicitly: all 17 existing/general states are visible.
    var seconds:Double {self == .waking ? 2.5 : duration}
    static var length:Double {allCases.reduce(0){$0+$1.seconds}}
    static func at(_ time:Double)->(CompanionRigState,Double) {
        var t=max(0,time).truncatingRemainder(dividingBy:length)
        for state in allCases {if t<state.seconds {return(state,t)};t-=state.seconds}
        return(.hello,0)
    }
    var start:Double {Self.allCases.prefix(rawValue).reduce(0){$0+$1.seconds}}
}
func rigSmooth(_ value:Double)->Double {let x=min(1,max(0,value));return x*x*(3-2*x)}

// A top intake, then two soft acknowledgement pulses. The receipt has no
// progress bar or spinning body; rigid characters preserve their silhouette.
struct CompanionFileIntake: Sendable {
    var scaleX = 1.0, scaleY = 1.0, pitch = 0.0, eyeOpen = 1.0, joy = 0.0
    var aperture = 0.0, suction = 0.0, fileOpacity = 0.0, fileScaleX = 1.0, fileScaleY = 1.0
}
func rigFileIntake(time t: Double) -> CompanionFileIntake {
    var p = CompanionFileIntake()
    p.suction = rigSmooth((t - 0.08) / 0.30)
    p.aperture = 1 - rigSmooth((t - 0.38) / 0.12)
    p.fileOpacity = 1 - rigSmooth((t - 0.30) / 0.09)
    p.fileScaleX = 1 - p.suction * 0.75; p.fileScaleY = 1 - p.suction * 0.2
    if t < 0.08 { let k=rigSmooth(t/0.08);p.scaleX=1+k*0.045;p.scaleY=1-k*0.06 }
    else if t < 0.38 { p.scaleX=rigGLerp(1.045,0.975,p.suction);p.scaleY=rigGLerp(0.94,1.045,p.suction) }
    else if t < 0.49 { let k=rigSmooth((t-0.38)/0.11);p.scaleX=rigGLerp(0.975,1.075,k);p.scaleY=rigGLerp(1.045,0.90,k) }
    else if t < 0.65 { let k=rigSmooth((t-0.49)/0.16);p.scaleX=rigGLerp(1.075,1,k);p.scaleY=rigGLerp(0.90,1,k) }
    else if t < 0.95 { let pulse=pow(sin((t-0.65)/0.15 * .pi),2)*(1-rigSmooth((t-0.85)/0.10));p.scaleX=1+pulse*0.015;p.scaleY=1-pulse*0.025 }
    p.pitch = -0.035 * (1-rigSmooth((t-0.4)/0.3))
    p.eyeOpen = 1 - sin(rigGSeg(t,0.39,0.66)*Double.pi)*0.45
    p.joy = sin(rigGSeg(t,0.48,1.25)*Double.pi)*0.6
    return p
}
struct CompanionRigPose: Sendable {
    var sx=1.0,sy=1.0,sz=1.0,x=0.0,y=0.0,yaw=0.0,roll=0.0,pitch=0.0,open=1.0,joy=0.0,wink=0.0,anger=0.0,loading=0.0,fold=0.0,opacity=1.0
    var gaze=CGSize.zero
    func mix(_ other:Self,_ p:Double)->Self {
        func m(_ a:Double,_ b:Double)->Double {a+(b-a)*p}
        var result=Self()
        result.sx=m(sx,other.sx);result.sy=m(sy,other.sy);result.sz=m(sz,other.sz);result.x=m(x,other.x);result.y=m(y,other.y)
        result.yaw=m(yaw,other.yaw);result.roll=m(roll,other.roll);result.pitch=m(pitch,other.pitch)
        result.open=m(open,other.open);result.joy=m(joy,other.joy);result.wink=m(wink,other.wink);result.anger=m(anger,other.anger)
        result.loading=m(loading,other.loading);result.fold=m(fold,other.fold);result.opacity=m(opacity,other.opacity)
        result.gaze=CGSize(width:m(gaze.width,other.gaze.width),height:m(gaze.height,other.gaze.height));return result
    }
}

// A shared clock drives six different greetings. Rigid characters keep their proportions;
// the expressive gesture belongs to the character's existing accessory.
func rigIdentityHelloPose(_ hero: CompanionAvatar, _ time: Double) -> CompanionRigPose {
    CompanionPaintedMotion.sample(hero, id: 43, time: time, global: 0)
}

// A short, identity-specific reaction while waiting for a turn. The intro
// schedules one companion at a time; inactive miniatures remain cached.
func rigWaitingPose(_ hero: CompanionAvatar, _ time: Double) -> CompanionRigPose {
    let k = pow(sin(rigGSeg(time, 0, 0.85) * .pi), 2)
    var p = rigIdentityHelloPose(hero, 0)
    p.gaze = CGSize(width: -2.5 * k, height: -0.8 * k)
    switch hero {
    case .sig: p.pitch = k * 0.07; p.open = 1 - k * 0.2
    case .rita: p.roll = -k * 0.07; p.wink = k * 0.45
    case .ada: p.y = pow(sin(time * .pi * 2 / 0.85), 2) * k * 3
    case .gantt: p.pitch = -k * 0.08; p.open = 1 - k * 0.3
    case .elinor: p.yaw += k * 0.10; p.open = 1 - k * 0.4
    case .toni: p.roll = k * 0.055; p.open = 1 - k * 0.35
    }
    return p
}

extension CompanionRigModel {
    func updateWaitingGesture(time: Double) {
        let k = pow(sin(rigGSeg(time, 0, 0.85) * .pi), 2)
        if usesIntegratedIllustration { updateIllustratedGesture(fold: k * 0.45) }
        switch hero {
        case .gantt: paper?.opacity = usesIllustration ? 1 : k; paper?.eulerAngles.y = CGFloat(k * 0.45)
        case .elinor: identityAccent?.eulerAngles.z = CGFloat(k * 0.10)
        case .toni: paper?.eulerAngles.z = CGFloat(-0.1 - k * (0.25 + sin(time * 12) * 0.08))
        default: break
        }
    }
    func updateIdentityHello(time: Double, strength: Double) {
        let t = max(0, time)
        let gesture = rigSmooth(t / 0.18) * (1 - rigSmooth((t - 1.55) / 0.5)) * strength
        if usesIntegratedIllustration { updateIllustratedGesture(fold: gesture * sin(t * 3) * 0.7) }
        accessory.scale = SCNVector3(1, 1, 1); accessory.opacity = 1
        switch hero {
        case .sig:
            let pulse = 1 + gesture * 0.06
            accessory.scale = SCNVector3(pulse, pulse, 1)
        case .rita:
            // The book lifts with Rita's nod; glasses and sprout stay attached.
            identityAccent?.eulerAngles.z = CGFloat(gesture * sin(t * 3) * 0.14)
        case .ada:
            // The lid answers Ada's two rigid-body hops.
            if usesIllustration { identityAccent?.eulerAngles.z = CGFloat(-gesture * sin(t * 9) * 0.08) }
            else { notebookLid?.eulerAngles.x = CGFloat(-0.16 - gesture * (0.09 + sin(t * 9) * 0.07)) }
        case .gantt:
            paper?.opacity = usesIllustration ? 1 : gesture
            paper?.eulerAngles.y = CGFloat(gesture * (0.55 + sin(t * 5) * 0.18))
        case .elinor:
            identityAccent?.eulerAngles.z = CGFloat(sin(t * 5) * gesture * 0.14)
        case .toni:
            paper?.eulerAngles = SCNVector3(0.08 + gesture * 0.18, 0,
                                           -0.1 - gesture * (0.52 + sin(t * .pi * 6) * 0.22))
            paperRight?.eulerAngles.z = CGFloat(gesture * sin(t * 3) * 0.045)
        }
    }
}

func rigPose(_ hero:CompanionAvatar,_ state:CompanionRigState,_ t:Double,_ global:Double)->CompanionRigPose {
    let index=Double(CompanionAvatar.allCases.firstIndex(of:hero)!)
    var p=CompanionRigPose();let breath=sin(global*1.5+index*0.4)
    p.sx+=breath*0.004;p.sy+=breath*0.012;p.y+=breath*0.55
    p.yaw = -0.09+sin(global*0.8+index)*0.017
    let blink=(global+index*0.17).truncatingRemainder(dividingBy:4.2)
    if blink>3.55 && blink<3.85 {p.open=1-sin((blink-3.55)/0.3*Double.pi)*0.94}
    switch state {
    case .hello:
        let v=max(0,t-index*0.08),spring=1-exp(-5*v)*cos(9*v)
        p.sx=0.40+spring*0.60;p.sy=0.23+spring*0.77;p.y = -34*(1-spring)
        p.opacity=rigSmooth(v/0.3);p.open=rigSmooth(v/0.5)
        let wave=sin(max(0,v-0.7)*6)*exp(-max(0,v-0.7)*1.3)
        p.roll=wave*0.06;p.yaw = -0.09+wave*0.2;p.joy=rigSmooth((v-0.6)/0.6)*0.65*(1-rigSmooth((v-2.5)/1.1))
        p.fold=max(0,sin(min(1,max(0,(v-0.6)/2.5))*Double.pi))
    case .idle:p.gaze.width=sin(t*1.8+index*0.3)*0.7
    case .look:
        p.gaze.width=sin(t*Double.pi)*3.8;p.yaw = -0.09+sin(t*Double.pi)*0.20
    case .stroll:
        p.x=sin(t*Double.pi)*7;p.y+=abs(sin(t*Double.pi*2))*2
        p.roll=sin(t*Double.pi*2)*0.045;p.yaw = -0.09+cos(t*Double.pi)*0.12;p.gaze.width=cos(t*Double.pi)*2
    case .preparing:p.open*=0.85;p.loading=rigSmooth(t/0.25);p.gaze.height = -0.7
    case .listening:
        p.open*=1.06;p.gaze=CGSize(width:sin(t*3)*1.7,height:-0.7)
        p.pitch=sin(t*3.4)*0.03;p.yaw = -0.09+sin(t*2.2)*0.10;p.roll=sin(t*2.1)*0.025;p.fold=0.20+sin(t*2)*0.12
    case .thinking:
        p.loading=1;p.open*=0.8;p.gaze=CGSize(width:sin(t*2.3)*1.7,height:-1.8)
        p.yaw = -0.09+sin(t*2.3)*0.10;p.roll=sin(t*2)*0.018;p.fold=0.15+sin(t*2)*0.08
    case .working:
        p.loading=0.6;p.fold=0.4+sin(t*2)*0.3
        switch hero {
        case .sig:p.gaze.width=sin(t*2)*2.5;p.yaw = -0.09+sin(t*2)*0.15
        case .rita:let b=(1-cos(t*Double.pi/2))/2;p.sx=1+b*0.025;p.sy=0.98+b*0.06;p.y+=b*1.3;p.open=0.72;p.joy=0.12
        case .ada:p.gaze.height=1.2;let hop=pow(sin(min(1,max(0,(t-2.9)/0.8))*Double.pi),2);p.y+=hop*5;p.joy=hop*0.7
        case .gantt:p.gaze.width=sin(t*1.5)*1.3;p.pitch=sin(t*1.5)*0.035
        case .elinor:p.gaze.height=0.7;p.yaw = -0.09+sin(t*1.5)*0.08
        case .toni:p.gaze.width=rigSmooth((t-1.6)/1.5)*2.7;p.gaze.height = -rigSmooth((t-1.6)/1.5)*0.7
        }
    case .speaking:p.sy+=sin(t*10)*0.012;p.roll=sin(t*4.5)*0.025;p.open*=1+sin(t*9.5)*0.04;p.fold=0.3+sin(t*5)*0.18
    case .understood:
        let nod=sin(min(1,t/1.1)*Double.pi);p.pitch=nod*0.1;p.y-=nod*1.5;p.joy=nod*0.50;p.wink=hero == .sig || hero == .toni ? nod*0.85 : 0
    case .happy:p.joy=0.70;p.y+=sin(t*3)*1;p.roll=sin(t*2)*0.025
    case .celebrating:
        let u=min(1,t/1.35),jump=pow(sin(u*Double.pi),2)
        p.y+=jump*(hero == .ada ? 7 : 4);p.sx+=jump*0.025;p.sy-=jump*0.028
        p.roll=hero == .ada ? 0 : sin(u*Double.pi*2)*(1-u)*0.055;p.joy=rigSmooth(t/0.3)*0.8*(1-rigSmooth((t-1.5)/0.5));p.fold=jump
    case .annoyed:
        p.open*=0.66;p.anger=18*rigSmooth(t/0.2);p.x=sin(t*15)*0.8*(1-rigSmooth((t-1.4)/0.6));p.yaw = -0.09+sin(t*9)*0.045;p.fold=0.04
    case .startled:
        let s=sin(min(1,t/1.5)*Double.pi);p.open=1+s*0.22;p.sy+=s*0.045;p.y+=s*2;p.pitch = -s*0.03
    case .failure:p.open*=0.65;p.gaze.height=1.3;p.roll = -0.045*rigSmooth(t/0.3);p.fold=0.1
    case .sleeping:
        let b=(1-cos(t*1.8))/2;p.open=0.045;p.sx=1+b*0.02;p.sy=0.94+b*0.06;p.roll=0.04+sin(t*0.8)*0.015;p.y = -1+b*0.7;p.fold=0.05
    case .waking:
        let stretch=sin(min(1,t/1.4)*Double.pi);p.open=0.06+rigSmooth(t/0.9)*0.94;p.sy=0.96+stretch*0.08;p.y+=stretch*1.5;p.joy=stretch*0.22;p.fold=stretch*0.5
    }
    // Preserve each silhouette and give the common state its own character.
    switch hero {
    case .ada:
        if state == .hello {let v=max(0,t-index*0.08),s=0.23+(1-exp(-5*v)*cos(9*v))*0.77;p.sx=s;p.sy=s}
        else {p.sx=1;p.sy=1;p.roll=0}
    case .gantt:p.sx=p.sy;p.roll*=0.60
    case .rita:p.roll*=1.35;p.yaw*=0.80
    case .elinor:p.yaw*=0.65;p.roll*=0.55
    case .toni:p.roll*=1.15
    case .sig:break
    }
    return p
}

extension CompanionRigModel {
    func prepareMotion() {
        let badge = rigLoadingBadge(self)
        marker = badge.node; loadingProgress = badge.progress
        badge.node.position = SCNVector3(-31, 27, front + 8); badge.node.opacity = 0
        if usesIllustration { badge.node.position = SCNVector3(-25, -40, front + 8) }
        head.addChildNode(badge.node)
        switch hero {
        case .ada:
            for n in 0..<3 {
                let line=motionShape(Path(roundedRect:CGRect(x:30,y:86+Double(n)*4,width:30-Double(n)*4,height:2),cornerRadius:0.5),color:[rigLilac,rigMint,rigCoral][n],depth:1,bevel:0.2)
                line.position.z=CGFloat(front+2);activity.addChildNode(line)
            }
        case .elinor:
            for n in 0..<3 {
                let bar=motionShape(Path(roundedRect:CGRect(x:29+Double(n)*11,y:93-Double(n)*4,width:6,height:6+Double(n)*4),cornerRadius:1),color:rigGold,depth:2,bevel:0.5)
                bar.position.z=CGFloat(front+3);activity.addChildNode(bar)
            }
        case .gantt:
            for n in 0..<3 {
                let card=motionShape(Path(roundedRect:CGRect(x:24+Double(n)*19,y:88,width:12,height:10),cornerRadius:2),color:[rigLilac,rigCoral,rigMint][n],depth:2,bevel:0.5)
                card.position.z=CGFloat(front+3);activity.addChildNode(card)
            }
        case .toni:
            let plane=motionShape(rigPolygon([(29,85),(52,80),(44,99),(40,90)],radius:0.3),color:rigCream,depth:0.8,bevel:0.1)
            plane.position.z=CGFloat(front+5);activity.addChildNode(plane)
        case .sig:
            for _ in 0..<2 {
                let route=motionShape(rigPolygon([(46,82),(49,85),(46,88),(43,85)]),color:rigMint,depth:2,bevel:0.4)
                route.position.z=CGFloat(front+3);activity.addChildNode(route)
            }
        case .rita:
            if usesIntegratedIllustration {
                for x in [32.0, 44.0, 56.0] {
                    let dot = motionShape(Path(roundedRect: CGRect(x: x, y: 87, width: 6, height: 2), cornerRadius: 1), color: rigMint, depth: 0.6)
                    dot.position.z = CGFloat(front + 2); activity.addChildNode(dot)
                }
                break
            }
            let outline = rigBodyPath(hero).strokedPath(StrokeStyle(lineWidth: 0.8, lineJoin: .round))
            let ring = motionShape(outline, color: rigMint, depth: 0.6)
            ring.position.z=CGFloat(front-1);ring.scale=SCNVector3(1.07,1.07,1);activity.addChildNode(ring)
        }
        activity.opacity=0
    }
    func updateActivity(time t: Double) {
        if usesIllustration {
            let phase=max(0,t).truncatingRemainder(dividingBy:4.8)
            for (index,node) in activity.childNodes.enumerated() {
                let v=CompanionPaintedMotion.pulse(phase,0.4+Double(index)*0.3,2.0)
                node.opacity=v*0.65
                switch hero {
                case .sig: node.position.x=CGFloat((index==0 ? -1 : 1)*v*10); node.position.y=CGFloat(v*2)
                case .rita: node.scale=SCNVector3(1+v*0.1,1,1)
                case .ada: node.scale.x=CGFloat(0.3+v*0.7)
                case .gantt: node.position.x=CGFloat(v*0.7)
                case .elinor: node.scale.y=CGFloat(0.65+v*0.35)
                case .toni: node.position=SCNVector3(-23+v*8,-37+v*2,front+5); node.eulerAngles.z=CGFloat(v*0.06)
                }
            }
            return
        }
        for (n,node) in activity.childNodes.enumerated() {
            switch hero {
            case .sig:let v=(t+Double(n)*0.7).truncatingRemainder(dividingBy:1.8)/1.8;node.position.x=CGFloat((n==0 ? -1 : 1)*v*30);node.position.y=CGFloat(sin(v*Double.pi)*6)
            case .rita:
                let breathe = (1-cos(t*Double.pi/2 - Double(n)*0.6))/2
                let stretch = usesIntegratedIllustration ? 1+breathe*0.3 : 1.04+breathe*0.09
                node.scale=SCNVector3(stretch,stretch,1);node.opacity=0.17+breathe*0.35
            case .ada:node.scale.x=CGFloat(rigSmooth((t-Double(n)*0.5)/0.7))
            case .gantt:node.position.x=CGFloat(sin(max(0,t-Double(n)*0.4)*2)*3*(1-rigSmooth((t-2)/1)))
            case .elinor:node.scale.y=CGFloat(0.15+rigSmooth((t-Double(n)*0.3)/0.7)*0.85)
            case .toni:
                let v=rigSmooth((t-1)/2.6)
                node.position.x=CGFloat(usesIntegratedIllustration ? -20+v*18 : v*31)
                node.position.y=CGFloat(usesIntegratedIllustration ? -39+sin(v*Double.pi)*5 : sin(v*Double.pi)*12)
                node.eulerAngles.z=CGFloat(v*0.3);node.opacity=rigSmooth(t/0.3)
            }
        }
    }
}

/// Choreography for the painted family. All envelopes have zero end velocity;
/// the body, fitted wearables and contact shadows share one transform.
enum CompanionPaintedMotion {
    static func pulse(_ t: Double, _ start: Double, _ length: Double) -> Double {
        guard t > start, t < start + length else { return 0 }
        return pow(sin((t-start) / length * .pi), 2)
    }
    static func window(_ t: Double, _ start: Double, _ end: Double, ramp: Double = 0.35) -> Double {
        rigSmooth((t-start)/ramp) * (1-rigSmooth((t-end)/ramp))
    }
    static func idle(_ hero: CompanionAvatar, _ time: Double) -> CompanionRigPose {
        let i = Double(CompanionAvatar.allCases.firstIndex(of: hero) ?? 0)
        let phase = time * (hero == .elinor ? 1.05 : 1.35) + i * 0.48
        let breath = sin(phase)
        var p = CompanionRigPose()
        p.sy += breath * 0.004; p.sx -= breath * 0.0015
        p.y = 34 * (p.sy-1)
        let blink = (max(0,time)+i*0.71).truncatingRemainder(dividingBy: 5.7)
        p.open = 1 - pulse(blink, 4.65, 0.28)*0.94
        return p
    }
    static func sample(_ hero: CompanionAvatar, id: Int, time: Double, global: Double) -> CompanionRigPose {
        let t = max(0,time), motion = CompanionAnimation(rawValue: id) ?? .idle
        var p = idle(hero, global)
        let energy: Double = switch hero {
        case .sig: 1; case .rita: 0.72; case .ada: 0.85
        case .gantt: 0.65; case .elinor: 0.5; case .toni: 1.1
        }
        let phase = t.truncatingRemainder(dividingBy: 4.8)
        let engaged = window(t, 0, 100_000)
        func beat(_ start: Double, _ length: Double = 0.72) -> Double { pulse(t, start, length) }
        func nod(_ start: Double, _ length: Double = 0.72) {
            let v = beat(start,length); p.y -= v*1.6*energy; p.sy -= v*0.013
            p.roll -= v*0.016*energy; p.joy += v*0.22
        }
        switch motion {
        case .launch:
            let arrive = rigSmooth(t/0.70), settle = beat(0.5,0.7)
            p.opacity = arrive; p.y += -14*(1-arrive)-settle*1.6
            p.sx *= 0.92+arrive*0.08+settle*0.01; p.sy *= 0.92+arrive*0.08-settle*0.013
            let hello = sample(hero,id:43,time:max(0,t-0.8),global:global)
            if t > 0.8 { p = p.mix(hello,rigSmooth((t-0.8)/0.3)) }
        case .cursor:
            p.gaze = CGSize(width:sin(t*0.9)*1.5,height:sin(t*0.55)*0.5)
            p.roll = -sin(t*0.9)*0.009
        case .miniLook:
            let look = window(phase,0.5,2.3,ramp:0.6)
            p.gaze = CGSize(width:look*2,height:-look*0.4); p.roll = -look*0.012
        case .breathing, .idle: break
        case .blink:
            let v = t.truncatingRemainder(dividingBy:3)
            p.open = 1-0.94*max(pulse(v,0.55,0.28),pulse(v,1.02,0.25))
        case .touch:
            let press=beat(0.22,0.5), answer=beat(0.65,1.05)
            p.sy -= press*0.025; p.sx += press*0.012; p.y -= press*0.8
            p.y += answer*2*energy; p.joy=answer*0.55; p.roll=answer*0.035*energy
        case .annoyed:
            let v=window(t,0.15,1.85)
            p.open *= 1-v*0.35; p.anger=v*5; p.gaze.width = -v*1.4
            p.roll = -sin((t-0.4)*5)*beat(0.4,1.25)*0.035*energy
        case .dizzy:
            let v=beat(0.25,2.25), phase=t*4.8
            p.roll=sin(phase)*v*0.09*energy; p.x=sin(phase)*v*1.5
            p.gaze=CGSize(width:cos(phase)*v*2,height:sin(phase)*v)
            p.open *= 1-v*0.35
        case .working:
            let focus = pulse(phase,0.3,2.3)
            p.loading=0.55*engaged; p.fold=focus*0.55; p.joy=0.08
            switch hero {
            case .sig: p.gaze.width=sin(t*0.95)*1.8; p.roll=sin(t*0.95)*0.012
            case .rita: p.gaze=CGSize(width:0.25*focus,height:0.5*focus); p.y = -focus*0.8; p.roll = -focus*0.025
            case .ada: p.gaze=CGSize(width:focus*1.2,height:focus*1.6); p.y = -pulse(phase,1.2,0.65)*0.8
            case .gantt: p.gaze=CGSize(width:focus*0.7,height:focus*0.8); p.y = -pulse(phase,1.3,0.65)*1.0
            case .elinor: p.y += sin(t*1.05)*0.55; p.roll=sin(t*0.8)*0.01
            case .toni: p.roll=sin(t*2.5)*0.028; p.y += pulse(phase,0.6,1.2)*0.6
            }
        case .thinking, .voiceThinking:
            let ponder=window(phase,0.4,2.6,ramp:0.75)
            p.loading=0.6*engaged; p.roll=ponder*0.035*energy
            p.gaze=CGSize(width:-ponder*1.3,height:-ponder*0.7); p.open *= 1-ponder*0.15
        case .searching:
            let look = sin(t*1.1)*engaged
            p.gaze=CGSize(width:look*2.2,height:-0.4); p.roll = -look*0.018; p.loading=0.65*engaged
        case .approval, .question:
            let ask=window(phase,0.15,2.9,ramp:0.55)
            p.roll=ask*0.055*energy; p.gaze.height = -ask*0.6; p.open *= 1+ask*0.06
            p.y += pulse(phase,0.15,0.9)*0.7
        case .failure:
            let sigh=window(t,0.15,1.85,ramp:0.5)
            p.y -= sigh*1.6; p.sy -= sigh*0.018; p.roll = -sigh*0.035
            p.open *= 1-sigh*0.3; p.gaze.height=sigh*0.7
        case .completed:
            if hero == .ada {
                let focus=window(t,0.12,1.65,ramp:0.45)
                p.gaze=CGSize(width:2.3*focus,height:2.5*focus); p.roll = -focus*0.022
                p.x=focus*0.7; p.open *= 1-focus*0.12
                p.joy=beat(1.85,0.85)*0.5
            } else {
                let prepare=beat(0.12,0.35), lift=beat(0.46,0.85)
                p.sy -= prepare*0.025; p.sx += prepare*0.012; p.y -= prepare*0.8
                p.y += lift*4.5*energy; p.roll=sin(t*4.5)*lift*0.04*energy
                p.joy=window(t,0.5,2)*0.65; p.fold=lift*0.55
                nod(1.65,0.7)
            }
        case .rateLimit:
            p.open *= 0.78; p.roll = -0.025*engaged; p.gaze.height=0.4
        case .sleeping:
            p.open=0.06; p.sy=0.985+sin(t*1.15)*0.006
            p.y=34*(p.sy-1); p.roll=0.022+sin(t*0.6)*0.004
        case .love:
            let v=window(t,0.2,1.85,ramp:0.45)
            p.joy=v*0.68; p.roll=sin(t*2)*v*0.045*energy; p.y += v*0.8
        case .surprised:
            let recoil=beat(0.15,0.65), settle=beat(0.85,1.0)
            p.y += recoil*3*energy; p.open *= 1+recoil*0.12
            p.sy += recoil*0.02; p.roll = -settle*0.025; p.gaze.height = -settle*0.5
        case .proud:
            let v=window(t,0.2,1.9,ramp:0.5)
            p.y += v*1.2; p.sy += v*0.014; p.joy=v*0.5; p.roll=v*0.025*energy
        case .wink:
            let v=beat(0.45,0.7); p.wink=v*0.94; p.roll=v*0.035*energy; p.joy=v*0.25
        case .yawn:
            let v=beat(0.3,1.75); p.open *= 1-v*0.92
            p.sy += v*0.025; p.y += v*0.9; p.roll = -v*0.025
        case .happy:
            let v=beat(0.25,1.4); p.joy=v*0.7; p.y += v*2.2*energy
            p.roll=sin(t*3.5)*v*0.035*energy; p.fold=v*0.35
        case .listening, .compactListening:
            let v=pulse(phase,1.3,0.9); p.roll = -0.025*engaged
            p.y -= v*0.55; p.joy=v*0.15; p.gaze.height = -0.3*engaged
        case .speaking:
            let phrase=pulse(phase,0.2,1.0)+pulse(phase,1.65,1.4)
            p.y += phrase*0.7*energy; p.roll=sin(t*2.3)*phrase*0.023*energy
            p.joy=phrase*0.22; p.fold=phrase*0.25
        case .listeningEnd, .understood: nod(0.18,0.85); p.joy += beat(0.8,1.0)*0.3
        case .dance:
            let beat=t * .pi*2*92/60, amplitude=rigSmooth(t/0.6)
            p.roll=sin(beat/2)*0.065*energy*amplitude
            p.x=sin(beat/2)*1.7*energy*amplitude; p.y += (1-cos(beat))*1.1*energy*amplitude
            p.joy=0.45*amplitude; p.fold=sin(beat/2-0.5)*0.45*amplitude
        case .fileHover:
            p.gaze=CGSize(width:sin(t*0.9)*1.6,height:-1.3*engaged); p.roll=sin(t*0.9)*0.012
        case .fileOpen:
            p.gaze.height = -rigSmooth(t/0.5); p.open *= 1+rigSmooth(t/0.5)*0.07
        case .fileReceive, .gulp:
            let stretch=beat(0.05,0.4), receipt=beat(0.43,0.6)
            p.gaze.height = -stretch; p.sy += stretch*0.018-receipt*0.02
            p.sx -= stretch*0.006-receipt*0.008; p.y += stretch*0.6-receipt*0.7
            p.joy=receipt*0.5; p.fold=receipt*0.3
        case .fileProcessing:
            let process=pulse(phase,0.35,1.6)+pulse(phase,2.3,1.2)
            p.loading=0.65*engaged; p.joy=process*0.16; p.fold=process*0.4; p.y -= process*0.5
        case .uploadProgress:
            p.gaze=CGSize(width:(rigSmooth(t/3.2)*2-1)*1.5,height:0.9)
            p.y += sin(t*1.5)*0.3; p.loading=0.35
        case .uploadComplete:
            nod(0.25); p.joy=beat(0.5,1.45)*0.65; p.y += beat(0.75,0.9)*2.0*energy
        case .fileReturn:
            let choose=window(t,0.15,1.65,ramp:0.5)
            p.gaze.width=choose*1.6; p.roll = -choose*0.035; nod(1.65)
        case .accessoryInertia:
            let swing=sin(t*1.7)*rigSmooth(t/0.6)
            p.roll=swing*0.045*energy; p.fold=sin(t*1.7-0.45)*0.6*rigSmooth(t/0.6)
        case .accessoryChange:
            let adjust=beat(0.3,1.35)
            p.y -= adjust*0.8; p.gaze.height=adjust*0.6; p.fold=adjust*0.8; nod(1.7)
        case .flyOut:
            let travel=window(t,0.25,2.35,ramp:0.65)
            p.x=travel*22; p.y = -travel*13; p.roll = -sin(t*2)*travel*0.035
            p.gaze.width = -travel*1.4
        case .alert:
            let approach=1-rigSmooth(t/0.7)
            p.x=approach*22; p.y = -approach*13; p.opacity=1-approach
            p.open *= 1+beat(0.65,0.8)*0.1; nod(1.5)
        case .interrupted:
            let wave=beat(0.15,0.85), pause=window(t,1.1,2.3)
            p.roll=wave*0.045*energy-pause*0.035; p.joy=wave*0.4
            p.gaze=CGSize(width:-pause*1.5,height:-pause*0.6); p.loading=pause*0.5
        case .badgeChange:
            p.loading=1-rigSmooth((t-0.5)/0.45); p.roll=beat(0.8,1.3)*0.045
            p.gaze.height = -beat(0.6,1.5)*0.5
        case .hello:
            let first=beat(0.12,0.85), second=beat(1.05,0.8)
            p.joy=(first+second*0.5)*0.55; p.fold=first*0.65
            switch hero {
            case .sig: p.y += first*2; p.roll=sin(t*4)*first*0.045
            case .rita: p.y -= first; p.roll = -first*0.04; p.wink=second*0.8
            case .ada: p.y += first*2.3+second*1.2; p.gaze.height=first*0.4
            case .gantt: p.y -= first*1.3; p.roll = -first*0.018; p.joy=first*0.4
            case .elinor: p.y += first*0.8; p.roll=first*0.025; p.joy=0.15*first
            case .toni: p.roll=sin(t*4.3)*first*0.065; p.y += first*1.2
            }
        case .voiceEnd:
            nod(0.15); p.roll = -beat(0.75,1.3)*0.02
        case .waking:
            let stretch=beat(0.25,1.5)
            p.open=0.06+rigSmooth(t/1.1)*0.94
            p.sy += stretch*0.026; p.y += stretch*0.9; p.joy=beat(1.5,0.9)*0.25
        case .stroll:
            let phase=t * .pi*2/6, ramp=rigSmooth(t/0.65)
            p.x=sin(phase)*7*ramp; p.roll=sin(phase*2)*0.03*energy*ramp
            p.y += (1-cos(phase*4))*0.45*energy*ramp; p.gaze.width=cos(phase)*ramp*1.3
        }
        // Preserve closed Elinor eyes and the small eyes inside Rita's lenses.
        if hero == .elinor { p.wink=0; p.joy=min(0.18,p.joy) }
        if hero == .rita { p.gaze.width=max(0,min(0.4,p.gaze.width)); p.gaze.height=max(-0.4,min(0.5,p.gaze.height)); p.joy*=0.5 }
        p.open=max(0.06,min(1.15,p.open))
        p.yaw=0; p.pitch=0
        return p
    }
}
