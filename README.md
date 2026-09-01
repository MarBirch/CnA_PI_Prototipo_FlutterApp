# 📱 Comida & Afeto — Aplicativo Mobile (Flutter)

O **Comida & Afeto Mobile** é a aplicação cliente do projeto integrador/TCC de compra, venda e agendamento de marmitas saudáveis. O aplicativo permite que o consumidor explore marmiterias parceiras, personalize e faça pedidos de refeições, organize sua rotina alimentar semanal e consulte uma assistente nutricional virtual com inteligência artificial (**DeepSeek-R1** rodando localmente via Ollama).

---

## ✨ Funcionalidades Principais

- 🔐 **Autenticação & Perfil**: Login, cadastro e gestão de conta do cliente.
- 🍱 **Exploração de Cardápios**: Busca por marmiterias parceiras, visualização de pratos e detalhes nutricionais.
- 🛒 **Carrinho & Agendamento**: Montagem de pedidos, cálculo dinâmico de valores e agendamento de entrega das refeições.
- 📦 **Acompanhamento de Pedidos**: Histórico de compras e status do pedido em tempo real.
- 🤖 **Assistente Nutricional IA ("Nutri")**: Chat com suporte a Markdown alimentado pelo modelo **DeepSeek-R1** para tirar dúvidas sobre calorias, macronutrientes, combinações de alimentos e tabela nutricional.

---

## 🛠️ Tecnologias Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.8.1)
- **Linguagem**: Dart
- **Gerenciamento de Estado**: `provider`
- **Requisições HTTP**: `http`
- **Persistência Local**: `shared_preferences`
- **Renderização Markdown**: `markdown_widget`
- **Design & UI**: `google_fonts`, `carousel_slider`, `cupertino_icons`

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
1. **Flutter SDK** instalado e adicionado ao `PATH`.
2. **Backend Spring Boot** em execução (`http://localhost:8080`).
3. **Ollama** em execução com o modelo `deepseek-r1`:
   ```bash
   ollama pull deepseek-r1
   ollama run deepseek-r1
   ```

### Passo a Passo
1. Baixe as dependências do projeto:
   ```bash
   flutter pub get
   ```

2. Execute a aplicação no dispositivo/emulador desejado:
   ```bash
   flutter run
   ```

---

## 📄 Estrutura de Pastas (`lib/`)

- `main.dart`: Ponto de entrada do aplicativo.
- `app_theme.dart`: Design System e temas (Light/Dark).
- `login.dart` / `cadastro.dart`: Telas de autenticação.
- `home.dart` / `marmiteria.dart`: Vitrine e busca de estabelecimentos.
- `cardapio.dart`: Itens do cardápio e detalhes das refeições.
- `carrinho.dart`: Carrinho de compras e fechamento de pedido.
- `pedidos.dart` / `pedido_model.dart`: Acompanhamento e modelo de pedidos.
- `chat.dart` / `chat_model.dart` / `message.dart`: Interface e modelo do assistente virtual.
- `configuracoes.dart` / `user_settings.dart`: Preferências do usuário.

---

## 📖 Documentação Geral
Para visualizar a documentação completa do ecossistema do projeto (Mobile + API Spring Boot + DeepSeek-R1), consulte o arquivo `DOCUMENTACAO_PROJETO.md` na raiz do repositório.
