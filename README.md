# DataServiceV2

High-performance Roblox data service with automatic server/client replication, embedded ProfileStore persistence, typed path tokens, QuickNet transport, and Janitor-based connection lifecycle management.

**Documentation:** [kartzrbx.github.io/KartzData-V2](https://kartzrbx.github.io/KartzData-V2/docs/intro)

## Local testing

```powershell
.\scripts\setup-test-env.ps1
cd Test
rojo serve
```

`Test/` is gitignored. The template lives in `test-template/`.

## Installation

`wally.toml`:

```toml
[dependencies]
DataServiceV2 = "kartzrbx/dataservicev2@2.0.6"
```

```bash
wally install
```

### Setup Wally + Rojo

O DataServiceV2 depende de pacotes instalados pelo Wally (`quicknet`, `janitor`, `signal`). Eles precisam existir em `ReplicatedStorage.Packages` no jogo.

No `default.project.json` do seu jogo:

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

Fluxo:

1. Adicione `DataServiceV2` no `wally.toml` do jogo
2. Rode `wally install` (gera a pasta `Packages/` com `_Index/`)
3. Sincronize com Rojo
4. Require via `ReplicatedStorage.Packages.dataservicev2`

Se QuickNet ou Janitor não carregarem, confirme que `Packages/_Index/` contém as pastas `breadboardengineer1234_quicknet@*` e `1foreverhd_janitor@*`.

## Uso

### Exemplo completo (Server + Client)

Use este exemplo como base de produção.

**ServerScriptService/DataBootstrap.server.lua**

```lua
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const DataService = require(ReplicatedStorage.Packages.DataServiceV2).Server

const TEMPLATE = {
    Currencies = {
        Coins = 0,
        Gems = 0,
    },
    Inventory = {},
    Stats = {
        Level = 1,
        XP = 0,
    },
}

DataService:Init({
    Template = TEMPLATE,
    StoreName = "PlayerDataV2",
    StrictPaths = true,
    AutoCreateMissingTables = false,
})

Players.PlayerAdded:Connect(function(player)
    const data = DataService:WaitFor(player)
    if not data then
        return
    end

    -- Path token (recomendado)
    data:Update(data.Currencies.Coins, function(current)
        return (current or 0) + 100
    end)

    data:Update(data.Stats.XP, function(current)
        return (current or 0) + 25
    end)

    data:GetChangedSignal(data.Currencies.Coins):Connect(function(newValue, oldValue)
        print(("[Server] %s Coins: %s -> %s"):format(player.Name, tostring(oldValue), tostring(newValue)))
    end)

    -- Compatibilidade legada (continua suportado)
    data:Set({ "Currencies", "Gems" }, 10)
end)

Players.PlayerRemoving:Connect(function(player)
    const stats = DataService:GetBufferStats(player)
    if stats then
        print(("[Server] Buffer %s | bytes=%d messages=%d"):format(player.Name, stats.Bytes, stats.Messages))
    end
end)
```

**StarterPlayerScripts/DataClient.client.lua**

```lua
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const DataService = require(ReplicatedStorage.Packages.DataServiceV2).Client

const data = DataService:Init()

print("[Client] Coins initial:", data:Get(data.Currencies.Coins))

data:GetChangedSignal(data.Currencies.Coins):Connect(function(newValue, oldValue)
    print(("[Client] Coins changed: %s -> %s"):format(tostring(oldValue), tostring(newValue)))
end)

data:GetChangedSignal(data.Stats.XP):Connect(function(newValue)
    print("[Client] XP changed:", newValue)
end)

task.spawn(function()
    while task.wait(10) do
        const buffer = DataService:GetBufferStats()
        if buffer then
            print(("[Client] Buffer | bytes=%d messages=%d utilization=%.2f"):format(
                buffer.Bytes or 0,
                buffer.Messages or 0,
                buffer.LastUtilization or 0
            ))
        end
    end
end)
```

## Why DataServiceV2 is Powerful

- Built for scale: QuickNet-based replication reduces CPU and bandwidth overhead compared to plain RemoteEvent flows.
- Safer writes: strict path validation prevents silent corruption caused by invalid dynamic paths.
- Developer speed: chainable path tokens (`data.Currencies.Coins`) improve readability and reduce human error.
- Full compatibility: legacy array paths keep working, so migration can be incremental.
- Operational visibility: built-in buffer utilization stats help inspect replication pressure in real time.
- Lifecycle safety: Janitor cleanup prevents connection leaks in both server and client runtime.

### Servidor

```lua
local DataService = require(game.ReplicatedStorage.Packages.DataServiceV2).Server

local TEMPLATE = {
    Coins = 0,
    Inventory = {},
}

DataService:Init({
    Template = TEMPLATE,
    StoreName = "PlayerData", -- opcional, default "PlayerData"
    UseMock = false,           -- opcional, true em Studio sem API services
    Exclude = { { "Secret" } },-- caminhos que não replicam ao cliente
    StrictPaths = true,        -- opcional, default true (evita paths inválidos)
    AutoCreateMissingTables = false, -- opcional, default false (modo legado = true)
})

game.Players.PlayerAdded:Connect(function(player)
    local data = DataService:WaitFor(player)
    -- Novo (recomendado): path token com autocomplete
    data:Set(data.Coins, 100)

    -- Compatibilidade legada (continua funcionando)
    data:Set({ "Coins" }, 100)
end)
```

### Cliente

```lua
local DataService = require(game.ReplicatedStorage.Packages.DataServiceV2).Client

local data = DataService:Init() -- yields até receber snapshot inicial
print(data:Get(data.Coins))

data:GetChangedSignal(data.Coins):Connect(function(new, old)
    print("Coins:", old, "->", new)
end)
```

## API

### Server

- `Init(options)` — `{ Template, StoreName?, UseMock?, KeyPrefix?, Exclude?, StrictPaths?, AutoCreateMissingTables? }`
- `WaitFor(player)` → Data
- `Get(player)` → Data?
- `HasData(player)` → boolean
- `GetProfile(player)` → ProfileStore profile
- `GetBufferStats(player?)` → métricas de buffer/uso de rede da replicação
- `Destroy()` → limpa conexões e listeners do serviço
- `Paths` → token raiz de caminhos (disponível após `Init`)

### Client

- `Init()` → Data (yields)
- `WaitForData()` → Data
- `Get()` → Data?
- `GetBufferStats()` → últimas métricas de buffer enviadas pelo servidor
- `Destroy()` → limpa conexões/listeners do cliente

### Data

- `Get(path?)` — lê (caminho vazio = root), aceita token ou array legado
- `Typed<T>(path)` — força tipo do caminho para inferência forte em sinais e Get/Set/Update
- `Set(path, value)` — server-only, aceita token ou array legado
- `Update(path, fn)` — server-only, aceita token ou array legado
- `ArrayInsert(path, value, index?)` — server-only, aceita token ou array legado
- `ArrayRemove(path, index)` — server-only, aceita token ou array legado
- `GetChangedSignal(path)` → Signal(new, old), aceita token ou array legado
- `GetIndexChangedSignal(path)` → Signal(key, new, old), aceita token ou array legado
- `GetArrayInsertedSignal(path)` → Signal(index, value), aceita token ou array legado
- `GetArrayRemovedSignal(path)` → Signal(index, removed), aceita token ou array legado

### Caminhos tipados / seguros (novo)

Agora você pode usar acesso encadeado para montar caminhos sem tabelas manuais:

```lua
data:Set(data.Currencies.Coins, 100)
local coins = data:Get(data.Currencies.Coins)

data:GetChangedSignal(data.Currencies.Coins):Connect(function(new, old)
    print(old, new)
end)

local coinsPath = data:Typed<number>(data.Currencies.Coins)
data:GetPathChangedSignal(coinsPath):Connect(function(newValue, oldValue)
    -- newValue e oldValue inferidos como number
    print(newValue, oldValue)
end)
```

Isso reduz erros de digitação em paths (`{"Currencies","Coins"}`), mantendo compatibilidade com o formato antigo.

### Compatibilidade e modo legado

- Compatível com chamadas antigas via array: `data:Set({ "Currencies", "Coins" }, 100)`
- `StrictPaths = true` (default): bloqueia escrita em caminho inválido
- `AutoCreateMissingTables = false` (default): não cria estruturas faltantes automaticamente
- Para comportamento antigo (mais permissivo), use:

```lua
DataService:Init({
    Template = TEMPLATE,
    StrictPaths = false,
    AutoCreateMissingTables = true,
})
```

## Dependências

- `sleitnick/signal@2.0.3` (instalado automaticamente pelo Wally)
- `breadboardengineer1234/quicknet@0.3.0` (replicação otimizada)
- `1foreverhd/janitor@1.18.15` (gerenciamento de conexões/recursos)
- ProfileStore — embutido, sem necessidade de instalação separada
