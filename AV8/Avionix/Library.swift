//
//  AVX.swift
//  AV8
//
//  Created by Marc Prud'hommeaux on 11/20/16.
//  Copyright © 2016 io.glimpse. All rights reserved.
//

import Foundation

/// Issue a debug message
public func dbg(_ items: Any..., functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
    let msg = items.map({ String(describing: $0) }).joined(separator: " ")
    let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())

    let fn = (fileName.description as NSString).lastPathComponent

    func ptrunc(_ val: Int?, len: Int = 2) -> String {
        var str = "\(val ?? 0)"
        while str.characters.count < len {
            str = "0" + str
        }
        while str.characters.count > len {
            str = String(str.characters.dropLast())
        }
        return str
    }
    print("\(ptrunc(comp.hour)):\(ptrunc(comp.minute)):\(ptrunc(comp.second)).\(ptrunc(comp.nanosecond, len: 3)) \(fn):\(lineNumber) \(functionName): \(msg)")
}

@available(*, deprecated)
public func die<T>(_ msg: String = "DIE") -> T { fatalError(msg) }

@available(*, deprecated)
public func FIXME<T>(_ value: T) -> T { return value }

//public typealias Num = Double
public typealias Num = Foundation.Decimal

public enum Distance {
    case meter(Num)
    case foot(Num)
    case statueMile(Num)
    case nauticalMile(Num)

    public static let feetPerMeter: Num = 3.2808
    public static let metersPerNauticalMile: Num = 1852
    /// “exactly 1,609.344 metres by international agreement in 1959”
    public static let metersPerStatuteMile: Num = 1609.344

    public var meters: Num {
        switch self {
        case .meter(let m): return m
        case .foot(let ft): return ft / Distance.feetPerMeter
        case .statueMile(let sm): return Distance.metersPerStatuteMile * sm
        case .nauticalMile(let nm): return Distance.metersPerNauticalMile * nm
        }
    }

    public var nauticalMiles: Num {
        return meters / Distance.metersPerNauticalMile
    }

    public var statueMiles: Num {
        return meters / Distance.metersPerStatuteMile
    }

    public var feet: Num {
        return meters * Distance.feetPerMeter
    }

}

public enum Duration {
    case second(Num)
    case minute(Num)
    case hour(Num)

    public static let secondsPerMinute: Num = 60 * 60
    public static let minutesPerHour: Num = 60

    public var seconds : Num {
        switch self {
        case .second(let s): return s
        case .minute(let m): return m * Duration.secondsPerMinute
        case .hour(let h): return h * Duration.secondsPerMinute * Duration.minutesPerHour
        }
    }

    public var minutes : Num {
        return seconds / Duration.secondsPerMinute
    }

    public var hours : Num {
        return minutes / Duration.minutesPerHour
    }
}

public enum Angle {
    case degree(Num)
    case radian(Num)

    private func normalizeDegrees(_ d: Num) -> Num {
        if !d.isFinite { return d }
        var d = d
        while d <= 0.0 { d += 360.0 }
        while d > 360.0 { d -= 360.0 }
        return d
    }

    /// The degrees normalized from 0° < n <= 360°
    public var compassDirection: Num {
        return normalizeDegrees(degrees)
    }

    public var degrees: Num {
        switch self {
        case .degree(let d): return d
        case .radian(let r): return r * 180 / Num.pi
        }
    }

    public var radians: Num {
        switch self {
        case .degree(let d): return d / (180 / Num.pi)
        case .radian(let r): return r
        }
    }
}

public enum Quantity {
    case gallon(Num)
    case liter(Num)

    public static let litersPerGallon : Num = 3.785411784

    public var liters : Num {
        switch self {
        case .gallon(let g): return Quantity.litersPerGallon * g
        case .liter(let l): return l
        }
    }
}

public enum Temperature {
    case fahrenheit(Num)
    case celsius(Num)
    case kelvin(Num)

    public var celsius : Num {
        switch self {
        case .fahrenheit(let f): return ((f - 32) * 5) / 9
        case .celsius(let c): return c
        case .kelvin(let k): return k + 273.15
        }
    }
}

/// A speed is the product of distance and duration
public struct Speed {
    public let distance: Distance
    public let duration: Duration

    public init(distance: Distance, duration: Duration) {
        self.distance = distance
        self.duration = duration
    }

    public var knots: Num {
        return distance.nauticalMiles / duration.hours
    }

    public static func knots(_ nmph: Num) -> Speed {
        return Speed(distance: .nauticalMile(nmph), duration: .hour(1))
    }

    public static func milesPerHour(_ mph: Num) -> Speed {
        return Speed(distance: .statueMile(mph), duration: .hour(1))
    }

    public static func metersPerSecond(_ mps: Num) -> Speed {
        return Speed(distance: .meter(mps), duration: .second(1))
    }

}

/// Divides one speed by the other
public func /(lhs: Speed, rhs: Speed) -> Num {
    return lhs.knots / rhs.knots
}

/// Divides one speed by the other
public func *(lhs: Speed, rhs: Speed) -> Num {
    return lhs.knots * rhs.knots
}

/// Creates speed from distance and duration
public func /(lhs: Distance, rhs: Duration) -> Speed {
    return Speed(distance: lhs, duration: rhs)
}

/// A vector is the product of speed and angle
public struct Vector {
    public let speed: Speed
    public let angle: Angle

    public init(speed: Speed, angle: Angle) {
        self.speed = speed
        self.angle = angle
    }
}

public extension Decimal {
    /// The built-in Decimal.doubleValue is internal
    public var doubleValue : Double { return (self as NSDecimalNumber).doubleValue }
}

/// Transform a Decimal based on a Double transformation function and one argument; rounding & truncation errors to Doubles will occur
private func dfun1(_ num: Decimal, _ f: (Double) -> Double) -> Decimal {
    return Decimal(f(num.doubleValue))
}

/// Transform a Decimal based on a Double transformation function and two arguments; rounding & truncation errors to Doubles will occur
private func dfun2(_ num: Decimal, _ arg: Decimal, _ f: (Double, Double) -> Double) -> Decimal {
    return Decimal(f(num.doubleValue, arg.doubleValue))
}

// MARK: Decimal-based Trigonometric functions

private func sin(_ num: Decimal) -> Decimal { return dfun1(num, sin) }
private func asin(_ num: Decimal) -> Decimal { return dfun1(num, asin) }
private func cos(_ num: Decimal) -> Decimal { return dfun1(num, cos) }
private func tan(_ num: Decimal) -> Decimal { return dfun1(num, tan) }
private func atan(_ num: Decimal) -> Decimal { return dfun1(num, atan) }
private func acos(_ num: Decimal) -> Decimal { return dfun1(num, acos) }
private func sqrt(_ num: Decimal) -> Decimal { return dfun1(num, sqrt) }
private func atan2(_ num: Decimal, _ exp: Decimal) -> Decimal { return dfun2(num, exp, atan2) }

public func ^(lhs: Decimal, rhs: Int) -> Decimal {
    return pow(lhs, rhs)
}

public func ^(lhs: Decimal, rhs: Decimal) -> Decimal {
    return pow(lhs, Int(rhs.doubleValue))
}

// MARK: Aviation Formulary V1.46 by Ed Williams from http://williams.best.vwh.net/avform.htm#Wind


public func crosswindComponent(wind: Vector, course: Angle) -> Speed {
//    XW= WS*sin(WD-RD)     (positive=  wind from right)
    return .knots(wind.speed.knots * sin(wind.angle.radians - course.radians))
}

public func headwindComponent(wind: Vector, course: Angle) -> Speed {
    //    HW= WS*cos(WD-RD)     (tailwind negative)
    return .knots(wind.speed.knots * cos(wind.angle.radians - course.radians))
}

/// Calculated the wind correction angle from the given parameters
///
/// - Parameters:
///   - wind: the speed and direction of the wind
///   - airspeed: the speed of the plane throug the air
///   - course: the desired course of the airplane
public func windCorrectionAngle(wind: Vector, airspeed: Speed, heading: Angle) -> Angle {
    // WCA=atan2(WS*sin(HD-WD),TAS-WS*cos(HD-WD))  (*)
    return .radian(-atan2(wind.speed.knots * sin(heading.radians - wind.angle.radians), airspeed.knots - wind.speed.knots * cos(heading.radians - wind.angle.radians)))

    // “(*) WCA=asin((WS/GS)*sin(HD-WD)) works if the wind correction angle is less than 90 degrees, which will always be the case if WS < TAS. The listed formula works in the general case”
    //return .radian(asin((wind.speed / airspeed) * sin(wind.angle.radians - course.radians)))
}

// Let CRS=course, HD=heading, WD=wind direction (from), TAS=True airpeed, GS=groundspeed, WS=windspeed.
// (crs: Angle, hdg: Angle, wd: Angle, tas: Speed, gs: Speed, ws: Speed)

///// Calculates wind vector (wind direction & windspeed) from a heading+airspeed and course+groundspeed
//public func calcWind(air: Vector, ground: Vector) -> Vector {
//    let HD = air.angle.radians
//    let TAS = air.speed.knots
////    let WD = wind.angle.radians
////    let WS = wind.speed.knots
//    let CRS = ground.angle.radians
//    let GS = ground.speed.knots
//
//    let WS = sqrt( (TAS-GS)^2 + 4*TAS*GS*(sin((HD-CRS)/2))^2 )
//    let WD = CRS + atan2(TAS*sin(HD-CRS), TAS*cos(HD-CRS)-GS)
//
//    return Vector(speed: .knots(WS), angle: .radian(WD))
//}
//
///// Calculates ground vector (course & groundspeed) from a heading, airspeed, and wind vector
//public func calcGround(air: Vector, wind: Vector) -> Vector {
//    let HD = air.angle.radians
//    let TAS = air.speed.knots
//    let WD = wind.angle.radians
//    let WS = wind.speed.knots
////    let CRS = ground.angle.radians
////    let GS = ground.speed.knots
//
//    let WCA = atan2(WS*sin(HD-WD),TAS-WS*cos(HD-WD))
//    let CRS = HD+WCA
//    let GS = sqrt(WS^2 + TAS^2 - 2*WS*TAS*cos(HD-WD))
//    return Vector(speed: .knots(GS), angle: .radian(CRS))
//}

//public extension Speed {
//    public static func groundspeed(directions: Direction.Pair, speeds: (tas: Speed, ws: Speed)) -> Speed {
//        return die()
//    }
//
//    public static func windspeed(directions: Direction.Pair, speeds: (tas: Speed, gs: Speed)) -> Speed {
//        return die()
//    }
//
//    public static func airspeed(directions: Direction.Pair, speeds: (gs: Speed, ws: Speed)) -> Speed {
//        return die()
//    }
//}
//
//public extension Angle {
//    public static func heading(velocities: Velocity.Pair, angles: (crs: Angle, wd: Angle)) -> Angle {
//        return die()
//    }
//
//    public static func course(velocities: Velocity.Pair, angles: (hdg: Angle, wd: Angle)) -> Angle {
//        return die()
//    }
//
//    public static func winddirection(velocities: Velocity.Pair, angles: (crs: Angle, hdg: Angle)) -> Angle {
//        return die()
//    }
//}

public func groundspeed(hdg: Angle, wd: Angle, tas: Speed, ws: Speed) -> Speed {
    return .knots(sqrt((ws.knots ^ 2) + (tas.knots ^ 2) - (2 * ws.knots * tas.knots * cos(hdg.radians - wd.radians))))
}

public func course(hdg: Angle, wd: Angle, tas: Speed, ws: Speed) -> Angle {
    return .radian(hdg.radians + atan2(ws.knots * sin(hdg.radians - wd.radians), tas.knots - ws.knots * cos(hdg.radians - wd.radians)))
}

private func groundspeed(crs: Angle, wd: Angle, tas: Speed, ws: Speed) -> Speed {
    return .knots(tas.knots * sqrt(1 - (swc(crs: crs, wd: wd, tas: tas, ws: ws)) ^ 2) - ws.knots * cos(wd.radians - crs.radians))
}

private func airspeed(crs: Angle, hdg: Angle, wd: Angle, gs: Speed, ws: Speed) -> Speed {
    return die()
}


private func windspeed(crs: Angle, hdg: Angle, tas: Speed, gs: Speed) -> Speed {
    return .knots(sqrt((tas.knots - gs.knots) ^ 2 + 4 * tas.knots * gs.knots * (sin((hdg.radians - crs.radians) / 2)) ^ 2))
}

private func winddirection(crs: Angle, hdg: Angle, tas: Speed, gs: Speed) -> Angle {
    return .radian(crs.radians + atan2(tas.knots * sin(hdg.radians - crs.radians), tas.knots * cos(hdg.radians - crs.radians) - gs.knots))
}

private func swc(crs: Angle, wd: Angle, tas: Speed, ws: Speed) -> Num {
    return (ws.knots / tas.knots) * sin(wd.radians - crs.radians)
}

private func heading(crs: Angle, wd: Angle, tas: Speed, ws: Speed) -> Angle {
    return .radian(crs.radians + asin(swc(crs: crs, wd: wd, tas: tas, ws: ws)))
}

private func wind(air: Vector, ground: Vector) -> Vector {
    return die()
}

private func air(wind: Vector, ground: Vector) -> Vector {
    return die()
}

//private func ground(air: Vector, wind: Vector) -> Vector {
//    let gs = groundspeed(hdg: air.angle, wd: wind.angle, tas: air.speed, ws: wind.speed)
//    let crs = course(hdg: <#T##Angle#>, wd: <#T##Angle#>, tas: <#T##Speed#>, ws: <#T##Speed#>)
//    return Vector(speed: gs, angle: <#T##Angle#>)
//}


// CRS=course, HD=heading, WD=wind direction (from), TAS=True airpeed, GS=groundspeed, WS=windspeed.

public enum Granularity {
    case coarse, normal, fine
}

public enum Direction {
    case heading(to: Angle)
    case wind(from: Angle)
    case course(to: Angle)

    public enum Pair {
        case windCourse(wind: Angle, course: Angle)
        case windHeading(wind: Angle, heading: Angle)
        case courseHeading(course: Angle, heading: Angle)
    }

    public var direction : Angle {
        switch self {
        case .heading(let s): return s
        case .wind(let s): return s
        case .course(let s): return s
        }
    }
}

public enum Velocity {
    case air(Speed)
    case wind(Speed)
    case ground(Speed)

    public enum Pair {
        case airWind(air: Speed, wind: Speed)
        case airGround(air: Speed, ground: Speed)
        case windGround(wind: Speed, ground: Speed)
    }

    public var speed : Speed {
        switch self {
        case .air(let s): return s
        case .wind(let s): return s
        case .ground(let s): return s
        }
    }
}

private func randomAngle() -> Angle {
    return Angle.degree(Num(arc4random_uniform(360)))
}

private func randomSpeed() -> Speed {
    return Speed.knots(Num(arc4random_uniform(200)))
}

/// Given any pair of directions (wind, course, or heading) and velocities (airspeed, windspeed, groundspeed),
/// calculates the vector of direction and speed
public func calculateTriangle(direction: Direction.Pair, velocity: Velocity.Pair) -> Vector {
    // complete triangle formula
    let triangle: (wd: Angle, hdg: Angle, crs: Angle, ws: Speed, tas: Speed, gs: Speed)

    switch (direction, velocity) {

    case let (.windHeading(wd, hdg), .airWind(tas, ws)):
        let gs: Speed = groundspeed(hdg: hdg, wd: wd, tas: tas, ws: ws)
        let crs: Angle = course(hdg: hdg, wd: wd, tas: tas, ws: ws)
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.gs, angle: triangle.crs)

    case let (.windCourse(wd, crs), .windGround(ws, gs)):
        let hdg = randomAngle()
        let tas = randomSpeed()
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.tas, angle: triangle.hdg)

    case let (.courseHeading(crs, hdg), .airGround(tas, gs)):
        let wd: Angle = winddirection(crs: crs, hdg: hdg, tas: tas, gs: gs)
        let ws = randomSpeed()
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.ws, angle: triangle.wd)

    case let (.windCourse(wd, crs), .airWind(tas, ws)):
        let hdg: Angle = heading(crs: crs, wd: wd, tas: tas, ws: ws)
        let gs: Speed = groundspeed(hdg: hdg, wd: wd, tas: tas, ws: ws)
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.gs, angle: triangle.hdg)
    case let (.windCourse(wd, crs), .airGround(tas, gs)):
        let hdg = randomAngle()
        let ws = randomSpeed()
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.ws, angle: triangle.hdg)
    case let (.windHeading(wd, hdg), .airGround(tas, gs)):
        let crs = randomAngle()
        let ws = randomSpeed()
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.ws, angle: triangle.crs)
    case let (.windHeading(wd, hdg), .windGround(ws, gs)):
        let crs = randomAngle()
        let tas = randomSpeed()
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.tas, angle: triangle.crs)
    case let (.courseHeading(crs, hdg), .airWind(tas, ws)):
        let gs = randomSpeed()
        let wd: Angle = winddirection(crs: crs, hdg: hdg, tas: tas, gs: gs)
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.gs, angle: triangle.wd)
    case let (.courseHeading(crs, hdg), .windGround(ws, gs)):
        let tas = randomSpeed()
        let wd: Angle = winddirection(crs: crs, hdg: hdg, tas: tas, gs: gs)
        triangle = (wd: wd, hdg: hdg, crs: crs, ws: ws, tas: tas, gs: gs)
        return Vector(speed: triangle.tas, angle: triangle.wd)
    }
}

public struct TriangleModel {
    var v1, v2, v3: Velocity
    var d1, d2, d3: Direction

    public init() {
        v1 = Velocity.air(Speed.knots(.nan))
        d1 = Direction.heading(to: Angle.degree(.nan))
        v2 = Velocity.wind(Speed.knots(.nan))
        d2 = Direction.wind(from: Angle.degree(.nan))
        v3 = Velocity.ground(Speed.knots(.nan))
        d3 = Direction.course(to: Angle.degree(.nan))
    }
}

public protocol TriangleComponents {
    var wd: Angle { get }
    var ws: Speed { get }
    var hdg: Angle { get }
    var tas: Speed { get }
    var crs: Angle { get }
    var gs: Speed { get }
    var wca: Angle { get }
    var xwc: Speed { get }
    var hwc: Speed { get }
}

public extension TriangleComponents {
//    var wd: Angle {
//        return Angle.degree(Num((picker.selectedRow(inComponent: 0) + 1) % 360))
//    }
//
//    var ws: Speed {
//        return Speed.knots(Num(picker.selectedRow(inComponent: 1)))
//    }
//
//    var hdg: Angle {
//        return Angle.degree(Num((picker.selectedRow(inComponent: 2) + 1) % 360))
//    }
//    var tas: Speed {
//        return Speed.knots(Num(picker.selectedRow(inComponent: 3)))
//    }

    var crs: Angle {
        return course(hdg: hdg, wd: wd, tas: tas, ws: ws)
    }

    var gs: Speed {
        return groundspeed(hdg: hdg, wd: wd, tas: tas, ws: ws)
    }

    var wca: Angle {
        return windCorrectionAngle(wind: Vector(speed: ws, angle: wd), airspeed: tas, heading: hdg)
    }

    var xwc: Speed {
        return crosswindComponent(wind: Vector(speed: ws, angle: wd), course: crs)
    }

    var hwc: Speed {
        return headwindComponent(wind: Vector(speed: ws, angle: wd), course: crs)
    }
}
