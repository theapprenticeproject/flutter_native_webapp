import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/build_info.dart';

/// Long-press [child] to show the build line (the commit, the Flutter version
/// and the Worker the build talks to). Long-press again to hide it. A tester
/// reads it before a deploy, to be sure the build is the right one.
class BuildInfoToggle extends StatefulWidget {
  const BuildInfoToggle({required this.child, super.key});

  final Widget child;

  @override
  State<BuildInfoToggle> createState() => _BuildInfoToggleState();
}

class _BuildInfoToggleState extends State<BuildInfoToggle> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => setState(() => _shown = !_shown),
          child: widget.child,
        ),
        if (_shown)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              BuildInfo.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
