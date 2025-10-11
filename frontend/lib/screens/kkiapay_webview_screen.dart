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
            // Inject JavaScript to handle Kkiapay payment
            _injectKkiapayJavaScript();
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

  void _injectKkiapayJavaScript() {
    // This JavaScript will be executed inside the WebView
    // It loads the Kkiapay JS SDK and initiates the payment
    final String jsCode = '''
      (function() {
        // Load Kkiapay JS SDK from CDN
        const script = document.createElement('script');
        script.src = 'https://unpkg.com/kkiapay/dist/kkiapay.bundle.js';
        script.onload = function() {
          const k = kkiapay("${ApiConstants.kkiapayPublicKey}", {
            sandbox: ${ApiConstants.kkiapaySandbox}, // Assuming a boolean env var
            theme: "#0095ff", // Optional: customize theme
            // Add other Kkiapay options as needed
          });

          // Example: Initiate debit payment
          // This part needs to be dynamic based on the payment initiation
          // For now, we'll assume the paymentUrl already contains enough info
          // or we'll pass it from Flutter.
          // The paymentUrl from backend is already a Kkiapay URL, so we might not need to call k.debit() here.
          // Instead, we might just need to ensure the WebView loads the Kkiapay payment page.

          // If the paymentUrl is a direct Kkiapay payment page,
          // the user will interact with it directly.
          // We primarily need to listen for the callback URL.

          // Example of sending message back to Flutter (if needed)
          // KkiapayFlutterChannel.postMessage(JSON.stringify({ status: 'success', transactionId: '...' }));
        };
        document.head.appendChild(script);
      })();
    ''';
    _controller.runJavaScript(jsCode);
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
