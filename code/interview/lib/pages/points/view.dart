part of 'index.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(title: const Text('积分')),
      body: const SafeArea(child: AppEmpty(message: '请从充值或明细入口进入')),
    );
  }
}
