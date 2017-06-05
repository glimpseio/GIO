//
//  GameViewController.swift
//  AV8
//
//  Created by Marc Prud'hommeaux on 11/20/16.
//  Copyright © 2016 io.glimpse. All rights reserved.
//

import UIKit
import Avionix

private let foregroundColor = UIColor.white
private let backgroundColor = UIColor.black

class MainViewController: UIViewController {
    let segments = UISegmentedControl()
    let picker = createPicker()

    let directionLabel = createLabel()

    let result1Label = createLabel(size: 25, weight: 0.4)
    let result1Value = createLabel(size: 50, weight: 1)
    let result2Label = createLabel(size: 25, weight: 0.4)
    let result2Value = createLabel(size: 50, weight: 1)

    let hwclabel = createLabel("", size: 15, weight: 0.2, align: .center)
    let xwclabel = createLabel("", size: 15, weight: 0.2, align: .center)
    let wcalabel = createLabel("", size: 15, weight: 0.2, align: .center)

    let spacerView = UIView()

    override func viewDidLoad() {
        dbg("loading controller")
        super.viewDidLoad()

        self.view.backgroundColor = backgroundColor
        self.view.tintColor = UIColor.lightGray

        self.vertical(pinh: true, views: segments, picker, directionLabel, result1Label, result1Value, result2Label, result2Value, hwclabel, xwclabel, wcalabel, spacerView)

        segments.isMomentary = true
        segments.insertSegment(withTitle: "Winds", at: 0, animated: false)
        segments.insertSegment(withTitle: "Windspeed", at: 1, animated: false)
        segments.insertSegment(withTitle: "Heading", at: 2, animated: false)
        segments.insertSegment(withTitle: "Airspeed", at: 3, animated: false)

        result1Label.font = UIFont.monospacedDigitSystemFont(ofSize: 25, weight: 0.2)
        result1Label.text = "Course"

        result1Value.font = UIFont.monospacedDigitSystemFont(ofSize: 50, weight: 1)
        result1Value.text = "°"

        result2Label.font = UIFont.monospacedDigitSystemFont(ofSize: 25, weight: 0.2)
        result2Label.text = "Groundspeed"

        result2Value.font = UIFont.monospacedDigitSystemFont(ofSize: 50, weight: 1)
        result2Value.text = "\(knotsSuffix)"

        picker.dataSource = self
        picker.delegate = self
        realignAngles()

        spacerView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    let fmt: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.maximumFractionDigits = 0
        return fmt
    }()

    /// When the user selects or scrolls past a component, perform the triangle calculations
    func updateComponent(_ component: Int) {

        let crsn = fmt.string(from: NSDecimalNumber(decimal: crs.compassDirection)) ?? "???"
        result1Value.text = "\(crsn)°"

        let gsn = fmt.string(from: NSDecimalNumber(decimal: gs.knots)) ?? "???"
        result2Value.text = "\(gsn)\(knotsSuffix)"

        let hwcn = fmt.string(from: NSDecimalNumber(decimal: abs(hwc.knots))) ?? "???"
        hwclabel.text = "\(hwcn)\(knotsSuffix) " + (hwc.knots >= 0 ? "headwind" : "tailwind")

        let xwcn = fmt.string(from: NSDecimalNumber(decimal: abs(xwc.knots))) ?? "???"
        xwclabel.text = "\(xwcn)\(knotsSuffix) " + (xwc.knots < 0 ? "left " : xwc.knots > 0 ? "right " : "") + "crosswind"
//        xwclabel.textColor = abs(xwc.knots) <= 15 ? foregroundColor : UIColor.red

        let wcan = fmt.string(from: NSDecimalNumber(decimal: wca.degrees)) ?? "???" // note that WCA is not normalized
        wcalabel.text = "\(wcan)° wind correction angle"

//        hwclabel.textColor = xwc.knots >= 0 ? foregroundColor : UIColor.red

//        dbg("wind direction", wd, "windspeed", ws, "heading", hdg, "true airspeed", tas, "course", crs, "groundspeed", gs, "crsn", crsn, "gsn", gsn)

    }
}

extension MainViewController : TriangleComponents {
    var wd: Angle {
        return Angle.degree(Num((picker.selectedRow(inComponent: 0) + 1) % 360))
    }

    var ws: Speed {
        return Speed.knots(Num(picker.selectedRow(inComponent: 1)))
    }

    var hdg: Angle {
        return Angle.degree(Num((picker.selectedRow(inComponent: 2) + 1) % 360))
    }
    var tas: Speed {
        return Speed.knots(Num(picker.selectedRow(inComponent: 3)))
    }

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

//let knotsSuffix = "kn"
let knotsSuffix = "kt"


func createLabel(_ text: String = "", size: CGFloat = 25, weight: CGFloat = 0.5, align: NSTextAlignment = .center) -> UILabel {
    let label = UILabel()
    label.font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    label.textColor = foregroundColor
    label.adjustsFontSizeToFitWidth = true
    label.textAlignment = align
    label.text = text
    return label
}

func createPicker() -> UIPickerView {
    let picker = UIPickerView()
    return picker
}

private let pickerAttributes = [NSFontAttributeName: UIFont.monospacedDigitSystemFont(ofSize: 25, weight: 0.2), NSForegroundColorAttributeName : foregroundColor]

extension MainViewController : UIPickerViewDataSource, UIPickerViewDelegate {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 4
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 || component == 2 {
            return 360 * 10
        } else {
            return 251
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        updateComponent(component)

        let label = view as? UILabel ?? createLabel()

        let astr: NSAttributedString
        if component == 0 || component == 2 {
            let angle: Int = (row % 360) + 1
            astr = NSAttributedString(string: "\(angle)°", attributes: pickerAttributes)
        } else {
            astr = NSAttributedString(string: "\(row)\(knotsSuffix)", attributes: pickerAttributes)
        }
        label.attributedText = astr
        label.adjustsFontSizeToFitWidth = true
        return label
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        dbg(component, row)
        if component == 0 || component == 2 {
            // reset to the center of the spinner
            realignAngles()
        }
        updateComponent(component)
    }

    /// UIPickerView does not support "wrapping" values, so we create the illusion by repeating the
    /// angle rangle multiple times; whenever the user selects a new angle, jump back to the middle
    /// to maintain the illusion
    public func realignAngles() {
        for component in [0, 2] {
            let selected = picker.selectedRow(inComponent: component)
            let mod = selected % 360
            let count = picker.numberOfRows(inComponent: component)
            let jump = (count/2) + mod
            if selected != jump {
                dbg("jumping", selected, jump)
                DispatchQueue.main.async {
                    self.picker.selectRow(jump, inComponent: component, animated: false)
                }
            }
        }
    }
}

public extension UIViewController {
    public func vertical(pinh: Bool, views: UIView...) {
        for v in views {
            v.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(v)
        }

        for (i, v) in views.enumerated() {
            if pinh {
                v.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                v.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            }
            if i == 0 {
                v.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            } else {
                v.topAnchor.constraint(equalTo: views[i-1].bottomAnchor).isActive = true
            }
            if i == views.count - 1 {
                v.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
            }
        }
    }

    public func horizontal(pinv: Bool, equal: Bool = false, spacing: CGFloat = 0, views: UIView...) {
        for v in views {
            v.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(v)
        }

        for (i, v) in views.enumerated() {
            if pinv {
                v.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
                v.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
            }
            if i == 0 {
                v.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            } else {
                v.leadingAnchor.constraint(equalTo: views[i-1].trailingAnchor, constant: spacing).isActive = true
                if equal {
                    v.widthAnchor.constraint(equalTo: views[i-1].widthAnchor).isActive = true
                }
            }
            if i == views.count - 1 {
                v.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            }
        }
    }

}
