import 'package:flutter/material.dart';
import 'package:brickmmo_pixy_viewer/services/crypto_service.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';
// import 'package:brickmmo_pixy_viewer/models/wallet_data.dart';

/// Comprehensive modal dialog showing detailed information about a grid cell
/// Includes block data, tracking controls, and cryptocurrency operations
/// Accessed by tapping on any grid cell in the main view
class TileInfoModal extends StatefulWidget {
  final BlockData?
  registeredBlockData; // Block data if cell contains a registered block
  final String cellKey; // Cell coordinates in "x,y" format
  final Color baseColor; // Base map color for this cell
  final Color? overlayColor; // Current Pixy overlay color (if any)
  final Function(BlockData)? onTrackBlock; // Callback to start tracking a block
  final CryptoService cryptoService; // Reference to cryptocurrency service

  const TileInfoModal({
    super.key,
    required this.cellKey,
    required this.baseColor,
    this.overlayColor,
    this.registeredBlockData,
    this.onTrackBlock,
    required this.cryptoService,
  });

  @override
  State<TileInfoModal> createState() => _TileInfoModalState();
}

class _TileInfoModalState extends State<TileInfoModal> {
  // Controllers for cryptocurrency operation form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _recipientAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // State variables for crypto operations
  bool _isRegistering = false; // Registration operation in progress
  bool _isSending = false; // Coin send operation in progress
  String? _registrationMessage; // Status message for registration
  String? _sendCoinsMessage; // Status message for coin sending
  String? _loggedInUsername; // Currently logged in user (if any)

  @override
  void initState() {
    super.initState();
    // Initialize with current login state from crypto service
    _loggedInUsername = widget.cryptoService.loggedInUsername;
  }

  @override
  void dispose() {
    // Clean up all text controllers to prevent memory leaks
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _recipientAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Registers a new cryptocurrency user associated with this block
  Future<void> _registerBlockAsCryptoUser() async {
    setState(() {
      _isRegistering = true;
      _registrationMessage = null; // Clear previous messages
    });

    final username = _usernameController.text;
    final password = _passwordController.text;
    final pin = _pinController.text;

    // Validate all required fields are filled
    if (username.isEmpty || password.isEmpty || pin.isEmpty) {
      setState(() {
        _registrationMessage = 'Please fill all registration fields.';
        _isRegistering = false;
      });
      return;
    }

    // Step 1: Create cryptocurrency wallet
    final walletResult = await widget.cryptoService.createWallet();
    if (walletResult['success'] == true) {
      final walletData = WalletData.fromJson(walletResult['wallet']);

      // Step 2: Register user with wallet information
      final registerResult = await widget.cryptoService.registerUser(
        username: username,
        password: password,
        pin: pin,
        walletAddress: walletData.address,
        walletPrivateKey: walletData.privateKey,
      );

      if (registerResult['success'] == true) {
        // Step 3: Auto-login after successful registration
        final loginResult = await widget.cryptoService.login(
          username: username,
          password: password,
        );

        if (loginResult['success'] == true) {
          setState(() {
            _registrationMessage =
                'User "$username" registered & logged in successfully!';
            _loggedInUsername = username;
          });
        } else {
          setState(() {
            _registrationMessage =
                'User "$username" registered, but auto-login failed: ${loginResult['error']}';
          });
        }
      } else {
        setState(() {
          _registrationMessage =
              'Registration failed: ${registerResult['error']}';
        });
      }
    } else {
      setState(() {
        _registrationMessage =
            'Wallet creation failed: ${walletResult['error']}';
      });
    }

    setState(() {
      _isRegistering = false;
    });
  }

  /// Sends cryptocurrency coins from the block owner to another address
  Future<void> _sendCoinsFromBlockOwner() async {
    setState(() {
      _isSending = true;
      _sendCoinsMessage = null;
    });

    final recipientAddress = _recipientAddressController.text;
    final amountText = _amountController.text;
    final pin = _pinController.text; // Re-use PIN for verification

    // Validate user is logged in first
    if (_loggedInUsername == null) {
      setState(() {
        _sendCoinsMessage = 'Please login first to send coins.';
        _isSending = false;
      });
      return;
    }

    // Validate all required fields are filled
    if (recipientAddress.isEmpty || amountText.isEmpty || pin.isEmpty) {
      setState(() {
        _sendCoinsMessage = 'Please fill all send coin fields.';
        _isSending = false;
      });
      return;
    }

    // Parse and validate amount
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _sendCoinsMessage = 'Invalid amount.';
        _isSending = false;
      });
      return;
    }

    // Get sender wallet information from crypto service
    final senderAddress = widget.cryptoService.loggedInWalletAddress;
    final senderPrivateKey = widget.cryptoService.loggedInPrivateKey;

    if (senderAddress == null || senderPrivateKey == null) {
      setState(() {
        _sendCoinsMessage =
            'Sender wallet info not available. Please re-login.';
        _isSending = false;
      });
      return;
    }

    // Step 1: Verify PIN for security
    final pinVerifyResult = await widget.cryptoService.verifyPin(pin: pin);
    if (pinVerifyResult['success'] == true) {
      // Step 2: Send coins if PIN verification succeeds
      final sendResult = await widget.cryptoService.sendCoins(
        fromAddress: senderAddress,
        privateKey: senderPrivateKey,
        toAddress: recipientAddress,
        amount: amount,
      );

      if (sendResult['success'] == true) {
        setState(() {
          _sendCoinsMessage = 'Successfully sent $amount coins!';
        });
      } else {
        setState(() {
          _sendCoinsMessage = 'Send failed: ${sendResult['error']}';
        });
      }
    } else {
      setState(() {
        _sendCoinsMessage =
            'PIN verification failed: ${pinVerifyResult['error']}';
      });
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build modal content sections
    final content = <Widget>[
      // Cell information header
      Text(
        'Cell Coordinates: ${widget.cellKey}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Base Tile Color: #${widget.baseColor.value.toRadixString(16).substring(2).toUpperCase()}',
        style: const TextStyle(fontSize: 14),
      ),

      // Overlay color if present
      if (widget.overlayColor != null)
        Text(
          'Pixy Overlay Color: #${widget.overlayColor!.value.toRadixString(16).substring(2).toUpperCase()}',
          style: const TextStyle(fontSize: 14),
        ),
      const SizedBox(height: 16),
    ];

    // Add block details section if cell contains a registered block
    if (widget.registeredBlockData != null) {
      content.addAll([
        const Text(
          'Registered Block Details:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          'UUID: ${widget.registeredBlockData!.uuid}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Camera: ${widget.registeredBlockData!.camera}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Signature: ${widget.registeredBlockData!.signature}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Raw X: ${widget.registeredBlockData!.rawX}, Raw Y: ${widget.registeredBlockData!.rawY}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Timestamp: ${DateTime.parse(widget.registeredBlockData!.timestamp).toLocal().toString().split('.')[0]}',
          style: const TextStyle(fontSize: 14),
        ),
      ]);
    } else if (widget.overlayColor != null) {
      // Pixy detection without registration
      content.add(
        const Text(
          'This tile has a Pixy overlay but is not a registered block.',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      // Empty cell state
      content.add(
        const Text(
          'This is a base map tile with no active Pixy overlay or registered block.',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Cryptocurrency operations section
    content.add(const Divider(height: 32));
    content.add(
      const Text(
        'Cryptocurrency Operations',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
    content.add(const SizedBox(height: 10));

    // Display current login status
    if (_loggedInUsername != null) {
      content.add(
        Text(
          'Logged in as: $_loggedInUsername',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
      content.add(
        Text(
          'Wallet: ${widget.cryptoService.loggedInWalletAddress?.substring(0, 8)}...',
          style: const TextStyle(fontSize: 12),
        ),
      );
      content.add(const SizedBox(height: 10));
    } else {
      content.add(
        const Text('No user logged in.', style: TextStyle(color: Colors.red)),
      );
      content.add(const SizedBox(height: 10));
    }

    // User registration form
    content.addAll([
      const Text(
        'Register New Crypto User (for this block/purpose):',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextField(
        controller: _usernameController,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      TextField(
        controller: _passwordController,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
      ),
      TextField(
        controller: _pinController,
        decoration: const InputDecoration(
          labelText: 'PIN (for verification and future sends)',
        ),
        keyboardType: TextInputType.number,
      ),

      // Registration status message
      if (_registrationMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _registrationMessage!,
            style: TextStyle(
              color:
                  _registrationMessage!.contains('failed')
                      ? Colors.red
                      : Colors.green,
            ),
          ),
        ),

      // Registration button
      ElevatedButton(
        onPressed: _isRegistering ? null : _registerBlockAsCryptoUser,
        child:
            _isRegistering
                ? const CircularProgressIndicator()
                : const Text('Register & Log In User'),
      ),
      const SizedBox(height: 20),
    ]);

    // Coin sending form (only shown if user is logged in)
    if (_loggedInUsername != null) {
      content.addAll([
        const Text(
          'Send Coins:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _recipientAddressController,
          decoration: const InputDecoration(
            labelText: 'Recipient Wallet Address',
          ),
        ),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Amount'),
          keyboardType: TextInputType.number,
        ),

        // Send status message
        if (_sendCoinsMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _sendCoinsMessage!,
              style: TextStyle(
                color:
                    _sendCoinsMessage!.contains('failed')
                        ? Colors.red
                        : Colors.green,
              ),
            ),
          ),

        // Send button
        ElevatedButton(
          onPressed: _isSending ? null : _sendCoinsFromBlockOwner,
          child:
              _isSending
                  ? const CircularProgressIndicator()
                  : const Text('Send Coins'),
        ),
      ]);
    }

    // Modal action buttons
    final actions = <Widget>[
      // Track block button (if block exists and callback provided)
      if (widget.registeredBlockData != null && widget.onTrackBlock != null)
        TextButton(
          onPressed: () {
            widget.onTrackBlock!(widget.registeredBlockData!);
            Navigator.of(context).pop();
          },
          child: const Text('Track Block Visually (Once)'),
        ),

      // Start periodic tracking button
      if (widget.registeredBlockData != null && widget.onTrackBlock != null)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onTrackBlock!(
              widget.registeredBlockData!.copyWith(
                startTracking: true, // Flag for continuous tracking
              ),
            );
          },
          child: const Text('Start Periodic Tracking'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),

      // Close modal button
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ];

    return AlertDialog(
      title: const Text('Tile Information'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: content,
        ),
      ),
      actions: actions,
    );
  }
}
