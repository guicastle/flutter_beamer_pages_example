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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthState>();

    routerDelegate = BeamerDelegate(
      initialPath: '/splash',
      locationBuilder: (routeInformation, _) => AppLocation(routeInformation),
      guards: [
        BeamGuard(
          // pathPatterns: ['/', '/pedidos', '/item', '/item/*'],
          pathPatterns: ['/splash', '/login'],
          guardNonMatching: true,
          check: (context, location) => authState.isLoggedIn,
          beamToNamed: (_, __) => '/login',
          onCheckFailed: (_, __) => '/not-found',
        ),
      ],
    );
    ;

    if (mounted) {
      authState.addListener(() {
        routerDelegate.update(rebuild: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Beamer Entrega 2 Corrigido',
      routeInformationParser: BeamerParser(),
      routerDelegate: routerDelegate,
    );
  }
}

// ---------------- BeamLocation ----------------
class AppLocation extends BeamLocation<BeamState> {
  AppLocation(RouteInformation super.routeInformation);

  String lastUrl = "";

  @override
  List<String> get pathPatterns => [
    '/',
    '/splash',
    '/login',
    '/pedidos',
    '/item',
    '/item/:itemId',
    '/item/:itemId/detalhes',
  ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    final uri = state.uri;

    final pages = <BeamPage>[];

    if (uri.path == '/splash') {
      pages.add(
        BeamPage(
          key: const ValueKey('splash'),
          title: 'Splash',
          type: BeamPageType.noTransition,
          child: const SplashScreen(),
        ),
      );
    } else if (uri.path == '/') {
      pages.add(
        BeamPage(
          key: const ValueKey('home'),
          title: 'Home',
          type:
              lastUrl == "/login"
                  ? BeamPageType.slideRightTransition
                  : BeamPageType.noTransition,
          child: const HomeScreen(),
        ),
      );
    }

    if (uri.path == '/login') {
      pages.add(
        BeamPage(
          key: const ValueKey('login'),
          title: 'Login',
          type: BeamPageType.slideLeftTransition,
          child: const LoginScreen(),
        ),
      );
    } else if (uri.path == '/pedidos') {
      pages.add(
        BeamPage(
          key: const ValueKey('pedidos'),
          title: 'Pedidos',
          type: BeamPageType.noTransition,
          child: const PedidosScreen(),
        ),
      );
    } else if (uri.pathSegments.contains('item')) {
      pages.add(
        BeamPage(
          key: const ValueKey('item'),
          title: 'Itens',
          type: BeamPageType.noTransition,
          child: const ItemListScreen(),
        ),
      );

      if (state.pathParameters.containsKey('itemId')) {
        final itemId = state.pathParameters['itemId']!;
        pages.add(
          BeamPage(
            key: ValueKey('item-$itemId'),
            title: 'Detalhes do Item',
            type: BeamPageType.slideRightTransition,
            child: ItemDetailsScreen(itemId: itemId),
          ),
        );

        if (uri.pathSegments.contains('detalhes')) {
          pages.add(
            BeamPage(
              key: ValueKey('item-$itemId-detalhes'),
              title: 'Detalhes Avançados',
              type: BeamPageType.slideRightTransition,
              child: ItemDeepDetailsScreen(itemId: itemId),
            ),
          );
        }
      }
    }

    if (uri.path == '/not-found') {
      pages.add(
        BeamPage(
          key: const ValueKey('not-found'),
          title: '404',
          child: const NotFoundScreen(),
        ),
      );
    }

    lastUrl = uri.path;
    return pages;
  }
}

// ---------------- Responsive Scaffold (VERSÃO CORRIGIDA) ----------------
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          // Layout para Desktop/Web com menu fixo à esquerda
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 240,
                  child: Drawer(
                    child: _AppDrawerContent(), // Usando o novo widget
                  ),
                ),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(title: Text(title)),
                    body: child,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout para Mobile com Drawer que abre e fecha
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            drawer: const Drawer(
              child: _AppDrawerContent(), // Usando o novo widget
            ),
            body: child,
          );
        }
      },
    );
  }
}

// NOVO WIDGET para o conteúdo do Drawer, que resolve o problema de contexto
class _AppDrawerContent extends StatelessWidget {
  const _AppDrawerContent();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            "Menu Principal",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () => _navigateTo(context, '/'),
        ),
        ListTile(
          leading: const Icon(Icons.shopping_cart),
          title: const Text('Pedidos'),
          onTap: () => _navigateTo(context, '/pedidos'),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt),
          title: const Text('Itens'),
          onTap: () => _navigateTo(context, '/item'),
        ),
        const Divider(),
        if (authState.isLoggedIn)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authState.logout();
              _navigateTo(context, '/');
            },
          )
        else
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Login'),
            onTap: () => _navigateTo(context, '/login'),
          ),
      ],
    );
  }

  // Função agora é um método privado do _AppDrawerContent
  void _navigateTo(BuildContext context, String route) {
    // Agora o `context` está correto e o Scaffold será encontrado.
    // Usamos Navigator.pop(context) para fechar o Drawer, que é a forma padrão.
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
    Beamer.of(context).beamToNamed(route);
  }
}

// ---------------- Screens (Sem alterações) ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScaffold(
      title: 'Home',
      child: Center(child: Text('Bem-vindo à tela inicial!')),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthState>();

    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Fazer Login'),
        onPressed: () {
          authState.login();
          Beamer.of(context).beamToNamed('/');
        },
      ),
    );
  }
}

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScaffold(
      title: 'Pedidos',
      child: Center(child: Text('Aqui você vê a lista de pedidos.')),
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
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final id = items[index];
          return ListTile(
            title: Text('Ver detalhes de $id'),
            onTap: () => Beamer.of(context).beamToNamed('/item/$id'),
            trailing: const Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;
  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes: $itemId')),
      body: Center(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes Avançados')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Informações avançadas sobre o item: $itemId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamBack(),
              child: const Text('Voltar para detalhes do item'),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      final authState = context.read<AuthState>();

      if (authState.isLoggedIn) {
        Beamer.of(context).beamToNamed('/');
      } else {
        Beamer.of(context).beamToNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // loading simples
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '404 - Página não encontrada',
          style: TextStyle(fontSize: 20, color: Colors.red),
        ),
      ),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Sem acesso - favor logar para continuar',
          style: TextStyle(fontSize: 18, color: Colors.orange),
        ),
      ),
    );
  }
}
