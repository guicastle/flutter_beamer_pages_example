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
  List<String> get pathPatterns => [
    '/',
    '/login',
    '/pedidos',
    '/item',
    '/item/:itemId',
    '/item/:itemId/detalhes',
  ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    final uri = Uri.parse(state.uri.toString());

    final pages = <BeamPage>[
      // Home -> fadeIn
      BeamPage(
        key: const ValueKey('home'),
        title: 'Home',
        type: BeamPageType.fadeTransition,
        child: const HomeScreen(),
      ),
    ];

    // Login -> slideLeft
    if (uri.path == '/login') {
      pages.add(
        BeamPage(
          key: const ValueKey('login'),
          title: 'Login',
          type: BeamPageType.slideLeftTransition,
          child: const LoginScreen(),
        ),
      );
    }
    // Pedidos -> slideRight
    else if (uri.path == '/pedidos') {
      pages.add(
        BeamPage(
          key: const ValueKey('pedidos'),
          title: 'Pedidos',
          type: BeamPageType.slideRightTransition,
          child: const PedidosScreen(),
        ),
      );
    }
    // Item list / item details / item deep details
    else if (uri.pathSegments.contains('item')) {
      // Item list -> slideUp (mapped to slideTopTransition)
      pages.add(
        BeamPage(
          key: const ValueKey('item'),
          title: 'Itens',
          type: BeamPageType.slideTopTransition,
          child: const ItemListScreen(),
        ),
      );

      // If there's an itemId parameter, add details page -> slide (generic)
      if (state.pathParameters.containsKey('itemId')) {
        final itemId = state.pathParameters['itemId']!;

        // Item details -> slideDown (approximated with slideTransition)
        pages.add(
          BeamPage(
            key: ValueKey('item-$itemId'),
            title: 'Detalhes do Item',
            type: BeamPageType.slideTransition,
            child: ItemDetailsScreen(itemId: itemId),
          ),
        );

        // Item deep details -> scale
        if (uri.path.endsWith('/detalhes')) {
          pages.add(
            BeamPage(
              key: ValueKey('item-$itemId-detalhes'),
              title: 'Detalhes Avançados',
              type: BeamPageType.scaleTransition,
              child: ItemDeepDetailsScreen(itemId: itemId),
            ),
          );
        }
      }
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
    final items = ['item_001', 'item_002', 'item_003'];

    return ResponsiveScaffold(
      title: 'Itens',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...items.map(
              (id) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => Beamer.of(context).beamToNamed('/item/$id'),
                  child: Text('Ver detalhes de $id'),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/'),
              child: const Text('Voltar para Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;
  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Detalhes do Item',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Você está vendo os detalhes do item: $itemId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      Beamer.of(context).beamToNamed('/item/$itemId/detalhes'),
              child: const Text('Ver detalhes avançados'),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/item'),
              child: const Text('Voltar para lista de itens'),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemDeepDetailsScreen extends StatelessWidget {
  final String itemId;
  const ItemDeepDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Detalhes Avançados',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Informações avançadas sobre o item: $itemId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/item/$itemId'),
              child: const Text('Voltar para detalhes do item'),
            ),
          ],
        ),
      ),
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
