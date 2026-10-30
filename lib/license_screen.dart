import 'package:flutter/material.dart';

import 'core/services.dart';
import 'ui/markdown.dart';
import 'ui/widgets.dart';

/// El acuerdo para leerlo desde Ajustes (la primera vez se acepta en WelcomeScreen).
class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('licenseH'))),
        body: PageList(children: [MiniMarkdown(tr('licenseBody'))]),
      );
}
