import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/presentation/screens/purchase_flow_screen.dart';

void main() {
  test('new items created from purchase flow are inactive by default', () {
    expect(purchaseFlowNewItemDefaultIsActive, isFalse);
  });
}
