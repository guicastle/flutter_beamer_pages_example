import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AuthState(), child: const MyApp()),
  );
}

// ---------------- AUTH STATE ----------------
class AuthState extends ChangeNotifier {
  bool isLoggedIn = false;

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }
}

// ---------------- APP ----------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BeamerDelegate routerDelegate;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();

    routerDelegate = BeamerDelegate(
      locationBuilder: (routeInformation, _) => AppLocation(routeInformation),
      guards: [
        BeamGuard(
          pathPatterns: ['/pedidos', '/item'],
          check: (context, location) => authState.isLoggedIn,
          beamToNamed: (_, __) => '/login',
        ),
      ],
    );

    authState.addListener(routerDelegate.update);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Beamer Entrega 2',
      routeInformationParser: BeamerParser(),
      routerDelegate: routerDelegate,
    );
  }
}

// ---------------- BeamLocation ----------------
class AppLocation extends BeamLocation<BeamState> {
  AppLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => ['/', '/login', '/pedidos', '/item'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    final path = Uri.parse(state.uri.toString()).path;

    final pages = [
      const BeamPage(key: ValueKey('home'), title: 'Home', child: HomeScreen()),
    ];

    final routes = {
      '/login': const BeamPage(
        key: ValueKey('login'),
        title: 'Login',
        child: LoginScreen(),
      ),
      '/pedidos': const BeamPage(
        key: ValueKey('pedidos'),
        title: 'Pedidos',
        child: PedidosScreen(),
      ),
      '/item': const BeamPage(
        key: ValueKey('item'),
        title: 'Itens',
        child: ItemListScreen(),
      ),
    };

    if (routes.containsKey(path)) {
      pages.add(routes[path]!);
    }

    return pages;
  }
}

// ---------------- Responsive Scaffold ----------------
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    final drawerContent = ListView(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text("Menu", style: TextStyle(color: Colors.white)),
        ),
        _drawerItem(context, 'Home', '/'),
        _drawerItem(context, 'Pedidos', '/pedidos'),
        _drawerItem(context, 'Itens', '/item'),
        if (authState.isLoggedIn)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authState.logout();
              Beamer.of(context).beamToNamed('/');
            },
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 200, child: drawerContent),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(title: Text(title)),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            drawer: Drawer(child: drawerContent),
            body: child,
          );
        }
      },
    );
  }

  ListTile _drawerItem(BuildContext context, String title, String route) {
    return ListTile(
      leading: const Icon(Icons.arrow_right),
      title: Text(title),
      onTap: () => Beamer.of(context).beamToNamed(route),
    );
  }
}

// ---------------- Screens ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Home',
      child: _buttonColumn(context, [
        ['Ir para Pedidos (Protegido)', '/pedidos'],
        ['Ir para Itens (Protegido)', '/item'],
        ['Ir para Login', '/login'],
      ]),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthState>();

    return ResponsiveScaffold(
      title: 'Login',
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Fazer Login'),
          onPressed: () {
            authState.login();
            Beamer.of(context).beamToNamed('/');
          },
        ),
      ),
    );
  }
}

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Pedidos',
      child: _buttonColumn(context, [
        ['Voltar para Home', '/'],
        ['Ir para Itens', '/item'],
      ]),
    );
  }
}

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Itens',
      child: _buttonColumn(context, [
        ['Voltar para Home', '/'],
        ['Ir para Pedidos', '/pedidos'],
      ]),
    );
  }
}

// ---------------- Widgets Auxiliares ----------------
Widget _buttonColumn(BuildContext context, List<List<String>> buttons) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          buttons
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () => Beamer.of(context).beamToNamed(b[1]),
                    child: Text(b[0]),
                  ),
                ),
              )
              .toList(),
    ),
  );
}
