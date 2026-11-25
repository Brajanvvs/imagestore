import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_image/app.dart';
import 'package:store_image/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el invitado ve el catálogo y puede abrir el login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ImagoApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('IMAGO'), findsWidgets);
    expect(find.text('Fotografías para llevar'), findsOneWidget);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();
    expect(find.text('Invitado'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);

    await tester.tap(find.text('Iniciar sesión').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Usuario o correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
