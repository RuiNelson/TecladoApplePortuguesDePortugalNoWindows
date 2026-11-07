// Exporta para JSON um layout de teclado do macOS (por omissao, "Portuguese"),
// tecla a tecla, para os estados: normal, Shift, Option, Shift+Option e Caps Lock.
// Usa o teclado do tipo ISO, que e o do teclado Apple PT-PT.
//
// Uso: swift tools/macos/dump-mac-layout.swift [com.apple.keylayout.Portuguese] > docs/data/mac-portuguese.json
import Carbon
import Foundation

let sourceID = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "com.apple.keylayout.Portuguese"

let filter = [kTISPropertyInputSourceID as String: sourceID] as CFDictionary
guard let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource],
      let source = list.first,
      let rawData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
    FileHandle.standardError.write("Layout \(sourceID) nao encontrado\n".data(using: .utf8)!)
    exit(1)
}
let layoutData = Unmanaged<CFData>.fromOpaque(rawData).takeUnretainedValue() as Data

// Tipo de teclado ISO (o uchr pode ter tabelas diferentes para ANSI/ISO/JIS).
var isoType: UInt32 = 0
for t in 0..<256 where KBGetLayoutType(Int16(t)) == UInt32(kKeyboardISO) {
    isoType = UInt32(t)
    break
}

// Teclas de caracteres (codigos virtuais do macOS), com o nome da posicao fisica.
// 0x0A e a tecla do canto superior esquerdo (scancode PC 0x29; no teclado Apple
// PT-PT, "§ ±") e 0x32 a tecla extra do ISO, ao lado do Shift esquerdo
// (scancode PC 0x56; "< >").
let keys: [(UInt16, String)] = [
    (0x0A, "top-left"), (0x12, "1"), (0x13, "2"), (0x14, "3"), (0x15, "4"), (0x17, "5"),
    (0x16, "6"), (0x1A, "7"), (0x1C, "8"), (0x19, "9"), (0x1D, "0"), (0x1B, "minus"), (0x18, "equal"),
    (0x0C, "Q"), (0x0D, "W"), (0x0E, "E"), (0x0F, "R"), (0x11, "T"), (0x10, "Y"), (0x20, "U"),
    (0x22, "I"), (0x1F, "O"), (0x23, "P"), (0x21, "lbracket"), (0x1E, "rbracket"),
    (0x00, "A"), (0x01, "S"), (0x02, "D"), (0x03, "F"), (0x05, "G"), (0x04, "H"), (0x26, "J"),
    (0x28, "K"), (0x25, "L"), (0x29, "semicolon"), (0x27, "quote"), (0x2A, "backslash"),
    (0x32, "iso-left-of-z"), (0x06, "Z"), (0x07, "X"), (0x08, "C"), (0x09, "V"), (0x0B, "B"),
    (0x2D, "N"), (0x2E, "M"), (0x2B, "comma"), (0x2F, "period"), (0x2C, "slash"),
    (0x31, "space"), (0x41, "keypad-decimal"),
]

// Estados de modificadores no formato do UCKeyTranslate ((modifiers >> 8) & 0xFF).
let shift: UInt32 = 0x02, option: UInt32 = 0x08, caps: UInt32 = 0x04
let states: [(String, UInt32)] = [
    ("none", 0), ("shift", shift), ("option", option), ("shiftOption", shift | option), ("caps", caps),
]

func translate(_ key: UInt16, _ mods: UInt32, _ dead: inout UInt32) -> String {
    var length = 0
    var chars = [UniChar](repeating: 0, count: 8)
    let status = layoutData.withUnsafeBytes { buf -> OSStatus in
        let layout = buf.baseAddress!.assumingMemoryBound(to: UCKeyboardLayout.self)
        return UCKeyTranslate(layout, key, UInt16(kUCKeyActionDown), mods, isoType, 0,
                              &dead, chars.count, &length, &chars)
    }
    return status == noErr ? String(utf16CodeUnits: chars, count: length) : ""
}

var result: [[String: Any]] = []
for (code, name) in keys {
    var entry: [String: Any] = ["macKeyCode": Int(code), "position": name]
    for (stateName, mods) in states {
        var dead: UInt32 = 0
        let text = translate(code, mods, &dead)
        if dead != 0 && text.isEmpty {
            // Tecla morta: o caracter "isolado" obtem-se com espaco a seguir.
            var d = dead
            let spacing = translate(0x31, 0, &d)
            var compositions: [String: String] = [:]
            for (c2, _) in keys {
                for (_, m2) in states where m2 != caps {
                    var d1: UInt32 = 0
                    let plain = translate(c2, m2, &d1)
                    if d1 != 0 || plain.isEmpty { continue }
                    var d2 = dead
                    let composed = translate(c2, m2, &d2)
                    if composed.count == 1 && composed != plain { compositions[plain] = composed }
                }
            }
            entry[stateName] = ["dead": spacing, "compositions": compositions]
        }
        else {
            entry[stateName] = text
        }
    }
    result.append(entry)
}

let json = try JSONSerialization.data(withJSONObject: ["source": sourceID, "keyboardType": Int(isoType), "keys": result],
                                      options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(json)
FileHandle.standardOutput.write("\n".data(using: .utf8)!)
