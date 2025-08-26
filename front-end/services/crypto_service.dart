// lib/services/crypto_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- API Constants (You might have these in a separate file too) ---
class ApiConstants {
  //static const String baseUrl = 'https://nahid-sekander.duckdns.org/projects/crypto/api';
  static const String baseUrl = 'http://192.168/projects/crypto/api';
  static const String walletCreateEndpoint = '$baseUrl/wallet.php?action=create_wallet';
  static const String registerEndpoint = '$baseUrl/register.php';
  static const String loginEndpoint = '$baseUrl/login.php';
  static const String verifyPinEndpoint = '$baseUrl/verify_pin.php';
  static const String sendCoinsEndpoint = '$baseUrl/wallet.php?action=send';
  static const String loadBlockchainEndpoint = '$baseUrl/wallet.php?action=load_blockchain';
  static const String getBalancesEndpoint = '$baseUrl/wallet.php?action=get_balances';
}

// --- Models ---
class WalletData {
  final String address;
  final String privateKey;
  WalletData({required this.address, required this.privateKey});

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      address: json['address'] ?? '',
      privateKey: json['privateKey'] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
    'address': address,
    'privateKey': privateKey,
  };
}

class UserData {
  final String username;
  final String password;
  final String role;
  final String walletAddress;
  final String privateKey; // DANGER: For this system's API, it's sent back on login
  final String pin; // DANGER: Stored plaintext in users.json and used for verification

  UserData({
    required this.username,
    required this.password,
    required this.role,
    required this.walletAddress,
    required this.privateKey,
    required this.pin,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      walletAddress: json['wallet'] ?? '',
      privateKey: json['privateKey'] ?? '',
      pin: json['pin'] ?? '',
    );
  }

  //
// THIS IS THE MISSING METHOD YOU NEED TO ADD
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'pin': pin,
      'walletAddress': walletAddress,
      'privateKey': privateKey,
      // Add other fields to the map
    };
  }


}

// --- Service Class ---
class CryptoService {
  String? _sessionId;
  // In a real app, this would be secured. For this demo, it's stored.
  UserData? _loggedInUser;

  // Getters to access logged-in user data
  String? get loggedInUsername => _loggedInUser?.username;
  String? get loggedInWalletAddress => _loggedInUser?.walletAddress;
  String? get loggedInPrivateKey => _loggedInUser?.privateKey; // DANGER!

  // Initialize session and user data from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionId');
    final userJsonString = prefs.getString('loggedInUserData');
    if (userJsonString != null) {
      _loggedInUser = UserData.fromJson(jsonDecode(userJsonString));
    }
  }

  // Helper to get headers with session cookie
  Map<String, String> _getHeaders({bool includeSession = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeSession && _sessionId != null) {
      headers['Cookie'] = 'PHPSESSID=$_sessionId';
    }
    return headers;
  }

  // --- API Calls ---

  Future<Map<String, dynamic>> createWallet() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.walletCreateEndpoint));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String pin,
    required String walletAddress,
    required String walletPrivateKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: _getHeaders(includeSession: false),
        body: jsonEncode({
          'username': username,
          'password': password,
          'pin': pin,
          'walletAddress': walletAddress,
          'walletPrivateKey': walletPrivateKey,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: _getHeaders(includeSession: false),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['success'] == true) {
          // Extract session ID
          String? setCookieHeader = response.headers['set-cookie'];
          if (setCookieHeader != null) {
            RegExp regExp = RegExp(r'PHPSESSID=([^;]+)');
            Match? match = regExp.firstMatch(setCookieHeader);
            if (match != null && match.groupCount > 0) {
              _sessionId = match.group(1);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('sessionId', _sessionId!);

              // Store user data (WARNING: storing private key is insecure)
              _loggedInUser = UserData.fromJson({
                ...responseJson['user'], // Assuming 'user' object in login response
                'privateKey': responseJson['user']['walletPrivateKey'] ?? '', // API might return it here
                'pin': '', // PIN isn't returned on login typically, but needed for send
              });
              await prefs.setString('loggedInUserData', jsonEncode(_loggedInUser!.toJson())); // Save entire UserData
            }
          }
        }
        return responseJson;
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPin({required String pin}) async {
    if (_sessionId == null) {
      return {'success': false, 'error': 'No active session. Please login first.'};
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyPinEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({'pin': pin}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendCoins({
    required String fromAddress,
    required String privateKey, // DANGER: Sent to server plaintext
    required String toAddress,
    required double amount,
  }) async {
    if (_sessionId == null) {
      return {'success': false, 'error': 'No active session. Please login first.'};
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sendCoinsEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'from': fromAddress,
          'private_key': privateKey, // DANGER!
          'to': toAddress,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  // You can add loadBlockchain, getBalances, etc., here following a similar pattern.
  Future<Map<String, dynamic>> loadBlockchain() async {
    if (_sessionId == null) {
      return {'success': false, 'error': 'No active session. Please login first.'};
    }
    try {
      final response = await http.get(Uri.parse(ApiConstants.loadBlockchainEndpoint), headers: _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBalances() async {
    if (_sessionId == null) {
      return {'success': false, 'error': 'No active session. Please login first.'};
    }
    try {
      final response = await http.get(Uri.parse(ApiConstants.getBalancesEndpoint), headers: _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network Error: $e'};
    }
  }
}









