import AVFoundation
import Flutter
import UIKit

public class SwiftFlutterAudioManagerPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_audio_manager", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterAudioManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global().async {
            if call.method == "getCurrentOutput" {
                result(self.getCurrentOutput())
            } else if call.method == "getAvailableInputs" {
                result(self.getAvailableInputs())
            } else if call.method == "changeToSpeaker" {
//              result(self.changeToSpeaker())
                result(self.switchSpeaker())
            } else if call.method == "changeToReceiver" {
//              result(self.changeToReceiver())
                result(self.switchReceiver())
            } else if call.method == "changeToHeadphones" {
//              result(self.changeToHeadphones())
                result(self.switchHeadphones())
            } else if call.method == "changeToBluetooth" {
//              result(self.changeToBluetooth())
                result(self.switchBluetooth())
            } else if call.method == "getAllOutputDevices" {
                result(self.getAllOutputDevices())
            } else {
                result("iOS " + UIDevice.current.systemVersion)
            }
        }
    }

    func getAllOutputDevices() -> [String] {
        var arr = [String]()

        let bluetoothArr = [AVAudioSession.Port.bluetoothLE, AVAudioSession.Port.bluetoothHFP, AVAudioSession.Port.bluetoothA2DP]
        let isConnectBLE = detectAvailableDevices(bluetoothArr)
        if isConnectBLE {
            arr.append("Bluetooth") // 4
        }

        let isConnectHeadphones = detectAvailableDevices([AVAudioSession.Port.headsetMic])
        if isConnectHeadphones {
            arr.append("Headset") // 3
        } else {
            arr.append("Receiver") // 1
        }

        arr.append("Speaker") // 2

        return arr
    }

    func getCurrentOutput() -> [String] {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            return getInfo(output)
        }
        return ["unknow", "0"]
    }

    func getAvailableInputs() -> [[String]] {
        var arr = [[String]]()
        if let inputs = AVAudioSession.sharedInstance().availableInputs {
            for input in inputs {
                arr.append(getInfo(input))
            }
        }
        return arr
    }

    func getInfo(_ input: AVAudioSessionPortDescription) -> [String] {
        var type = "0"
        let port = AVAudioSession.Port.self
        switch input.portType {
        case port.builtInReceiver, port.builtInMic:
            type = "1"
            break
        case port.builtInSpeaker:
            type = "2"
            break
        case port.headsetMic, port.headphones:
            type = "3"
            break
        case port.bluetoothA2DP, port.bluetoothLE, port.bluetoothHFP:
            type = "4"
            break
        default:
            type = "0"
        }
        return [input.portName, type]
    }

    func bluetoothAudioDevice() -> AVAudioSessionPortDescription? {
        let arr = [AVAudioSession.Port.bluetoothLE, AVAudioSession.Port.bluetoothHFP, AVAudioSession.Port.bluetoothA2DP]
        return audioDeviceFromTypes(arr)
    }

    func builtinAudioDevice() -> AVAudioSessionPortDescription? {
        let arr = [AVAudioSession.Port.builtInMic]
        return audioDeviceFromTypes(arr)
    }

    func headphonesAudioDevice() -> AVAudioSessionPortDescription? {
        let arr = [AVAudioSession.Port.headsetMic]
        return audioDeviceFromTypes(arr)
    }

    func speakerAudioDevice() -> AVAudioSessionPortDescription? {
        let arr = [AVAudioSession.Port.builtInSpeaker]
        return audioDeviceFromTypes(arr)
    }

    func switchBluetooth() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setPreferredInput(bluetoothAudioDevice())
            return true
        } catch {
            print(error)
            return false
        }

        return false
    }

    func switchHeadphones() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setPreferredInput(headphonesAudioDevice())
            return true
        } catch {
            return false
        }

        return false
    }

    func switchSpeaker() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try session.setActive(true)
            return true
        } catch {
            print(error)
            return false
        }

        return false
    }

    func switchReceiver() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.allowBluetooth)
            try session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try session.setActive(true)
//            try AVAudioSession.sharedInstance().setPreferredInput(builtinAudioDevice())
            return true
        } catch {
            print(error)
            return false
        }

        return false
    }

    func audioDeviceFromTypes(_ ports: [AVAudioSession.Port]) -> AVAudioSessionPortDescription? {
        guard let inputs = AVAudioSession.sharedInstance().availableInputs else {
            return nil
        }

        for input in inputs {
            if ports.contains(input.portType) {
                return input
            }
        }

        return nil
    }

//    func changeToSpeaker() -> Bool{
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.overrideOutputAudioPort(.speaker)
//            return true;
//        } catch {
//            return false;
//        }
//    }
//
//
//    func changeToReceiver() -> Bool{
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.overrideOutputAudioPort(.none)
//            return true;
//        } catch {
//            return false;
//        }
//    }
//
//
//    func changeToHeadphones() -> Bool{
//        return changeByPortType([AVAudioSession.Port.headsetMic])
//    }
//
//    func changeToBluetooth() -> Bool{
//        let arr = [AVAudioSession.Port.bluetoothLE,AVAudioSession.Port.bluetoothHFP,AVAudioSession.Port.bluetoothA2DP];
//        return changeByPortType(arr)
//    }
//
//    func changeByPortType(_ ports:[AVAudioSession.Port]) -> Bool{
//        let currentRoute = AVAudioSession.sharedInstance().currentRoute
//        for output in currentRoute.outputs {
//            if(ports.firstIndex(of: output.portType) != nil){
//                return true;
//            }
//        }
//        if let inputs = AVAudioSession.sharedInstance().availableInputs {
//            for input in inputs {
//                if(ports.firstIndex(of: input.portType) != nil){
//                    try?AVAudioSession.sharedInstance().setPreferredInput(input);
//                    return true;
//                }
//             }
//        }
//        return false;
//    }

    func detectAvailableDevices(_ ports: [AVAudioSession.Port]) -> Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if ports.firstIndex(of: output.portType) != nil {
                return true
            }
        }
        if let inputs = AVAudioSession.sharedInstance().availableInputs {
            for input in inputs {
                if ports.firstIndex(of: input.portType) != nil {
                    return true
                }
            }
        }
        return false
    }

    override public init() {
        super.init()
        registerAudioRouteChangeBlock()
    }

    func registerAudioRouteChangeBlock() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance(), queue: nil) { notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }
            self.channel!.invokeMethod("inputChanged", arguments: 1)
        }
    }
}
