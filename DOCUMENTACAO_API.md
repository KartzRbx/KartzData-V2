# DataServiceV2 - API e exemplos de uso

Documentacao pratica para usar `kartzrbx/dataservicev2@2.3.3` em jogos Roblox com Wally/Rojo.

O DataServiceV2 centraliza persistencia com ProfileStore embutido, leitura/escrita por paths tipados (`Paths`), replicacao automatica servidor/cliente via QuickNet e limpeza de conexoes com Janitor. A partir da `2.2.x`, `signal`, `quicknet` e `janitor` vem **embutidos** no pacote (`src/Packages`) — nao e necessario declara-los no `wally.toml` do jogo.

Novidades na `2.3.x`:

- Overlay transitório (`SetTransient`, `UpdateTransient`, `ClearTransient`) — alteracoes visiveis em `Get()` e no cliente, sem salvar no ProfileStore
- Leitura separada com `GetPersisted()` vs `Get()` (merged)
- Listas ordenadas com `GetOrderedList()` / `GetOrderedListWithPriority()` e `Enum.OrderList.Asc` / `Enum.OrderList.Desc`
- Correcao de runtime em `deepCopyTable` na `2.3.3` (erro `attempt to call a nil value` ao mesclar tabelas)

## Instalacao

No `wally.toml` do jogo:

```toml
[dependencies]
dataservicev2 = "kartzrbx/dataservicev2@2.3.3"
```

Depois rode:

```bash
wally install
```

No projeto Rojo do jogo, garanta que `Packages` seja sincronizado para `ReplicatedStorage.Packages`:

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

Require padrao:

```luau
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
local DataServiceServer = DataService.Server
local DataServiceClient = DataService.Client
local Enum = DataService.Enum
```

### Modulos compartilhados (server + client)

Em modulos em `ReplicatedStorage.Shared`, prefira `DataService.Paths` no servidor:

```luau
local DataService = require(ReplicatedStorage.Packages.dataservicev2)

-- Servidor (apos Server:Init)
local Paths = DataService.Paths :: DataTemplate.Schema

-- Cliente (apos Client:Init)
local Paths = DataService.Client.Paths :: DataTemplate.Schema
```

Na `2.2.2+`, `DataService.Client` existe no servidor como facade segura (com `Paths`), mas metodos de cliente (`Init`, `WaitForData`) so funcionam no client.

## Conceito principal

O DataServiceV2 trabalha com um singleton:

- No servidor, chame `Server:Init(...)` uma vez no boot.
- Depois do `Init`, os paths ficam em `Server.Paths` e `DataService.Paths`.
- Cada jogador tem uma instancia `Data`, obtida com `Server:WaitFor(player)`.
- O cliente chama `Client:Init()` e recebe copia somente leitura dos dados replicados.

Padrao recomendado:

```luau
local data = DataServiceServer:WaitFor(player)
local Paths = DataServiceServer.Paths :: DataTemplate.Schema

data:Set(Paths.Currencies.Coins, 100)
local coins = data:Get(Paths.Currencies.Coins)
```

Importante: os paths ficam no servico (`DataServiceServer.Paths`), nao na instancia `data`.

## Estrutura recomendada do projeto

```text
src/
  shared/
    DataTemplate.luau       -- dados padrao + export type Schema
  server/
    DataBootstrap.server.luau -- Server:Init uma vez
    PlayerData.server.luau    -- PlayerAdded, economia, recompensas
  client/
    DataClient.client.luau    -- Client:Init + sinais globais
    UI/
      Hud.client.luau       -- le dados, escuta GetChangedSignal
```

**Faca**

- Chame `Server:Init` em um unico script de boot no `ServerScriptService`.
- Use `Server:WaitFor(player)` dentro de `PlayerAdded`.
- Obtenha paths de `DataServiceServer.Paths` (tipados com `DataTemplate.Schema`).
- No cliente, chame `Client:Init()` uma vez em `StarterPlayerScripts`.

**Evite**

- Chamar `Init` em varios scripts.
- Guardar paths na instancia `data` (eles ficam no servico).
- Escrever dados do jogador no cliente.

## Template de dados

`src/shared/DataTemplate.luau`:

```luau
local Data = {
	Currencies = {
		Coins = 0,
		Gems = 0,
	},
	Stats = {
		Level = 1,
		XP = 0,
	},
	Inventory = {} :: { string },
	Settings = {
		Music = true,
		SFX = true,
	},
}

export type Schema = typeof(Data)

return Data
```

Tipagem nos consumidores:

```luau
local Paths = DataServiceServer.Paths :: DataTemplate.Schema
```

## Boot no servidor

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTemplate = require(ReplicatedStorage.DataTemplate)
local DataServiceServer = require(ReplicatedStorage.Packages.dataservicev2).Server

DataServiceServer:Init({
	Template = DataTemplate,
	StoreName = "PlayerDataV2",
	KeyPrefix = "Player_",
	UseMock = false,
	StrictPaths = true,
	AutoCreateMissingTables = false,
})
```

| Opcao | Tipo | Padrao | Descricao |
|---|---|---|---|
| `Template` | `table` | obrigatorio | Estrutura inicial de dados do jogador |
| `StoreName` | `string?` | `"PlayerData"` | Nome do DataStore/ProfileStore |
| `UseMock` | `boolean?` | `false` | Usa ProfileStore mock (sem DataStore real). **Nao** e overlay de teste por jogador |
| `KeyPrefix` | `string?` | `"Player_"` | Prefixo da chave por `UserId` |
| `Exclude` | `{ Path }?` | `nil` | Paths que nao replicam ao cliente |
| `StrictPaths` | `boolean?` | `true` | Bloqueia escrita em path invalido |
| `AutoCreateMissingTables` | `boolean?` | `false` | Cria tabelas faltantes automaticamente |

## API do servidor

| Metodo/propriedade | Retorno | Uso |
|---|---|---|
| `:Init(options)` | `Server` | Inicializa o singleton |
| `:WaitFor(player)` | `Data` | Aguarda e retorna os dados do jogador |
| `:Get(player)` | `Data?` | Retorna dados se ja carregaram |
| `:HasData(player)` | `boolean` | Jogador ja tem dados carregados |
| `:GetProfile(player)` | `Profile?` | Profile interno do ProfileStore |
| `:GetBufferStats(player?)` | `table?` | Metricas da replicacao |
| `:Destroy()` | `()` | Limpa conexoes e recursos |
| `.Paths` | `PathTree` | Arvore de paths tipados apos `Init` |

## API do cliente

| Metodo/propriedade | Retorno | Uso |
|---|---|---|
| `:Init()` | `Data` | Inicializa e aguarda snapshot inicial |
| `:WaitForData()` | `Data` | Aguarda dados replicados |
| `:Get()` | `Data?` | Dados se ja recebeu snapshot |
| `:GetBufferStats()` | `table?` | Ultimas metricas do servidor |
| `:Destroy()` | `()` | Limpa conexoes/listeners |
| `.Paths` | `PathTree` | Paths criados a partir do snapshot |

No cliente, `Data` e somente leitura. Escritas devem acontecer no servidor.

## API da instancia Data

| Metodo | Retorno | Servidor | Cliente | Descricao |
|---|---|---:|---:|---|
| `:Get(path?)` | `any` | sim | sim | Le valor merged (persistido + transitório) |
| `:GetPersisted(path?)` | `any` | sim | sim | Le apenas valor salvo no profile |
| `:GetTransient(path?)` | `any?` | sim | sim | Le overlay de teste, se existir |
| `:HasTransient(path?)` | `boolean` | sim | sim | Indica se ha overlay no path |
| `:Set(path, value)` | `()` | sim | nao | Escreve e **persiste** |
| `:SetTransient(path, value)` | `()` | sim | nao | Escreve overlay de teste (**nao persiste**) |
| `:Update(path, fn)` | `any` | sim | nao | Atualiza valor persistido |
| `:UpdateTransient(path, fn)` | `any` | sim | nao | Atualiza overlay de teste |
| `:ClearTransient(path?)` | `()` | sim | nao | Remove overlay (`nil` = limpa tudo) |
| `:ArrayInsert(path, value, index?)` | `()` | sim | nao | Insere em array persistido |
| `:ArrayInsertTransient(path, value, index?)` | `()` | sim | nao | Insere em array via overlay |
| `:ArrayRemove(path, index)` | `any` | sim | nao | Remove de array persistido |
| `:ArrayRemoveTransient(path, index)` | `any` | sim | nao | Remove de array via overlay |
| `:GetOrderedList(path, options)` | `{entry}` | sim | sim | Coleta e ordena itens de uma lista |
| `:GetOrderedListWithPriority(path, key, order?)` | `{entry}` | sim | sim | Atalho para ordenar por campo |
| `:GetChangedSignal(path)` | `Signal` | sim | sim | Mudanca no valor merged do path |
| `:GetPathChangedSignal(path)` | `Signal` | sim | sim | Alias de `GetChangedSignal` |
| `:GetIndexChangedSignal(path)` | `Signal` | sim | sim | Filho direto mudou |
| `:GetArrayInsertedSignal(path)` | `Signal` | sim | sim | Insert em array |
| `:GetArrayRemovedSignal(path)` | `Signal` | sim | sim | Remove de array |
| `:Typed(path)` | `PathToken` | sim | sim | Ajuda para tipagem |
| `:Destroy()` | `()` | sim | sim | Limpa sinais internos |

## Leitura e escrita persistida

```luau
local data = DataServiceServer:WaitFor(player)
local Paths = DataServiceServer.Paths :: DataTemplate.Schema

data:Set(Paths.Currencies.Coins, 100)
data:Update(Paths.Currencies.Coins, function(current)
	return (current or 0) + 50
end)
```

`Get()` sem path retorna a raiz merged:

```luau
local snapshot = data:Get()
print(snapshot.Currencies.Coins)
```

## Dados transitórios (overlay de teste)

Caso de uso: jogador tem **500 moedas reais**, painel de teste adiciona **+500** para exibir **1000**, mas ao sair deve salvar apenas **500**.

```luau
-- progresso real (salva no ProfileStore)
data:Set(Paths.Currencies.Coins, 500)

-- painel de teste (NAO salva)
data:UpdateTransient(Paths.Currencies.Coins, function(current)
	return (current or 0) + 500
end)

print(data:Get(Paths.Currencies.Coins))           -- 1000 (merged)
print(data:GetPersisted(Paths.Currencies.Coins)) -- 500

-- ao sair, overlay e descartado automaticamente
-- profile continua com 500
```

Regras:

- Use `Set` / `Update` para progresso real.
- Use `SetTransient` / `UpdateTransient` apenas em ferramentas de teste/admin.
- Overlay replica para o cliente e dispara `GetChangedSignal`.
- `ClearTransient()` remove o overlay manualmente; ao desconectar, o overlay nao e salvo.

`UseMock` **nao** substitui isso: ele mocka o DataStore inteiro, nao cria overlay por sessao em cima de dados reais.

## Consulta ordenada de listas

Para listas de objetos (ex.: units com `Damage`):

```luau
Units = {
	List = {
		{ Damage = 500 },
		{ Damage = 400 },
		{ Damage = 700 },
		{ Damage = 600 },
	},
}
```

```luau
local ordered = data:GetOrderedListWithPriority(
	Paths.Units.List,
	"Damage",
	Enum.OrderList.Desc
)

for _, entry in ordered do
	print(entry.index, entry.value.Damage, entry.priority)
end
```

Com opcoes:

```luau
local top3 = data:GetOrderedList(Paths.Units.List, {
	key = "Damage",
	order = Enum.OrderList.Desc,
	limit = 3,
})
```

### Valores de `order` (`Enum.OrderList`)

Use o enum exportado pelo pacote em vez de strings soltas:

```luau
local Enum = require(ReplicatedStorage.Packages.dataservicev2).Enum
```

| Enum | Valor interno | Significado | Quando usar |
|---|---|---|---|
| `Enum.OrderList.Desc` | `"desc"` | Decrescente — maior `priority` primeiro | Top N, ranking, melhores units (**padrao**) |
| `Enum.OrderList.Asc` | `"asc"` | Crescente — menor `priority` primeiro | Piores primeiro, fila por menor custo, etc. |

Se `order` for omitido, o padrao e `Enum.OrderList.Desc`.

Strings `"asc"` e `"desc"` ainda funcionam por compatibilidade, mas o uso recomendado e o enum.

Exemplo com os dois:

```luau
-- Maior Damage primeiro (700, 600, 500, 400)
local strongest = data:GetOrderedListWithPriority(Paths.Units.List, "Damage", Enum.OrderList.Desc)

-- Menor Damage primeiro (400, 500, 600, 700)
local weakest = data:GetOrderedListWithPriority(Paths.Units.List, "Damage", Enum.OrderList.Asc)

-- Com limite
local top3 = data:GetOrderedList(Paths.Units.List, {
	key = "Damage",
	order = Enum.OrderList.Desc,
	limit = 3,
})
```

A ordenacao usa o campo indicado em `key` (ex.: `item.Damage`). Valores `nil` em `priority` sao tratados como `0` na comparacao.

Cada entrada retorna:

```luau
{
	index = number,    -- indice original na lista
	value = any,       -- item completo
	priority = any,    -- valor usado na ordenacao (ex.: Damage)
}
```

## Sinais de mudanca

```luau
data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue, oldValue)
	print("Coins:", oldValue, "->", newValue)
end)

data.Changed:Connect(function(action, path, ...)
	print("Acao:", action, "Path:", table.concat(path, "."))
end)
```

Mudancas transient tambem disparam os mesmos sinais.

## Arrays

```luau
Inventory = {} :: { string }
```

```luau
data:ArrayInsert(Paths.Inventory, "Sword")
local removed = data:ArrayRemove(Paths.Inventory, 1)
```

## Paths tipados

```luau
data:Set(Paths.Currencies.Coins, 100)          -- recomendado
data:Set({ "Currencies", "Coins" }, 100)       -- legado
```

Somente `.Paths` existe (o alias `.paths` foi removido na `2.2.x`).

## Dados privados

```luau
DataServiceServer:Init({
	Template = DataTemplate,
	Exclude = { { "Private" } },
})
```

## Leaderstats

```luau
Players.PlayerAdded:Connect(function(player)
	local data = DataServiceServer:WaitFor(player)
	local Paths = DataServiceServer.Paths :: DataTemplate.Schema

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = data:Get(Paths.Currencies.Coins)
	coinsValue.Parent = leaderstats

	data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue)
		coinsValue.Value = newValue
	end)
end)
```

## Cliente exibindo UI

```luau
local data = DataServiceClient:Init()
local Paths = DataServiceClient.Paths :: DataTemplate.Schema

data:GetChangedSignal(Paths.Currencies.Coins):Connect(function()
	print("Coins:", data:Get(Paths.Currencies.Coins))
end)
```

## Estatisticas de replicacao

```luau
local stats = DataServiceServer:GetBufferStats(player)
local clientStats = DataServiceClient:GetBufferStats()
```

## Boas praticas

- Chame `Server:Init(...)` uma unica vez no boot.
- Use `Server:WaitFor(player)` quando o jogador acabou de entrar.
- Em modulos compartilhados, use `DataService.Paths` no servidor apos `Init`.
- Faca escritas persistidas somente com `Set` / `Update`.
- Use `*Transient` somente em paineis de teste/admin.
- Use `Exclude` para dados que nao podem ir ao cliente.
- Mantenha `StrictPaths = true` em producao.

## Troubleshooting

| Problema | Solucao |
|---|---|
| `Paths` nil | `Server:Init(...)` nao foi chamado antes do consumidor |
| `Get(player)` nil | Use `WaitFor(player)` |
| Cliente sem dados | Garanta `Client:Init()` em LocalScript |
| `attempt to index nil with 'Paths'` em utils shared | Use `require(...).Paths` no server apos `Init`, ou atualize para `>=2.2.2` |
| Painel de teste salvou moedas | Voce usou `Set`/`Update` em vez de `*Transient` |
| `UseMock` nao faz overlay | `UseMock` mocka o store inteiro; overlay usa `*Transient` |
| `attempt to call a nil value` em `Data:148` | Atualize para `>=2.3.3` (correcao em `deepCopyTable`) |
| CSS/docs 404 no GitHub Pages | Use URLs com `/KartzData-V2/` (repo renomeado de `KartzDataService`) |
