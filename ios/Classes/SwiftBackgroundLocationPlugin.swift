import Flutter
import UIKit
import CoreLocation

public class SwiftBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, FlutterStreamHandler {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBackgroundLocationPlugin()
        
        SwiftBackgroundLocationPlugin.channel = FlutterMethodChannel(name: "com.almoullim.background_location/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: SwiftBackgroundLocationPlugin.channel!)
        SwiftBackgroundLocationPlugin.channel?.setMethodCallHandler(instance.handle)
        let eventChannel = FlutterEventChannel(name: "com.almoullim.background_location/events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftBackgroundLocationPlugin.locationManager = CLLocationManager()
        SwiftBackgroundLocationPlugin.locationManager?.delegate = self
        //SwiftBackgroundLocationPlugin.locationManager?.requestAlwaysAuthorization()

        SwiftBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates = true
        if #available(iOS 11.0, *) {
            SwiftBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator = true;
        }
        if #available(iOS 14.0, *) {
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        }
        SwiftBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically = false
        SwiftBackgroundLocationPlugin.locationManager?.activityType = .other

        if (call.method == "start_location_service") {
            let args = call.arguments as? Dictionary<String, Any>
            let distanceFilter = args?["distance_filter"] as? Double
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = distanceFilter ?? 0
            SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation() 
        } else if (call.method == "stop_location_service") {
           SwiftBackgroundLocationPlugin.locationManager?.stopUpdatingLocation()
        } else if(call.method == "location_service_is_running") {
            SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
        }
        result(true)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
           
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationData = locations.last else {
            return
        }

        let location = [
            "speed": locationData.speed,
            "altitude": locationData.altitude,
            "latitude": locationData.coordinate.latitude,
            "longitude": locationData.coordinate.longitude,
            "accuracy": locationData.horizontalAccuracy,
            "bearing": locationData.course,
            "time": locationData.timestamp.timeIntervalSince1970 * 1000,
            "is_mock": false
        ] as [String : Any]

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: location)
        eventSink?(location)
    }

    public func onListen(withArguments arguments: Any?,
                                 eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
