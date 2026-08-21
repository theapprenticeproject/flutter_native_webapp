import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/router.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/loading_view.dart';
import '../widgets/onboarding_shell.dart';
import 'onboarding_flow_controller.dart';

class OnboardingRuntime extends ConsumerStatefulWidget {
  const OnboardingRuntime({super.key});

  @override
  ConsumerState<OnboardingRuntime> createState() => _OnboardingRuntimeState();
}

class _OnboardingRuntimeState extends ConsumerState<OnboardingRuntime> {
  late final OnboardingFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingFlowController(
      ref: ref,
      onGoHome: () {
        if (mounted) context.go(AppRoutes.home);
      },
      onError: _showErrorSnack,
    )..addListener(_onControllerChanged);
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Loading onboarding...'),
      );
    }

    final loadError = _controller.loadError;
    if (loadError != null) {
      return ErrorView(
        title: 'Could not start onboarding',
        message: loadError,
        buttonText: 'Retry',
        onRetry: _controller.retry,
      );
    }

    return OnboardingShell(
      messages: _controller.messages,
      scrollController: _controller.scrollController,
      isBotTyping: _controller.isBotTyping,
      interaction: _controller.currentInteraction,
      showTextInput: _controller.showTextInput,
      inputController: _controller.inputController,
      inputFocusNode: _controller.inputFocusNode,
      inputHint: _controller.textInputHint,
      inputEnabled: _controller.inputEnabled,
      isVoiceMuted: _controller.isVoiceMuted,
      onToggleVoice: _controller.toggleVoice,
      onSubmitText: _controller.submitText,
    );
  }
}
