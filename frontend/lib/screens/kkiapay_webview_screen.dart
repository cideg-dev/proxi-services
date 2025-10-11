import 'dart:convert'; // New import for jsonDecode
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:frontend/services/api_constants.dart'; // For KKIAPAY_PUBLIC_KEY

class KkiapayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String ourTransactionId;

  const KkiapayWebviewScreen({
    Key? key,
    required this.paymentUrl,
    required this.ourTransactionId,
  }) : super(key: key);

  @override
  State<KkiapayWebviewScreen> createState() => _KkiapayWebviewScreenState();
}

class _KkiapayWebviewScreenState extends State<KkiapayWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            _handlePaymentResult({'status': 'failed', 'message': error.description});
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept Kkiapay's callback URL
            if (request.url.startsWith('${ApiConstants.baseUrl}/payment-callback')) {
              // Extract status from URL parameters or handle as needed
              final uri = Uri.parse(request.url);
              final status = uri.queryParameters['status']; // Assuming Kkiapay adds status to callback URL
              final transactionId = uri.queryParameters['transaction_id']; // Kkiapay's transaction ID

              if (status == 'success') {
                _handlePaymentResult({'status': 'success', 'kkiapay_transaction_id': transactionId});
              } else {
                _handlePaymentResult({'status': 'failed', 'message': 'Payment ${status ?? 'failed'}'});
              }
              return NavigationDecision.prevent; // Prevent WebView from loading the callback URL
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'KkiapayFlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Message from Kkiapay JS: ${message.message}');
          // Handle messages from JavaScript (e.g., payment status)
          try {
            final Map<String, dynamic> result = jsonDecode(message.message);
            _handlePaymentResult(result);
          } catch (e) {
            debugPrint('Error decoding Kkiapay JS message: $e');
            _handlePaymentResult({'status': 'failed', 'message': 'Invalid message from Kkiapay JS'});
          }
        },
      )
      ..loadRequest(Uri.parse(widget.paymentUrl)); // Load the initial payment URL
  }



  void _handlePaymentResult(Map<String, dynamic> result) {
    if (mounted) {
      Navigator.pop(context, result); // Return result to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Kkiapay'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
