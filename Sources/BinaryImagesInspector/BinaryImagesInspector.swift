//
// MIT License
//
// Copyright (c) 2021 Stefan Schmitt
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import MachO

/// Helpful links
///
/// https://stackoverflow.com/questions/5567215/how-to-determine-binary-image-architecture-at-runtime
///
/// https://github.com/apple/swift/blob/master/stdlib/private/SwiftReflectionTest/SwiftReflectionTest.swift
///
/// https://lowlevelbits.org/parsing-mach-o-files/
///
/// https://developer.apple.com/library/archive/technotes/tn2151/_index.html
public struct BinaryImagesInspector {

    #if arch(x86_64) || arch(arm64)
    typealias MachHeader = mach_header_64
    #else
    typealias MachHeader = mach_header
    #endif

    /// Provides binary infos that are then used with the atos command to symbolicate stack traces
    /// - Parameter imageNamesToLog: an optional array of binary image names to restrict the infos to
    /// - Returns: An array of strings containing info on loaded binary name, its load address, architecture
    /// - Note: Example:
    ///
    /// atos -arch arm64 -o [YOUR-DSYM-ID].dSYM/Contents/Resources/DWARF/[YOUR APP] -l 0x0000000000000000 0x0000000000000000
    public static func getBinaryImagesInfo(imageNamesToLog: [String]? = nil) -> [String] {
        let count = _dyld_image_count()

        var stringsToLog = [String]()

        for i in 0..<count {

            guard let dyld = _dyld_get_image_name(i) else { continue }

            let dyldStr = String(cString: dyld)
            let subStrings = dyldStr.split(separator: "/")
            guard let imageName = subStrings.last else { continue }

            if let imageNamesToLog = imageNamesToLog {
                guard imageNamesToLog.contains(String(imageName)) else { continue }
            }

            guard let uncastHeader = _dyld_get_image_header(i) else { continue }
            let machHeader = uncastHeader.withMemoryRebound(to: MachHeader.self, capacity: MemoryLayout<MachHeader>.size) { $0 }
            guard let info = NXGetArchInfoFromCpuType(machHeader.pointee.cputype, machHeader.pointee.cpusubtype) else { continue }
            guard let archName = info.pointee.name else { continue }
            let uuid = getBinaryImageUUID(machHeader: machHeader)
            let logStr = "\(imageName) \(machHeader.debugDescription) - \(String(cString: archName)) - \(uuid ?? "uuid not found")"
            stringsToLog.append(logStr)
        }

        return stringsToLog
    }

    private static func getBinaryImageUUID(machHeader: UnsafePointer<MachHeader>) -> String? {

        guard var header_ptr = UnsafePointer<UInt8>.init(bitPattern: UInt(bitPattern: machHeader)) else {
            return nil
        }

        header_ptr += MemoryLayout<MachHeader>.size

        guard var command = UnsafePointer<load_command>.init(bitPattern: UInt(bitPattern: header_ptr)) else {
            return nil
        }

        for _ in 0..<machHeader.pointee.ncmds {

            if command.pointee.cmd == LC_UUID {
                guard let ucmd_ptr = UnsafePointer<uuid_command>.init(bitPattern: UInt(bitPattern: header_ptr)) else { continue }
                let ucmd = ucmd_ptr.pointee

                let cuuidBytes = CFUUIDBytes(byte0: ucmd.uuid.0,
                                             byte1: ucmd.uuid.1,
                                             byte2: ucmd.uuid.2,
                                             byte3: ucmd.uuid.3,
                                             byte4: ucmd.uuid.4,
                                             byte5: ucmd.uuid.5,
                                             byte6: ucmd.uuid.6,
                                             byte7: ucmd.uuid.7,
                                             byte8: ucmd.uuid.8,
                                             byte9: ucmd.uuid.9,
                                             byte10: ucmd.uuid.10,
                                             byte11: ucmd.uuid.11,
                                             byte12: ucmd.uuid.12,
                                             byte13: ucmd.uuid.13,
                                             byte14: ucmd.uuid.14,
                                             byte15: ucmd.uuid.15)
                guard let cuuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, cuuidBytes) else {
                    return nil
                }
                let suuid = CFUUIDCreateString(kCFAllocatorDefault, cuuid)
                let encoding = CFStringGetFastestEncoding(suuid)
                guard let cstr = CFStringGetCStringPtr(suuid, encoding) else {
                    return nil
                }
                let str = String(cString: cstr)

                return str
            }

            header_ptr += Int(command.pointee.cmdsize)
            guard let newCommand = UnsafePointer<load_command>.init(bitPattern: UInt(bitPattern: header_ptr)) else { continue }
            command = newCommand
        }

        return nil
    }
}
