# KartzDataService

Um sistema de gerenciamento de dados robusto para Roblox com suporte a persistência de perfil, replicação automática e padrão de dados estruturado.

## Instalação

## Made by KartzDev :>

### Via Wally

Adicione a seguinte linha ao seu `wally.toml`:

```toml
[dependencies]
DataServiceV2 = "kartzrbx/dataservicev2@0.1.1"
```

Depois execute:

```bash
wally install
```

### Uso

```lua
local DataService = require(game:GetService("ReplicatedStorage").Packages.DataServiceV2)

-- Inicializar DataService
DataService.init()

-- Usar para gerenciar dados do jogador
```

## Recursos

- Gerenciamento automático de dados do jogador
- Sincronização entre Cliente e Servidor
- Sistema de replicação inteligente
- Integração com ProfileStore para persistência
- Sistema de eventos com Signal

## Estrutura do Projeto

- `init.luau` - Ponto de entrada principal
- `Client.luau` - Lógica do lado do cliente
- `Server.luau` - Lógica do lado do servidor
- `Data.luau` - Estrutura de dados
- `Replicator.luau` - Sistema de replicação
- `Path.luau` - Utilitários de caminho
- `Enums.luau` - Enumerações

## Dependências

- `sleitnick/signal@2.0.3` - Sistema de eventos
- `lm-loleris/profilestore@1.0.3` - Persistência de dados (server-only)

## Desenvolvimento

Para construir o projeto com Rojo:

```bash
rojo build -o "KartzDataService.rbxlx"
```

Para servir em tempo real:

```bash
rojo serve
```

Mais informações: [Documentação Rojo](https://rojo.space/docs)
