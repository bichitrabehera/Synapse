import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(),
      if (message != null) Padding(
        padding: const EdgeInsets.only(top:12.0),
        child: Text(message!),
      )
    ]));
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
      if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry'))
    ]));
  }
}