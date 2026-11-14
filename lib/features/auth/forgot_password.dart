import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

Future<void> showForgotPasswordDialog(BuildContext context, WidgetRef ref,
    {String initialEmail = '', bool lockEmail = false}) async {
  final ctrl = TextEditingController(text: initialEmail);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Password reset link has been sent to your email.'),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          readOnly: lockEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.contains('@')),
          child: const Text('Send link'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  String msg = 'Reset link has been sent. Check your Inbox / Spam folder.';
  try {
    await ref.read(authServiceProvider).resetPassword(ctrl.text.trim());
  } on FirebaseAuthException catch (e) {
    msg = e.message ?? 'Error';
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}