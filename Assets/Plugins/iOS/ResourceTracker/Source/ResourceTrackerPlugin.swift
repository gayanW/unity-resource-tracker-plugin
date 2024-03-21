import Foundation
import Metal

@available(iOS 13.0, *)
@objc public class ResourceTrackerPlugin : NSObject {
    
    @objc public static let instance = ResourceTrackerPlugin()

    private var memory: [Int] = []
    private var cpu: [Double] = []
    private var gpu: [Double] = []

    private var timer: Timer?
    
    @objc public func StartTracking() {
        memory = []
        cpu = []
        gpu = []
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(update),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc private func update() {
        cpu.append(cpuUsage())
        memory.append(usedMemoryInMB())
        gpu.append(gpuTimeMs())
    }

    @objc public func StopTracking() -> String {
        timer?.invalidate()
        
        let cpuAvg = cpu.reduce(0.0, +) / Double(cpu.count)
        let memoryAvg = memory.reduce(0, +) / memory.count
        let gpuTimeAvg = gpu.reduce(0.0, +) / Double(gpu.count)
        
        let gpuTimeAvgFormatted = String(format: "%.5f", gpuTimeAvg)
        
        return "CPU: \(cpuAvg.rounded()), Memory: \(memoryAvg), GPU Time: \(gpuTimeAvgFormatted)"
    }

    private func usedMemoryInMB() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
          $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
          }
        }
        guard kerr == KERN_SUCCESS else { return 0 }
        return Int(info.resident_size / 1024 / 1024)
    }
    
    private func cpuUsage() -> Double {
        let  HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride

        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        if result != KERN_SUCCESS {
            print("Error  - kern_result_t = \(result)")
            cpu.removeAll()
            return 0.0
        }
        
        let data = hostInfo.move()
        hostInfo.deallocate()
                
        let totalTicks = data.cpu_ticks.0 + data.cpu_ticks.1 + data.cpu_ticks.2
        let usage = Double(data.cpu_ticks.0 + data.cpu_ticks.1) / Double(totalTicks)
        
        return usage * 100.0
    }
    
    private func gpuTimeMs() -> Double {
        let device = MTLCreateSystemDefaultDevice()
        let commandQueue = device?.makeCommandQueue()

        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()

        commandEncoder?.endEncoding()
        commandBuffer?.commit()

        commandBuffer?.waitUntilCompleted()

        let gpuEndTime = commandBuffer?.gpuEndTime
        let gpuStartTime = commandBuffer?.gpuStartTime

        let time = gpuEndTime! - gpuStartTime!

        return time * 1000.0;
    }
}