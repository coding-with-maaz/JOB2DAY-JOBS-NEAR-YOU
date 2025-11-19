import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'no_internet_widget.dart';

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;

  const NetworkAwareWidget({super.key, required this.child});

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    Connectivity().onConnectivityChanged.listen((_) => _checkInternet());
  }

  Future<void> _checkInternet() async {
    final isConnected = await InternetConnectionChecker.instance.hasConnection;
    if (mounted) {
      setState(() {
        _hasInternet = isConnected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _hasInternet
        ? widget.child
        : NoInternetWidget(
            onRetry: _checkInternet,
          );
  }
} 