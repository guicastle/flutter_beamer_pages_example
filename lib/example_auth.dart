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
      locationBuilder: (routeInformation, _) {
        return AppLocation(routeInformation);
      },
      guards: [
        BeamGuard(
          pathPatterns: ['/pedidos', '/item'],
          check: (context, location) => authState.isLoggedIn,
          beamToNamed: (_, __) => '/login',
        ),
      ],
      // Importante: listen to authState to rebuild guard automaticamente
      // Usamos listenable para informar guard da mudança de estado
      // (opcional, para garantir atualização automática)
      // listenable: authState,
    );

    // Opcional: adicionar listener para forçar rebuild do delegate
    authState.addListener(() {
      routerDelegate.update(); // notifica Beamer que mudou
    });
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
    final uri = Uri.parse(state.uri.toString());

    // Se a rota for desconhecida, retorna só Home
    if (!['/', '/login', '/pedidos', '/item'].contains(uri.path)) {
      return [
        const BeamPage(
          key: ValueKey('home'),
          title: 'Home',
          child: HomeScreen(),
        ),
      ];
    }

    final pages = [
      const BeamPage(key: ValueKey('home'), title: 'Home', child: HomeScreen()),
    ];

    if (uri.path == '/login') {
      pages.add(
        const BeamPage(
          key: ValueKey('login'),
          title: 'Login',
          child: LoginScreen(),
        ),
      );
    }

    if (uri.path == '/pedidos') {
      pages.add(
        const BeamPage(
          key: ValueKey('pedidos'),
          title: 'Pedidos',
          child: PedidosScreen(),
        ),
      );
    }

    if (uri.path == '/item') {
      pages.add(
        const BeamPage(
          key: ValueKey('item'),
          title: 'Itens',
          child: ItemListScreen(),
        ),
      );
    }

    return pages;
  }
}

// ---------------- Screens ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (authState.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authState.logout();

                Beamer.of(context).beamToNamed('/');
                // Navegação automática pelo guard, sem chamar beamToNamed aqui
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/pedidos'),
              child: const Text('Ir para Pedidos (Protegido)'),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/item'),
              child: const Text('Ir para Itens (Protegido)'),
            ),
            if (!authState.isLoggedIn)
              ElevatedButton(
                onPressed: () => Beamer.of(context).beamToNamed('/login'),
                child: const Text('Ir para Login'),
              ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            authState.login();
            Beamer.of(context).beamToNamed('/');
            // Navegação automática pelo guard
          },
          child: const Text('Fazer Login'),
        ),
      ),
    );
  }
}

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authState.logout();
              Beamer.of(context).beamToNamed('/');
              // Navegação automática pelo guard
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/'),
              child: const Text('Voltar para Home'),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/item'),
              child: const Text('Ir para Itens (Protegido)'),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authState.logout();

              Beamer.of(context).beamToNamed('/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/'),
              child: const Text('Voltar para Home'),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/pedidos'),
              child: const Text('Ir para Pedidos (Protegido)'),
            ),
          ],
        ),
      ),
    );
  }
}
