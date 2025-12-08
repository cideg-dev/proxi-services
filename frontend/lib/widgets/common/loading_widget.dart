// frontend/lib/widgets/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool useLottie;

  const LoadingWidget({
    Key? key,
    this.message,
    this.color,
    this.size = 50,
    this.useLottie = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    Widget loader = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );

    if (useLottie) {
      try {
        loader = Lottie.asset(
          'assets/lottie/loading.json',
          height: size,
          width: size,
          repeat: true,
          reverse: false,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Si le fichier lottie n'existe pas, utiliser le loader par défaut
        loader = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        );
      }
    }

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return loader;
  }
}

class LoadingOverlay {
  static void show(BuildContext context, {String message = 'Chargement...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(size: 50),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}