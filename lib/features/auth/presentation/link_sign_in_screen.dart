import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../domain/auth/auth_provider.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../shared/errors/friendly_error.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';

/// Opens the WhatsApp magic link (`/l/<code>`). It swaps the code for the
/// student tokens, then shows the name picker if the phone has several
/// children, or goes on to Home if it has one (R-32, R-34).
class LinkSignInScreen extends ConsumerStatefulWidget {
  const LinkSignInScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<LinkSignInScreen> createState() => _LinkSignInScreenState();
}

class _LinkSignInScreenState extends ConsumerState<LinkSignInScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    if (_error != null) setState(() => _error = null);
    try {
      final repository = await ref.read(magicLinkRepositoryProvider.future);
      final result = await repository.redeem(widget.code);
      ref.invalidate(activeProfileProvider);
      if (!mounted) return;
      context.go(result.needsPicker ? AppRoutes.profileSelect : AppRoutes.home);
    } catch (e) {
      debugPrint('Opening the link failed: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error == null) {
      return const Scaffold(body: LoadingView(message: 'Opening your link...'));
    }

    // A bad or old link cannot be fixed by trying again.
    final friendly = describeError(error);
    if (friendly.action == ErrorAction.signInAgain) {
      return const ErrorView(
        title: 'This link is not working',
        message: 'Please ask for a new link on WhatsApp.',
        buttonText: '',
        onRetry: _noop,
        showButton: false,
      );
    }

    return ErrorView(
      title: friendly.title,
      message: friendly.message,
      buttonText: friendly.buttonText,
      onRetry: _open,
    );
  }
}

void _noop() {}
