//
//  VgTests.swift
//  VgTests
//
//  Created by Marc Prud'hommeaux on 6/9/18.
//  Copyright © 2018 Glimpse I/O. All rights reserved.
//

import ChannelZ
import XCTest
@testable import Vg

class VgTests: XCTestCase {
    func testModel() throws {

    }
}

//extension Either : Equatable where T : Equatable, U : Equatable { }

/**
 * Base object for Vega's Axis and Axis Config.
 * All of these properties are both properties of Vega's Axis and Axis Config.
 */
public protocol VgAxisBase : Codable {
    /**
     * A boolean flag indicating if the domain (the axis baseline) should be included as part of the axis.
     *
     * __Default value:__ `true`
     */
    var domain: Bool? { get set }

    /**
     * A boolean flag indicating if grid lines should be included as part of the axis
     *
     * __Default value:__ `true` for [continuous scales](https://vega.github.io/vega-lite/docs/scale.html#continuous) that are not binned; otherwise, `false`.
     */
    var grid: Bool? { get set }

    /**
     * A boolean flag indicating if labels should be included as part of the axis.
     *
     * __Default value:__  `true`.
     */
    var labels: Bool? { get set }

    /**
     * Indicates if labels should be hidden if they exceed the axis range. If `false `(the default) no bounds overlap analysis is performed. If `true`, labels will be hidden if they exceed the axis range by more than 1 pixel. If this property is a number, it specifies the pixel tolerance: the maximum amount by which a label bounding box may exceed the axis range.
     *
     * __Default value:__ `false`.
     */
    var labelBound: Choose2<Bool, Double>? { get set }

    /**
     * Indicates if the first and last axis labels should be aligned flush with the scale range. Flush alignment for a horizontal axis will left-align the first label and right-align the last label. For vertical axes, bottom and top text baselines are applied instead. If this property is a number, it also indicates the number of pixels by which to offset the first and last labels; for example, a value of 2 will flush-align the first and last labels and also push them 2 pixels outward from the center of the axis. The additional adjustment can sometimes help the labels better visually group with corresponding axis ticks.
     *
     * __Default value:__ `true` for axis of a continuous x-scale. Otherwise, `false`.
     */
    var labelFlush: Choose2<Bool, Double>? { get set }

    /**
     * The strategy to use for resolving overlap of axis labels. If `false` (the default), no overlap reduction is attempted. If set to `true` or `"parity"`, a strategy of removing every other label is used (this works well for standard linear axes). If set to `"greedy"`, a linear scan of the labels is performed, removing any labels that overlaps with the last visible label (this often works better for log-scaled axes).
     *
     * __Default value:__ `true` for non-nominal fields with non-log scales; `"greedy"` for log scales; otherwise `false`.
     */
//    var labelOverlap?: boolean | 'parity' | 'greedy';


    /**
     * The padding, in pixels, between axis and text labels.
     */
    var labelPadding: Double? { get set }

    /**
     * Boolean value that determines whether the axis should include ticks.
     */
    var ticks: Bool? { get set }

    /**
     * The size in pixels of axis ticks.
     *
     * @minimum 0
     */
    var tickSize: Double? { get set }

    /**
     * Max length for axis title if the title is automatically generated from the field's description.
     *
     * @minimum 0
     * __Default value:__ `undefined`.
     */
    var titleMaxLength: Double? { get set }

    /**
     * The padding, in pixels, between title and axis.
     */
    var titlePadding: Double? { get set }

    /**
     * The minimum extent in pixels that axis ticks and labels should use. This determines a minimum offset value for axis titles.
     *
     * __Default value:__ `30` for y-axis; `undefined` for x-axis.
     */
    var minExtent: Double? { get set }

    /**
     * The maximum extent in pixels that axis ticks and labels should use. This determines a maximum offset value for axis titles.
     *
     * __Default value:__ `undefined`.
     */
    var maxExtent: Double? { get set }
}
