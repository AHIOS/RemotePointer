import Foundation

enum MouseButton: String, Codable {
    case left
    case right
}

enum ControlMessage: Codable {
    case move(deltaX: Double, deltaY: Double, timestamp: TimeInterval)
    case click(button: MouseButton)
    case setSensitivity(Double)
    case keyboardText(String)
    case keyboardKey(code: UInt16, isDown: Bool)
    case ping(TimeInterval)
}

extension ControlMessage {
    private enum CodingKeys: String, CodingKey {
        case type
        case deltaX
        case deltaY
        case timestamp
        case button
        case sensitivity
        case text
        case keyCode
        case isDown
    }

    private enum MessageType: String, Codable {
        case move
        case click
        case setSensitivity
        case keyboardText
        case keyboardKey
        case ping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .move:
            let deltaX = try container.decode(Double.self, forKey: .deltaX)
            let deltaY = try container.decode(Double.self, forKey: .deltaY)
            let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
            self = .move(deltaX: deltaX, deltaY: deltaY, timestamp: timestamp)
        case .click:
            let button = try container.decode(MouseButton.self, forKey: .button)
            self = .click(button: button)
        case .setSensitivity:
            let value = try container.decode(Double.self, forKey: .sensitivity)
            self = .setSensitivity(value)
        case .keyboardText:
            let text = try container.decode(String.self, forKey: .text)
            self = .keyboardText(text)
        case .keyboardKey:
            let keyCode = try container.decode(UInt16.self, forKey: .keyCode)
            let isDown = try container.decode(Bool.self, forKey: .isDown)
            self = .keyboardKey(code: keyCode, isDown: isDown)
        case .ping:
            let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
            self = .ping(timestamp)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .move(deltaX, deltaY, timestamp):
            try container.encode(MessageType.move, forKey: .type)
            try container.encode(deltaX, forKey: .deltaX)
            try container.encode(deltaY, forKey: .deltaY)
            try container.encode(timestamp, forKey: .timestamp)
        case let .click(button):
            try container.encode(MessageType.click, forKey: .type)
            try container.encode(button, forKey: .button)
        case let .setSensitivity(value):
            try container.encode(MessageType.setSensitivity, forKey: .type)
            try container.encode(value, forKey: .sensitivity)
        case let .keyboardText(text):
            try container.encode(MessageType.keyboardText, forKey: .type)
            try container.encode(text, forKey: .text)
        case let .keyboardKey(code, isDown):
            try container.encode(MessageType.keyboardKey, forKey: .type)
            try container.encode(code, forKey: .keyCode)
            try container.encode(isDown, forKey: .isDown)
        case let .ping(timestamp):
            try container.encode(MessageType.ping, forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
        }
    }
}

enum ControlCodec {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()

    static func encode(_ message: ControlMessage) throws -> Data {
        try encoder.encode(message)
    }

    static func decode(_ data: Data) throws -> ControlMessage {
        try decoder.decode(ControlMessage.self, from: data)
    }
}
