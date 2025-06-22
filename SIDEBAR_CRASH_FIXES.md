# Sidebar Navigation Crash Fixes

## Problem Summary
The Flutter application was crashing around the 9th second, especially when constantly navigating using the sidebar. The crashes were caused by:

1. **Problematic Navigation Pattern**: Complex nested `Future.delayed` calls with context access
2. **Multiple FutureBuilder Instances**: Every screen created a new `FutureBuilder` for restaurant info
3. **Inconsistent Sidebar Opening Methods**: Different screens used different approaches
4. **Context Access After Disposal**: Navigation attempts after widget disposal
5. **Memory Leaks**: Multiple concurrent async operations without proper cleanup
6. **Missing Restaurant Information**: Sidebar was not displaying actual restaurant data from API

## Fixes Applied

### 1. Fixed Sidebar Navigation Method (`sidebar_drawer.dart`)

**Before:**
```dart
void _navigateToPage(String routeName) {
  _closeDrawer();
  
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      if (routeName == '/home') {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.of(context).pushNamed(routeName);
          }
        });
      }
    }
  });
}
```

**After:**
```dart
void _navigateToPage(String routeName) {
  _closeDrawer();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      try {
        if (routeName == '/home') {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          Navigator.of(context).pushReplacementNamed(routeName);
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        // Fallback to home if navigation fails
        try {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        } catch (fallbackError) {
          debugPrint('Fallback navigation also failed: $fallbackError');
        }
      }
    }
  });
}
```

### 2. Enhanced Restaurant Info Service (`restaurant_info_service.dart`)

**Major Improvements:**
- **API Integration**: Now fetches restaurant info directly from the API
- **Smart Caching**: 5-minute cache with automatic refresh
- **Image URL Processing**: Properly handles and cleans restaurant image URLs
- **Fallback System**: Falls back to SharedPreferences if API fails
- **Real-time Updates**: Updates immediately when profile changes
- **Debug Logging**: Comprehensive logging for troubleshooting

**New API Integration:**
```dart
static Future<Map<String, String>> _fetchFromAPI() async {
  // Fetches restaurant info from /partner/restaurant/{userId} endpoint
  // Extracts: restaurant_name, address, restaurant_photos
  // Handles JSON parsing and URL cleaning
}
```

### 3. Fixed Sidebar Opening Methods

**Before (Problematic):**
```dart
void _openSidebar() {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => FutureBuilder<Map<String, String>>(
        future: RestaurantInfoService.getRestaurantInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data ?? {};
          return SidebarDrawer(...);
        },
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}
```

**After (Stable):**
```dart
void _openSidebar() {
  _scaffoldKey.currentState?.openDrawer();
}
```

### 4. Updated Screen Implementations

**Fixed screens with API integration:**
- `homePage/view.dart`: Force refreshes restaurant info from API on load
- `orders/view.dart`: Force refreshes restaurant info from API on load  
- `item_list/view.dart`: Force refreshes restaurant info from API on load

**Force Refresh Pattern:**
```dart
Future<void> _loadRestaurantInfo() async {
  try {
    // Force refresh from API to get the latest restaurant info
    final info = await RestaurantInfoService.refreshRestaurantInfo();
    if (mounted) {
      setState(() {
        _restaurantInfo = info;
        _isRestaurantInfoLoaded = true;
      });
      debugPrint('🔄 Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
    }
  } catch (e) {
    debugPrint('Error loading restaurant info: $e');
  }
}
```

### 5. Enhanced Error Handling (`main.dart`)

**Added:**
- Navigation error detection
- Periodic health checks
- Better error logging
- Crash prevention mechanisms
- **Cache clearing on app startup** to ensure fresh data

### 6. Restaurant Information Display

**Restored and Enhanced:**
- **Restaurant Name**: Fetched from API (`restaurant_name` field)
- **Restaurant Address/Slogan**: Fetched from API (`address` field)
- **Restaurant Image**: Fetched from API (`restaurant_photos` field)
- **Real-time Updates**: Changes reflect immediately when profile is modified
- **Image Loading**: Proper network image loading with fallback
- **Debug Logging**: Comprehensive logging for troubleshooting

**Sidebar Display:**
```dart
// Restaurant image with proper loading and error handling
Widget _buildRestaurantImage() {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.network(
        imageUrl,
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/logo.png', height: 64, width: 64);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircularProgressIndicator();
        },
      ),
    );
  } else {
    return Image.asset('assets/images/logo.png', height: 64, width: 64);
  }
}
```

### 7. Fixed Yellow Line Issue in Sidebar

**Problem:** The attributes, add product, and restaurant profile pages were showing a yellow line below the restaurant name and address in the sidebar. This was caused by using the old problematic sidebar approach with `Navigator.push` and `PageRouteBuilder`.

**Root Cause:** These pages were still using the old sidebar opening method:
```dart
void _openSidebar() {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => FutureBuilder<Map<String, String>>(
        future: RestaurantInfoService.getRestaurantInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data ?? {};
          return SidebarDrawer(...);
        },
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}
```

**Solution:** Updated all three pages to use the proper sidebar approach:
- **Attributes Page**: Added `ScaffoldKey` and `drawer` property
- **Add Product Page**: Added `ScaffoldKey` and `drawer` property  
- **Restaurant Profile Page**: Added `ScaffoldKey` and `drawer` property

**New Implementation:**
```dart
// Added to each page
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
Map<String, String>? _restaurantInfo;
bool _isRestaurantInfoLoaded = false;

Future<void> _loadRestaurantInfo() async {
  try {
    final info = await RestaurantInfoService.refreshRestaurantInfo();
    if (mounted) {
      setState(() {
        _restaurantInfo = info;
        _isRestaurantInfoLoaded = true;
      });
    }
  } catch (e) {
    debugPrint('Error loading restaurant info: $e');
  }
}

void _openSidebar() {
  _scaffoldKey.currentState?.openDrawer();
}

// In Scaffold
Scaffold(
  key: _scaffoldKey,
  drawer: SidebarDrawer(
    activePage: 'page_name',
    restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
    restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Page description',
    restaurantImageUrl: _restaurantInfo?['imageUrl'],
  ),
  // ... rest of scaffold
)
```

This fix eliminates the yellow line issue and ensures consistent sidebar behavior across all pages.

## Key Improvements

### 1. **Eliminated Nested Future.delayed Calls**
- Replaced with `WidgetsBinding.instance.addPostFrameCallback`
- Removed multiple delayed navigation calls
- Added proper error handling

### 2. **API-Driven Restaurant Info**
- **Direct API Integration**: Fetches from `/partner/restaurant/{userId}` endpoint
- **Smart Caching**: 5-minute cache with automatic refresh
- **Image URL Processing**: Handles malformed URLs and JSON arrays
- **Fallback System**: SharedPreferences backup if API fails
- **Real-time Updates**: Immediate cache updates on profile changes

### 3. **Consistent Sidebar Pattern**
- All screens now use `scaffoldKey.currentState?.openDrawer()`
- Removed `Navigator.push` with `PageRouteBuilder`
- Eliminated `FutureBuilder` in drawer creation
- **Restored restaurant information display with API data**

### 4. **Better Error Recovery**
- Navigation fallbacks
- Context validation
- Graceful degradation
- Comprehensive error logging

### 5. **Memory Management**
- Proper BLoC disposal
- Cache cleanup on logout and app startup
- Reduced async operation overhead
- Smart cache invalidation

### 6. **Restaurant Info Integration**
- **API-First Approach**: Prioritizes fresh API data over cached data
- **Force Refresh**: Each screen forces refresh on load for latest data
- **Image Support**: Proper network image loading with fallbacks
- **Debug Logging**: Comprehensive logging for troubleshooting
- **Real-time Updates**: Profile changes immediately reflect in sidebar

### 7. **Fixed Yellow Line Issue in Sidebar**
- Updated all three pages to use the proper sidebar approach
- Added `ScaffoldKey` and `drawer` property
- Implemented `_loadRestaurantInfo` and `_openSidebar` methods
- Updated Scaffold to include SidebarDrawer

## Testing Recommendations

1. **Navigation Stress Test**: Rapidly navigate between pages using sidebar
2. **Memory Usage**: Monitor memory consumption during navigation
3. **Error Scenarios**: Test with slow network and error conditions
4. **Long Session**: Keep app running for extended periods
5. **Profile Updates**: Verify sidebar updates when restaurant info is modified
6. **API Integration**: Test with different restaurant data scenarios
7. **Image Loading**: Test with various image URL formats and network conditions

## Monitoring

The app now includes:
- Navigation error detection
- Periodic health checks
- Detailed error logging
- Performance monitoring
- Restaurant info cache status
- **API call logging and debugging**
- **Image loading status and errors**

## Prevention Measures

1. **Always check `mounted` before context access**
2. **Use `WidgetsBinding.instance.addPostFrameCallback` instead of `Future.delayed`**
3. **Implement proper error handling for all async operations**
4. **Cache frequently accessed data with smart invalidation**
5. **Use consistent navigation patterns**
6. **Update restaurant info service when profile changes**
7. **Force refresh restaurant info on screen loads**
8. **Clear cache on app startup for fresh data**

## Files Modified

1. `lib/presentation/screens/homePage/sidebar/sidebar_drawer.dart`
2. `lib/services/restaurant_info_service.dart` - **Major enhancement with API integration**
3. `lib/presentation/screens/homePage/view.dart`
4. `lib/presentation/screens/orders/view.dart`
5. `lib/presentation/screens/item_list/view.dart`
6. `lib/main.dart`
7. `lib/presentation/screens/homePage/sidebar/sidebar_provider.dart` (new)
8. `lib/presentation/screens/restaurant_profile/bloc.dart`
9. `lib/presentation/screens/add_resturant_info/bloc.dart`
10. `lib/presentation/screens/attributes/view.dart` - **Fixed problematic sidebar approach**
11. `lib/presentation/screens/add_product/view.dart` - **Fixed problematic sidebar approach**
12. `lib/presentation/screens/restaurant_profile/view.dart` - **Fixed problematic sidebar approach**

## API Integration Details

The restaurant info service now:
- Fetches data from `/partner/restaurant/{userId}` endpoint
- Extracts `restaurant_name`, `address`, and `restaurant_photos`
- Handles JSON parsing for image URLs
- Cleans malformed image URLs
- Caches data for 5 minutes
- Provides fallback to SharedPreferences
- Updates immediately on profile changes

These fixes should resolve the crash issues and provide a more stable navigation experience with proper restaurant information display in the sidebar, now driven by actual API data. 