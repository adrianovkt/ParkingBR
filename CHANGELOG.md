# Changelog

## [1.1.0] - 2023-10-27

### Adicionado
- **Persistência de Dados**: Implementada a gravação local de Veículos e Tickets utilizando `SharedPreferences`. Os dados agora são mantidos mesmo após fechar o aplicativo.
- **Validação de Placas**: Reconhecimento e formatação automática para padrões de placa Mercosul (`LLLNLNN`) e Antiga (`LLL-NNNN`).
- **Privacidade e Segurança**: Adicionada máscara de CPF no perfil (`***.123.***-**`) e formatação automática com limite de caracteres no editor de perfil.
- **Melhorias de UI**: Novos diálogos e modais com maior contraste visual para campos de entrada.

### Corrigido
- **Erros de Compilação**: Resolvidos conflitos de tipos e membros depreciados que impediam o build do projeto (`compileFlutterBuildDebug`).
- **Performance do Teclado**: Otimizada a subida do teclado em formulários para evitar lentidão e travamentos na interface.
- **Status Bar**: Corrigida a visibilidade e as cores da barra de status para se adaptarem corretamente aos temas Claro e Escuro.
- **Layout de Configurações**: Ajustado o título da página de configurações para não sobrepor o botão de voltar.
- **Depreciações**: Substituído `WillPopScope` pelo novo `PopScope` e `withOpacity` por `withValues`.

### Alterado
- **Padronização de Design**: Unificação de raios de borda (`AppRadius`), espaçamentos (`AppSpacing`) e sistema de cores seguindo as diretrizes do Material 3.
- **Refatoração de Providers**: Melhoria na lógica de gerenciamento de estado para garantir a integridade dos dados.
