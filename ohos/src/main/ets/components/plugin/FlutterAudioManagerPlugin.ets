import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { ArrayList } from '@kit.ArkTS';
import Constants from './Constants';
import { audio } from '@kit.AudioKit';

/** FlutterAudioManagerPlugin **/
export default class FlutterAudioManagerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "FlutterAudioManagerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_audio_manager");
    this.channel.setMethodCallHandler(this)
    this.setAudioDevicesChangedListener()
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == 'getCurrentOutput') {
      // todo, notImplemented
      result.success([Constants.AUDIO_TYPE_SPEAKER_NAME, Constants.AUDIO_TYPE_SPEAKER])
    } else if (call.method == 'getAvailableInputs') {
      // todo, notImplemented
      result.success([])
    } else if (call.method == 'getAllOutputDevices') {
      this.getAllOutputDevices(call, result)
    } else {
      result.notImplemented()
    }
  }

  private getAllOutputDevices(call: MethodCall, result: MethodResult): void {
    let audioManager = audio.getAudioManager()
    let audioRoutingManager = audioManager.getRoutingManager()
    audioRoutingManager.getDevices(audio.DeviceFlag.OUTPUT_DEVICES_FLAG).then((data: audio.AudioDeviceDescriptors) => {
      let deviceTypes: ArrayList<audio.DeviceType> = new ArrayList()
      data.forEach((audioDeviceDescriptor) => {
        let deviceType = audioDeviceDescriptor.deviceType
        deviceTypes.add(deviceType);
      })

      let devices: ArrayList<String> = new ArrayList()
      if (deviceTypes.has(audio.DeviceType.BLUETOOTH_SCO || audio.DeviceType.BLUETOOTH_A2DP)) {
        devices.add('Bluetooth')
      }
      if (deviceTypes.has(audio.DeviceType.WIRED_HEADSET || audio.DeviceType.WIRED_HEADPHONES || audio.DeviceType.USB_HEADSET)) {
        devices.add('Headset')
      } else {
        devices.add('Receiver')
      }
      devices.add('Speaker')
      result.success(devices)
    });
  }

  private setAudioDevicesChangedListener() {
    let audioManager = audio.getAudioManager()
    let audioRoutingManager = audioManager.getRoutingManager()
    audioRoutingManager.on('deviceChange', audio.DeviceFlag.OUTPUT_DEVICES_FLAG, () => {
      this.channel?.invokeMethod('inputChanged', 1)
    });
  }
}