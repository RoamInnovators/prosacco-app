import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> promptMemberSecurityOtp(
  BuildContext context, {
  String? sentTo,
}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Verify transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sentTo == null || sentTo.isEmpty
                    ? 'Enter the OTP sent to your registered contact.'
                    : 'Enter the OTP sent to $sentTo.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: '6-digit OTP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.length == 6) Navigator.pop(ctx, code);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}
