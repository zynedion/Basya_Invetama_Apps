import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/core/widgets/visible_page_state.dart';

class Probe extends StatefulWidget {
  const Probe(this.changed, {super.key});
  final ValueChanged<bool> changed;
  @override
  State<Probe> createState() => ProbeState();
}

class ProbeState extends State<Probe> with VisiblePageState<Probe> {
  @override
  void onPageVisibilityChanged(bool v) => widget.changed(v);
  @override
  Widget build(BuildContext c) => const SizedBox();
}

void main() {
  testWidgets('hidden tabs and covered routes stay inactive on resume', (
    tester,
  ) async {
    final changes = <bool>[];
    final navigator = GlobalKey<NavigatorState>();
    final enabled = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (_, v, child) => TickerMode(enabled: v, child: child!),
          child: Probe(changes.add),
        ),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    expect(changes, isEmpty);
    enabled.value = true;
    await tester.pump();
    expect(changes.last, true);
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(changes.last, false);
    final count = changes.length;
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    expect(changes.length, count);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(changes.last, true);
    await tester.pumpWidget(const SizedBox());
    enabled.dispose();
  });
}

