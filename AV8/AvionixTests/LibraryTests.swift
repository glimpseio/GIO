//
//  AvionixTests.swift
//  AvionixTests
//
//  Created by Marc Prud'hommeaux on 11/20/16.
//  Copyright © 2016 io.glimpse. All rights reserved.
//

import XCTest
import Avionix

class AvionixTests: XCTestCase {

    func testCalculations() {
        do {
            for x in [Num.pi, 0, 1, -1] {
                assertEqual(Distance.nauticalMile(x).nauticalMiles, x)
                assertEqual(Distance.statueMile(x).statueMiles, x)
                assertEqual(Distance.meter(x).meters, x)
                assertEqual(Distance.foot(x).feet, x)
            }
        }

        do {
            assertEqual(Angle.degree(0).radians, 0)
            assertEqual(Angle.degree(180).radians, .pi)
            assertEqual(Angle.degree(360).radians, .pi * 2)
        }

        do {
            let x = Distance.nauticalMile(1) / Duration.hour(1)
            assertEqual(1, x.knots)
        }

        do {
            let speed = Speed(distance: .meter(1), duration: .second(0))
            assertEqual(.nan, speed.knots)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(100), angle: .degree(90)), airspeed: .knots(100), heading: .degree(0))
            assertEqual(090, x.compassDirection, accuracy: 0.0000000001)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(10), angle: .degree(360)), airspeed: .knots(10), heading: .degree(180))
            assertEqual(0, x.compassDirection, accuracy: 0.0000000001)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(10), angle: .degree(180)), airspeed: .knots(10), heading: .degree(360))
            assertEqual(360, x.compassDirection, accuracy: 0.0000000001)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(15), angle: .degree(215)), airspeed: .knots(130), heading: .degree(260))
            assertEqual(360-005, x.compassDirection, accuracy: 0.6)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(20), angle: .degree(050)), airspeed: .knots(105), heading: .degree(350))
            assertEqual(010, x.compassDirection, accuracy: 0.6)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(33), angle: .degree(123)), airspeed: .knots(77), heading: .degree(234))
            assertEqual(360-024, x.compassDirection, accuracy: 0.6)
        }

        do {
            let x = windCorrectionAngle(wind: Vector(speed: .knots(40), angle: .degree(300)), airspeed: .knots(110), heading: .degree(200))
            assertEqual(021, x.compassDirection, accuracy: 0.6)
        }

        do {
//            let wind = calcWind(crs: <#T##Angle#>, hd: <#T##Angle#>, tas: <#T##Speed#>, gs: <#T##Speed#>)
        }
    }

    func assertEqual(_ num1: Num, _ num2: Num, accuracy: Num? = nil, file: StaticString = #file, line: UInt = #line) {
        if num1 == num2 {
            return
        }

        if let accuracy = accuracy {
            XCTAssertEqualWithAccuracy(num2.doubleValue, num2.doubleValue, accuracy: accuracy.doubleValue, file: file, line: line)
        } else {
            XCTAssertEqual(num1.doubleValue, num2.doubleValue, file: file, line: line)
        }
    }
}

