/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import Datadog

internal class DdRumTests: XCTestCase {
    private let mockNativeRUM = MockNativeRUM()
    private var rum: DdRum! // swiftlint:disable:this implicitly_unwrapped_optional

    private let randomTimestamp = Int64.random(in: 0...Int64.max)

    override func setUpWithError() throws {
        try super.setUpWithError()
        rum = DdRumImplementation { self.mockNativeRUM }
    }

    func testItInitializesNativeRumOnlyOnce() {
        // Given
        let expectation = self.expectation(description: "Initialize RUM once")

        let rum = DdRumImplementation { [unowned self] in
            expectation.fulfill()
            return self.mockNativeRUM
        }

        // When
        (0..<10).forEach { _ in rum.addTiming(name: "foo") }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testInternalTimestampKeyValue() {
        XCTAssertEqual(DdRumImplementation.timestampKey, RUMAttribute.internalTimestamp)
    }

    func testStartView() throws {
        rum.startView(key: "view key", name: "view name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startView(key: "view key", name: "view name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopView() throws {
        rum.stopView(key: "view key", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopView(key: "view key"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStartAction() throws {
        rum.startAction(type: "custom", name: "action name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopActionWithoutStarting() {
        rum.stopAction(timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 0)
    }

    func testStopAction() throws {
        rum.startAction(type: "custom", name: "action name", timestampMs: 0, context: [:])
        rum.stopAction(timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 2)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 2)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testAddAction() throws {
        rum.addAction(type: "scroll", name: "action name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addUserAction(type: .scroll, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStartResource() throws {
        rum.startResource(key: "resource key", method: "put", url: "some/url/string", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startResourceLoading(resourceKey: "resource key", httpMethod: .put, urlString: "some/url/string"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopResource() throws {
        rum.stopResource(key: "resource key", statusCode: 999, kind: "xhr", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopResourceLoading(resourceKey: "resource key", statusCode: 999, kind: .xhr))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopResourceWithExternalTimings() throws {
        let context: NSDictionary = [
            "foo": 123,
            "_dd.resource_timings": [
                "fetch": [
                    "startTime": 0,
                    "duration": 13
                ],
                "redirect": [
                    "startTime": 1,
                    "duration": 1
                ],
                "dns": [
                    "startTime": 3,
                    "duration": 1
                ],
                "connect": [
                    "startTime": 5,
                    "duration": 1
                ],
                "ssl": [
                    "startTime": 7,
                    "duration": 1
                ],
                "firstByte": [
                    "startTime": 9,
                    "duration": 1
                ],
                "download": [
                    "startTime": 11,
                    "duration": 1
                ]
            ]
        ]

        rum.stopResource(key: "resource key", statusCode: 999, kind: "xhr", timestampMs: randomTimestamp, context: context)

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 2)

        XCTAssertEqual(
            mockNativeRUM.calledMethods.first,
            .addResourceMetrics(
                resourceKey: "resource key",
                fetch: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 0),
                    end: nanoTimeToDate(timestampNs: 13)
                ),
                redirection: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 1),
                    end: nanoTimeToDate(timestampNs: 2)
                ),
                dns: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 3),
                    end: nanoTimeToDate(timestampNs: 4)
                ),
                connect: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 5),
                    end: nanoTimeToDate(timestampNs: 6)
                ),
                ssl: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 7),
                    end: nanoTimeToDate(timestampNs: 8)
                ),
                firstByte: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 9),
                    end: nanoTimeToDate(timestampNs: 10)
                ),
                download: MockNativeRUM.Interval(
                    start: nanoTimeToDate(timestampNs: 11),
                    end: nanoTimeToDate(timestampNs: 12)
                ),
                responseSize: nil
            )
        )

        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopResourceLoading(resourceKey: "resource key", statusCode: 999, kind: .xhr))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 2)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testAddError() throws {
        rum.addError(message: "error message", source: "webview", stacktrace: "error trace", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addError(message: "error message", source: .webview, stack: "error trace"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = try XCTUnwrap(mockNativeRUM.receivedAttributes.last)
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testAddTiming() throws {
        rum.addTiming(name: "timing")

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addTiming(name: "timing"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 0)
    }

    private func nanoTimeToDate(timestampNs: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(fromNs: timestampNs))
    }
}

private class MockNativeRUM: NativeRUM {
    struct Interval: Equatable {
        let start: Date?
        let end: Date?
    }

    enum CalledMethod: Equatable {
        case startView(key: String, name: String?)
        case stopView(key: String)
        case addError(message: String, source: RUMErrorSource, stack: String?)
        case startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String)
        case stopResourceLoading(resourceKey: String, statusCode: Int, kind: RUMResourceType)
        case startUserAction(type: RUMUserActionType, name: String)
        case stopUserAction(type: RUMUserActionType, name: String?)
        case addUserAction(type: RUMUserActionType, name: String)
        case addTiming(name: String)
        case addResourceMetrics(resourceKey: String,
                                fetch: Interval,
                                redirection: Interval,
                                dns: Interval,
                                connect: Interval,
                                ssl: Interval,
                                firstByte: Interval,
                                download: Interval,
                                responseSize: Int64?)
    }

    private(set) var calledMethods = [CalledMethod]()
    private(set) var receivedAttributes = [[String: Encodable]]()

    // swiftlint:disable force_cast
    func startView(key: String, name: String?, attributes: [String: Encodable]) {
        calledMethods.append(.startView(key: key, name: name))
        receivedAttributes.append(attributes)
    }
    func stopView(key: String, attributes: [String: Encodable]) {
        calledMethods.append(.stopView(key: key))
        receivedAttributes.append(attributes)
    }
    func addError(message: String, source: RUMErrorSource, stack: String?, attributes: [String: Encodable], file: StaticString?, line: UInt?) {
        calledMethods.append(.addError(message: message, source: source, stack: stack))
        receivedAttributes.append(attributes)
    }

    func startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String, attributes: [String: Encodable]) {
        calledMethods.append(.startResourceLoading(resourceKey: resourceKey, httpMethod: httpMethod, urlString: urlString))
        receivedAttributes.append(attributes)
    }
    func stopResourceLoading(resourceKey: String, statusCode: Int?, kind: RUMResourceType, size: Int64?, attributes: [String: Encodable]) {
        calledMethods.append(.stopResourceLoading(resourceKey: resourceKey, statusCode: statusCode ?? 0, kind: kind))
        receivedAttributes.append(attributes)
    }
    func startUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable]) {
        calledMethods.append(.startUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
    func stopUserAction(type: RUMUserActionType, name: String?, attributes: [String: Encodable]) {
        calledMethods.append(.stopUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
    func addUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable]) {
        calledMethods.append(.addUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
    func addTiming(name: String) {
        calledMethods.append(.addTiming(name: name))
    }
    func addResourceMetrics(
        resourceKey: String,
        fetch: (start: Date, end: Date),
        redirection: (start: Date, end: Date)?,
        dns: (start: Date, end: Date)?,
        connect: (start: Date, end: Date)?,
        ssl: (start: Date, end: Date)?,
        firstByte: (start: Date, end: Date)?,
        download: (start: Date, end: Date)?,
        responseSize: Int64?,
        attributes: [AttributeKey: AttributeValue]
    ) {
        calledMethods.append(
            .addResourceMetrics(
                resourceKey: resourceKey,
                fetch: Interval(start: fetch.start, end: fetch.end),
                redirection: Interval(start: redirection?.start, end: redirection?.end),
                dns: Interval(start: dns?.start, end: dns?.end),
                connect: Interval(start: connect?.start, end: connect?.end),
                ssl: Interval(start: ssl?.start, end: ssl?.end),
                firstByte: Interval(start: firstByte?.start, end: firstByte?.end),
                download: Interval(start: download?.start, end: download?.end),
                responseSize: responseSize
            )
        )
        receivedAttributes.append(attributes)
    }
    // swiftlint:enable force_cast
}
