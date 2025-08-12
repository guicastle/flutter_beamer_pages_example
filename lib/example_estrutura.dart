import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final routerDelegate = BeamerDelegate(
    locationBuilder: (routeInformation, _) {
      return AppLocation(routeInformation);
    },
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Beamer Entrega 1',
      routeInformationParser: BeamerParser(),
      routerDelegate: routerDelegate,
    );
  }
}

// ---------------- BeamLocation ----------------
class AppLocation extends BeamLocation<BeamState> {
  AppLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => ['/', '/pedidos', '/item'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    final uri = Uri.parse(state.uri.toString());

    final pages = [
      BeamPage(key: const ValueKey('home'), title: 'Home', child: HomeScreen()),
    ];

    if (uri.pathSegments.contains('pedidos')) {
      pages.add(
        BeamPage(
          key: const ValueKey('pedidos'),
          title: 'Pedidos',
          child: PedidosScreen(),
        ),
      );
    }

    if (uri.pathSegments.contains('item')) {
      pages.add(
        BeamPage(
          key: const ValueKey('item'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/pedidos'),
              child: const Text('Ir para Pedidos'),
            ),
            ElevatedButton(
              onPressed: () => Beamer.of(context).beamToNamed('/item'),
              child: const Text('Ir para Itens'),
            ),
          ],
        ),
      ),
    );
  }
}

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
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
              child: const Text('Ir para Itens'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Itens')),
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
              child: const Text('Ir para Pedidos'),
            ),
          ],
        ),
      ),
    );
  }
}
