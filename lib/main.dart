import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AuthState(), child: const MyApp()),
  );
}

// ---------------- AUTH STATE ----------------
class AuthState extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool? isLoggedIn;
  // Adicione este flag de volta. Ele é crucial.
  bool isAuthCheckComplete = false;

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    isLoggedIn = token != null;
    // Marca a verificação como completa ANTES de notificar.
    isAuthCheckComplete = true;
    notifyListeners();
  }

  // ... resto da classe AuthState ...
  Future<void> login() async {
    await _storage.write(key: 'auth_token', value: 'fake_auth_token_123');
    isLoggedIn = true;
    isAuthCheckComplete = true; // Garante que o estado seja consistente
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    isLoggedIn = false;
    isAuthCheckComplete = true; // Garante que o estado seja consistente
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

  // late AuthState authState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthState authState = context.read<AuthState>();

    routerDelegate = BeamerDelegate(
      initialPath: '/splash',
      locationBuilder: (routeInformation, _) => AppLocation(routeInformation),
      buildListener: (context, delegate) async {
        await authState.checkAuthStatus();
      },
      guards: [
        BeamGuard(
          pathPatterns: ['/splash', '/login'],
          guardNonMatching: true,
          check: (context, location) {
            final authState = context.read<AuthState>();
            return !authState.isAuthCheckComplete ||
                (authState.isLoggedIn ?? false);
          },
          beamToNamed: (_, __) => '/login',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch<AuthState>();

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
    '/home',
    '/splash',
    '/login',
    '/pedidos',
    '/item',
    '/item/:itemId',
    '/item/:itemId/detalhes',
  ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    // A lógica do switch permanece a mesma, pois é limpa e eficiente.
    // O problema estava apenas nos patterns que alimentavam o `state`.
    final path = state.uri.path;

    // Para rotas simples, podemos usar o path completo.
    switch (path) {
      case '/home':
        return _homeStack;
      case '/splash':
        return [
          const BeamPage(
            key: ValueKey('splash'),
            title: 'Splash',
            type: BeamPageType.noTransition,
            child: SplashScreen(),
          ),
        ];
      case '/login':
        return [
          const BeamPage(
            key: ValueKey('login'),
            title: 'Login',
            type: BeamPageType.slideLeftTransition,
            child: LoginScreen(),
          ),
        ];
      case '/pedidos':
        return [
          ..._homeStack,
          const BeamPage(
            key: ValueKey('pedidos'),
            title: 'Pedidos',
            type: BeamPageType.noTransition,
            child: PedidosScreen(),
          ),
        ];
    }

    // Para rotas complexas com parâmetros, verificamos os segmentos.
    if (state.uri.pathSegments.contains('item')) {
      final pages = <BeamPage>[
        ..._homeStack,
        const BeamPage(
          key: ValueKey('item'),
          title: 'Itens',
          type: BeamPageType.noTransition,
          child: ItemListScreen(),
        ),
      ];

      // Com os pathPatterns corretos, o Beamer agora preenche os pathParameters.
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
        if (state.uri.pathSegments.contains('detalhes')) {
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

      lastUrl = state.uri.path;
      return pages;
    }

    // O `default` agora funciona como esperado para qualquer rota não reconhecida.
    return [
      const BeamPage(
        key: ValueKey('not-found'),
        title: 'Página Não Encontrada',
        child: NotFoundScreen(),
      ),
    ];
  }

  List<BeamPage> get _homeStack => [
    BeamPage(
      key: const ValueKey('home'),
      title: 'Home',
      type:
          lastUrl == "/login"
              ? BeamPageType.slideRightTransition
              : BeamPageType.noTransition,
      child: const HomeScreen(),
    ),
  ];
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
          onTap: () => _navigateTo(context, '/home'),
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
        if (authState.isLoggedIn == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (authState.isLoggedIn!)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authState.logout();
              _navigateTo(context, '/login');
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
        onPressed: () async {
          await authState.login();
          Beamer.of(context).beamToNamed('/home');
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
    // 1. Dispara a verificação inicial, mas não tenta ler o resultado aqui.
    context.read<AuthState>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Usa context.watch() para OUVIR as mudanças do AuthState.
    //    Isso fará o widget reconstruir quando notifyListeners() for chamado.
    final authState = context.watch<AuthState>();

    // 3. A LÓGICA DE NAVEGAÇÃO:
    //    Verifica se a checagem JÁ TERMINOU.
    if (authState.isAuthCheckComplete) {
      // Usa addPostFrameCallback para navegar com segurança APÓS o build.
      // Isso evita erros de "setState() or markNeedsBuild() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Garante que o widget ainda está na árvore.
          final targetRoute = authState.isLoggedIn! ? '/home' : '/login';
          Beamer.of(context).beamToReplacementNamed(targetRoute);
        }
      });
    }

    // 4. Enquanto a verificação não termina (ou durante o frame do redirecionamento),
    //    a tela SEMPRE exibe o indicador de carregamento.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página Não Encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Oops! A página que você procurava não existe.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/home'),
              child: const Text('Voltar para a Home'),
            ),
          ],
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

// // main oficial
// import 'package:flutter/material.dart';
// import 'package:beamer/beamer.dart';
// import 'package:provider/provider.dart';

// import 'notifiers/auth_state.dart';
// import 'utils/routes/app_location_beamer.dart';

// void main() {
//   runApp(
//     ChangeNotifierProvider(create: (_) => AuthState(), child: const MyApp()),
//   );
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late BeamerDelegate routerDelegate;
//   List<String> get publicRoutes => ['/login', '/cadastro', '/esqueci-senha'];

//   @override
//   void initState() {
//     super.initState();
//     final authState = context.read<AuthState>();

//     routerDelegate = BeamerDelegate(
//       locationBuilder: (routeInformation, _) => AppLocation(routeInformation),
//       guards: [
//         BeamGuard(
//           pathPatterns: ['/pedidos', '/item'],
//           check: (context, location) {
//             final path = location.state.routeInformation.uri.path;

//             // Se for pública, permite
//             if (publicRoutes.contains(path.toString())) {
//               return true;
//             }
//             // Se for privada, verifica login
//             return authState.isLoggedIn;
//           },
//           beamToNamed: (origin, target) {
//             if (authState.isLoggedIn) {
//               return target.state.routeInformation.uri.path;
//             }

//             return '/login';
//           },
//         ),
//       ],
//     );

//     authState.addListener(routerDelegate.update);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       debugShowCheckedModeBanner: false,
//       title: 'Beamer',
//       routeInformationParser: BeamerParser(),
//       routerDelegate: routerDelegate,
//     );
//   }
// }
