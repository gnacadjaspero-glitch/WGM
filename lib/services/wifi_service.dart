import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class WifiService {
  static final NetworkInfo _networkInfo = NetworkInfo();
  static final _wifiStreamController = StreamController<String?>.broadcast();
  
  static Stream<String?> get wifiNameStream => _wifiStreamController.stream;

  static Future<void> init() async {
    checkWifi();
    Connectivity().onConnectivityChanged.listen((results) {
      checkWifi();
    });
  }

  static Future<String?> checkWifi() async {
    String? wifiName;
    try {
      wifiName = await _networkInfo.getWifiName();
      // Nettoyage des guillemets souvent ajoutés par network_info_plus
      if (wifiName != null) {
        wifiName = wifiName.replaceAll('"', '');
      }
    } catch (e) {
      wifiName = "Indisponible";
    }
    _wifiStreamController.add(wifiName);
    return wifiName;
  }
}
