//
//  H264Reader.swift
//
//  Created by Sebastian Roth on 3/19/17.
//  Copyright © 2017 Ivity Asia Limited. All rights reserved.
//

import Foundation

import VideoToolbox

private let naluTypesStrings = [
    "0": "Unspecified (non-VCL)",
    "1": "Coded slice of a non-IDR picture (VCL)",    // P frame
    "2": "Coded slice data partition A (VCL)",
    "3": "Coded slice data partition B (VCL)",
    "4": "Coded slice data partition C (VCL)",
    "5": "Coded slice of an IDR picture (VCL)",      // I frame
    "6": "Supplemental enhancement information (SEI) (non-VCL)",
    "7": "Sequence parameter set (non-VCL)",         // SPS parameter
    "8": "Picture parameter set (non-VCL)",          // PPS parameter
    "9": "Access unit delimiter (non-VCL)",
    "10": "End of sequence (non-VCL)",
    "11": "End of stream (non-VCL)",
    "12": "Filler data (non-VCL)",
    "13": "Sequence parameter set extension (non-VCL)",
    "14": "Prefix NAL unit (non-VCL)",
    "15": "Subset sequence parameter set (non-VCL)",
    "16": "Reserved (non-VCL)",
    "17": "Reserved (non-VCL)",
    "18": "Reserved (non-VCL)",
    "19": "Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    "20": "Coded slice extension (non-VCL)",
    "21": "Coded slice extension for depth view components (non-VCL)",
    "22": "Reserved (non-VCL)",
    "23": "Reserved (non-VCL)",
    "24": "STAP-A Single-time aggregation packet (non-VCL)",
    "25": "STAP-B Single-time aggregation packet (non-VCL)",
    "26": "MTAP16 Multi-time aggregation packet (non-VCL)",
    "27": "MTAP24 Multi-time aggregation packet (non-VCL)",
    "28": "FU-A Fragmentation unit (non-VCL)",
    "29": "FU-B Fragmentation unit (non-VCL)",
    "30": "Unspecified (non-VCL)",
    "31": "Unspecified (non-VCL)"
]

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

enum H264Errors: Error {
    case fileUnknown
    case unknownFormat
    case decoderProblem
    case otherProblem
    case osError(OSStatus)
}

public class H264Reader: NSObject {
    var formatDescription: CMVideoFormatDescription?
    //    var blockBuffer : CMBlockBuffer?
    //    var sampleBuffer : CMSampleBuffer?

    var blockBuffer = UnsafeMutablePointer<CMBlockBuffer?>.allocate(capacity: 1)
    var sampleBuffer = UnsafeMutablePointer<CMSampleBuffer?>.allocate(capacity: 1)

    var session: VTDecompressionSession?

    var data: Data! = nil

    @objc
    public func load(url: URL) throws {
        let tmp = FileManager.default.contents(atPath: url.absoluteString)
        if tmp == nil {
            throw H264Errors.fileUnknown
        }
        self.data = tmp!
    }

    @objc
    public func load(path: String) throws {
        let tmp = FileManager.default.contents(atPath: path)
        if tmp == nil {
            throw H264Errors.fileUnknown
        }
        self.data = tmp!
    }

    @available(iOS 9.0, *)
    @objc
    public func convert(target: URL) throws {
        defer {
            if let session = self.session {
                VTDecompressionSessionInvalidate(session)
                self.session = nil
            }
        }

        try self.doConvert(target: target)
    }

    @available(iOS 9.0, *)
    fileprivate func doConvert(target: URL) throws {

        guard let ranges = detectRanges() else {
            throw H264Errors.fileUnknown
        }

        try detectFormat(sps: ranges.sps, pps: ranges.pps)

        guard formatDescription != nil else {
            throw H264Errors.unknownFormat
        }

        let idr = ranges.idr
        var rawIdr: [UInt8] = Array(data.bytes[idr.lowerBound...idr.upperBound-1])
        let length = UInt32(rawIdr.count - 4)
        var convertedNumber = length.bigEndian

        let lengthData = Data(bytes: &convertedNumber, count: 4)
        for (index, value) in lengthData.bytes.enumerated() {
            rawIdr[index] = value
        }

        var status: OSStatus = 0
        status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: &rawIdr,
            blockLength: rawIdr.count,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: rawIdr.count,
            flags: 0,
            blockBufferOut: blockBuffer)

        guard status == 0 else {
            print("(CMBlockBufferCreateWithMemoryBlock) FAIL: \(status)")

            throw H264Errors.osError(status)
        }

        var sampleSize = rawIdr.count

        status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer[0],
            dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription!,
            sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSize,
            sampleBufferOut: sampleBuffer
        )
        guard status == 0 else {
            print("(CMSampleBufferCreate) FAIL: \(status)")

            throw H264Errors.osError(status)
        }

        status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: formatDescription!,
            decoderSpecification: nil,
            imageBufferAttributes: nil,
            outputCallback: nil,
            decompressionSessionOut: &session
        )

        guard status == 0 else {
            print("(VTDecompressionSessionCreate) FAIL: \(status)")

            throw H264Errors.osError(status)
        }

        var image: UIImage?

        status = VTDecompressionSessionDecodeFrame(
            session!,
            sampleBuffer: sampleBuffer[0]!,
            flags: [._EnableAsynchronousDecompression],
            infoFlagsOut: nil
        ) { (status, _, buffer, _, _) in
            //                print ("status: \(status)")
            //                print ("a sample: \(buffer)")

            if let buffer = buffer {
                //                    print ("buffer: \(buffer)")
                let ciUiImage = UIImage(ciImage: CIImage(cvImageBuffer: buffer))
                UIGraphicsBeginImageContext(ciUiImage.size)
                ciUiImage.draw(in: CGRect(origin: .zero, size: ciUiImage.size))
                //                    print ("image to be sent: \(image)")
                image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                //                    print("sent onNext!")
            } else {
                print("(VTDecompressionSessionDecodeFrameWithOutputHandler) handler: FAIL: \(status)")
                //                    throw H264Errors.osError(status)
            }
        }
        guard status == 0 else {
            print("(VTDecompressionSessionDecodeFrameWithOutputHandler) FAIL: \(status)")

            throw H264Errors.osError(status)
        }

        status = VTDecompressionSessionWaitForAsynchronousFrames(session!)
        guard status == 0 else {
            print("(VTDecompressionSessionWaitForAsynchronousFrames) FAIL: \(status)")

            throw H264Errors.osError(status)
        }

        guard let theImage = image else {
            print("Created image is nil")

            throw H264Errors.otherProblem
        }

        do {
            try theImage.jpegData(compressionQuality: 100)?.write(to: URL(fileURLWithPath: target.absoluteString))
            //                try theImage.jpegData(compressionQuality: 100)?.write(to: target)
        } catch {
            print("Other error: \(error)")

            throw H264Errors.otherProblem
        }

    }

    fileprivate func nextNal(_ frame: [UInt8], offset: Int) -> Int {
        var index = offset

        while index < (frame.count - 3) {
            if frame[index] == 0x00 && frame[index+1] == 0x00 && frame[index+2] == 0x00 && frame[index+3] == 0x01 {
                return index
            } else {
                index += 1
            }
        }

        return -1
    }

    fileprivate func naluType(_ byte: UInt8) -> UInt8 {
        return byte & 0x1F
    }

    fileprivate func detectRanges() -> (sps: NSRange, pps: NSRange, idr: NSRange)? {
        var spsStartCodeIndex = -1
        var spsRange: NSRange?

        var ppsStartCodeIndex = -1
        var ppsRange: NSRange?

        var idrRange: NSRange?

        var index = 0
        while index != -1 {
            index = nextNal(data.bytes, offset: index)

            if index >= 0 {
                let type = naluType(data.bytes[index + 4])

                if type == 7 {
                    spsStartCodeIndex = index
                } else if spsStartCodeIndex != -1 {
                    spsRange = NSRange(location: spsStartCodeIndex, length: index - spsStartCodeIndex)
                    spsStartCodeIndex = -1
                }

                if type == 8 {
                    ppsStartCodeIndex = index
                } else if ppsStartCodeIndex != -1 {
                    ppsRange = NSRange(location: ppsStartCodeIndex, length: index - ppsStartCodeIndex)
                    ppsStartCodeIndex = -1
                }

                if type == 5 {
                    idrRange = NSRange(location: index, length: data.bytes.count - index)
                }

                index += 4
            }
        }

        if let sps = spsRange, let pps = ppsRange, let idr = idrRange {
            return (sps, pps, idr)
        } else {
            return nil
        }
    }

    fileprivate func detectFormat(sps: NSRange, pps: NSRange) throws {
        // sps and pps variables
        var spsByteArray: [UInt8] = []
        var ppsByteArray: [UInt8] = []

        let NALUnitHeaderLength: Int32 = 4

        let rawSPS: [UInt8] = Array(data.bytes[sps.lowerBound...sps.upperBound])
        let rawPPS: [UInt8] = Array(data.bytes[pps.lowerBound...pps.upperBound])

        // extract sps data
        spsByteArray = Array(rawSPS[Int(NALUnitHeaderLength)..<rawSPS.count])

        // extract pps data
        ppsByteArray = Array(rawPPS[Int(NALUnitHeaderLength)..<rawPPS.count])

        let parameterSetSizes: [Int] = [spsByteArray.count, ppsByteArray.count]

        let osStatus = withUnsafePointer(to: &spsByteArray[0]) { pointerSPS -> OSStatus in
            return withUnsafePointer(to: &ppsByteArray[0]) { pointerPPS -> OSStatus in
                var dataParamArray = [pointerSPS, pointerPPS]
                return withUnsafePointer(to: &dataParamArray[0]) { parameterSetPointers in
                    return CMVideoFormatDescriptionCreateFromH264ParameterSets(
                        allocator: kCFAllocatorDefault,
                        parameterSetCount: parameterSetSizes.count,
                        parameterSetPointers: parameterSetPointers,
                        parameterSetSizes: parameterSetSizes,
                        nalUnitHeaderLength: NALUnitHeaderLength,
                        formatDescriptionOut: &formatDescription
                    )
                }
            }
        }

        guard osStatus == 0 else {
            throw H264Errors.osError(osStatus)
        }
    }

}
