# Google Maps Setup Instructions

## Overview
The restaurant profile page now includes an interactive radius map widget that allows restaurant owners to set their delivery area using Google Maps.

## Setup Required

### 1. Get Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if supporting iOS)
   - Places API (optional, for enhanced location features)
4. Create credentials (API Key)
5. Restrict the API key to your app's package name and SHA-1 fingerprint

### 2. Configure Android
Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### 3. Configure iOS (if needed)
Add the API key to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Features Implemented

### Radius Map Widget
- **Interactive Map**: Users can pan and zoom to adjust restaurant location
- **Radius Slider**: Adjustable delivery radius from 1-50 km
- **Visual Circle**: Shows delivery area as a colored circle on the map
- **Current Location**: Button to quickly center map on user's current location
- **Real-time Updates**: Changes are immediately reflected in the form

### Integration
- **State Management**: Fully integrated with the existing BLoC pattern
- **Data Persistence**: Radius and location data are saved with restaurant profile
- **Validation**: Ensures valid radius values and coordinates
- **User Experience**: Intuitive interface with helpful instructions

## Usage
1. Restaurant owners can set their delivery radius by:
   - Moving the map to center on their restaurant location
   - Using the slider to adjust the delivery radius
   - The blue circle shows the delivery area visually
2. Changes are automatically saved when the profile is updated
3. The radius value is displayed in kilometers and synced with the backend

## Dependencies Added
- `google_maps_flutter: ^2.5.0` - For interactive map functionality

## Security Notes
- Always restrict your API key to specific apps and APIs
- Use different API keys for development and production
- Monitor API usage in Google Cloud Console
- Consider implementing additional security measures for production apps
