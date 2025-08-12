# Explicando como o Beamer realmente funciona

Pensa no Beamer como um GPS para o seu app.

📍 Location → É como o endereço que você coloca no GPS (o path da rota).

🚗 BeamerDelegate → É o motorista que decide qual caminho seguir para chegar no endereço.

🏠 BeamLocation → É o mapa com todos os lugares possíveis que o motorista conhece (rotas e páginas do app).

📢 notifyListeners() → É como o motorista avisar para todo mundo no carro: "Mudamos de rota, olhem pela janela!", e aí a tela se atualiza.

No meu código:

O BeamerDelegate fica ouvindo mudanças do NavigationNotifier.
Quando você muda o estado (por exemplo, seleciona uma página no menu), o notifyListeners() dispara.
O Beamer consulta o BeamLocation e renderiza a tela correspondente.

# Resumo do Projeto e das Fases

## **Entrega 1: A Estrutura Fundamental (O Alicerce do Roteamento)**

**Objetivo:**
Criar o esqueleto da navegação usando Beamer, focando na navegação básica entre telas públicas, sem autenticação.

**O que foi feito:**

* Configuramos o `MaterialApp.router` com `BeamerParser` e `BeamerDelegate`.
* Criamos uma única `BeamLocation` chamada `AppLocation` que controla as rotas simples: `/`, `/pedidos` e `/item`.
* Implementamos as telas `HomeScreen`, `PedidosScreen` e `ItemListScreen`, todas públicas.
* Navegação entre telas por meio de botões que usam `Beamer.of(context).beamToNamed()` atualizando a URL e a navegação corretamente.

**Conceito chave:**
Um app funcional com navegação declarativa e URLs sincronizadas, mas sem restrições ou parâmetros dinâmicos. (example_estrutura.dart)

---

## **Entrega 2: A Camada de Autenticação (Protegendo as Rotas)**

**Objetivo:**
Adicionar segurança ao app, protegendo rotas específicas para que só usuários logados possam acessá-las.

**O que foi feito:**

* Criamos um `AuthState` com `ChangeNotifier` para controlar `isLoggedIn`.
* Adicionamos a tela de login `LoginScreen` com botão para alterar o estado de autenticação.
* No `BeamerDelegate`, incluímos um `BeamGuard` que protege as rotas `/pedidos` e `/item`.
* Se o usuário não está logado e tenta acessar essas rotas, é redirecionado automaticamente para `/login`.
* Implementamos botão de logout no Drawer que desloga e redireciona para a home.
* O `Beamer` escuta mudanças no estado para atualizar a navegação automaticamente.

**Conceito chave:**
Beamer atua como um porteiro, tomando decisões de acesso em tempo real baseado no estado do app, utilizando os recursos do Navigator 2.0 para proteger rotas. (example_auth.dart)

---

## **Entrega 3: Roteamento Avançado (Parâmetros e Pilhas Aninhadas)**

**Objetivo:**
Deixar a navegação mais realista, com rotas que possuem parâmetros dinâmicos e que representam hierarquias/pilhas de páginas.

**O que foi feito:**

* Expandimos `AppLocation` para incluir rotas dinâmicas: `/item/:itemId` e `/item/:itemId/detalhes`.
* Extraímos o parâmetro `itemId` da URL dentro do `BeamLocation` via `state.pathParameters`.
* Construímos a pilha dinâmica de páginas com base nesses parâmetros: lista -> detalhe -> detalhe avançado.
* Criamos as telas `ItemDetailsScreen` e `ItemDeepDetailsScreen` que recebem o `itemId` e exibem conteúdo específico.
* Atualizamos a `ItemListScreen` para navegar para rotas dinâmicas com IDs, como `/item/item_001`.
* Toda navegação mantém sincronizada a URL e permite uso direto da URL para acessar níveis profundos.

**Conceito chave:**
Você domina a navegação inteligente, onde a UI reflete exatamente o estado da URL, e pode construir pilhas complexas, dinâmicas e aninhadas de forma declarativa. (main.dart)

---

# Todas as Fases

* **Fase 1** te dá confiança e domínio do básico: um app navegável simples, sem distrações.
* **Fase 2** traz segurança, algo fundamental em apps reais, e ensina a integrar estado global com roteamento.
* **Fase 3** adiciona realismo e complexidade natural, mostrando como navegar com parâmetros, animações e pilhas profundas.



Assim, você constrói a paginação com o Beamer.

`by kads`
