# Migracao Completa: Paths Tipados, Seguranca e Compatibilidade

Este documento explica a migracao do DataService para o novo modelo de caminhos seguros/tipados, mantendo compatibilidade com chamadas legadas.

## Objetivos da mudanca

- Reduzir quebras causadas por paths manuais em tabela, como `{"Currencies", "Coins"}`.
- Melhorar seguranca de acesso a dados com validacao de caminho na escrita.
- Adotar `const` para valores imutaveis no runtime.
- Tornar o core mais deterministico usando `rawget`/`rawset` em pontos criticos.
- Otimizar replicacao com QuickNet e melhorar ciclo de vida de conexoes com Janitor.
- Preservar compatibilidade total com a API antiga durante o periodo de transicao.

## O que foi implementado

## 1) PathToken (novo formato recomendado)

Agora o `Data` exposto pelo servidor/cliente permite caminhos encadeados:

```lua
data:Set(data.Currencies.Coins, 100)
local coins = data:Get(data.Currencies.Coins)
```

Esses caminhos sao `PathToken` internos e podem ser usados em:

- `Get`
- `Set`
- `Update`
- `ArrayInsert`
- `ArrayRemove`
- `GetChangedSignal`
- `GetIndexChangedSignal`
- `GetArrayInsertedSignal`
- `GetArrayRemovedSignal`

## 2) Compatibilidade legada total

Todas as APIs acima continuam aceitando o formato antigo:

```lua
data:Set({ "Currencies", "Coins" }, 100)
```

Ou seja, migracao pode ser gradual, sem reescrever tudo de uma vez.

## 3) Escrita segura por padrao

No servidor, `Set` agora trabalha com validacao de caminho para evitar corrupcao silenciosa.

Defaults novos:

- `StrictPaths = true`
- `AutoCreateMissingTables = false`

Com essa combinacao, caminhos invalidos geram erro explicito em vez de criar estrutura inesperada.

## 4) Modo legado (comportamento antigo)

Se voce precisa manter o comportamento permissivo temporariamente:

```lua
DataService:Init({
    Template = TEMPLATE,
    StrictPaths = false,
    AutoCreateMissingTables = true,
})
```

Esse modo reproduz a logica antiga de criar tabelas faltantes na escrita.

## 5) Constantes imutaveis (`const`)

Constantes criticas foram convertidas para `const` para reforcar intencao de imutabilidade e reduzir risco de mutacao acidental.

## 6) Uso de `rawget`/`rawset`

Foi aplicado em pontos sensiveis de leitura/escrita para evitar efeitos de metamethod e manter comportamento consistente no core de dados.

## 7) Replicacao QuickNet + Buffer Stats

A camada de replicacao foi atualizada para usar `quicknet@0.3.0`, com eventos dedicados para:

- dados de replicacao;
- handshake de prontidao;
- estatisticas de buffer por player.

No servidor, `GetBufferStats(player?)` retorna uso acumulado por jogador/global.  
No cliente, `GetBufferStats()` retorna a ultima leitura sincronizada do servidor.

## 8) Janitor para cleanup extremo de conexoes

`janitor@1.18.15` foi integrado na camada de rede e no bootstrap server/client para garantir cleanup consistente de:

- conexoes de eventos;
- sinais internos;
- listeners de replicacao por jogador.

## Mapa de migracao (antes e depois)

### Antes (legado)

```lua
data:Set({ "Currencies", "Coins" }, 100)
local coins = data:Get({ "Currencies", "Coins" })
data:GetChangedSignal({ "Currencies", "Coins" }):Connect(function(new, old)
    -- ...
end)
```

### Depois (recomendado)

```lua
data:Set(data.Currencies.Coins, 100)
local coins = data:Get(data.Currencies.Coins)
data:GetChangedSignal(data.Currencies.Coins):Connect(function(new, old)
    -- ...
end)
```

## Plano recomendado de rollout

## Fase 1 (imediata)

- Publicar a versao com dupla compatibilidade (token + array).
- Manter o codigo existente funcionando sem alteracoes obrigatorias.

## Fase 2 (gradual)

- Migrar scripts para o formato novo `data.<campo>.<subcampo>`.
- Priorizar paths mais usados e sensiveis (moedas, inventario, progressao).

## Fase 3 (hardening)

- Habilitar/validar `StrictPaths = true` em todos os ambientes.
- Usar `AutoCreateMissingTables = false` por padrao.
- Deixar modo legado apenas em excecoes controladas.

## Checklist de verificacao

- Leitura e escrita funcionam com token e com array.
- Sinais de mudanca funcionam com token e com array.
- Escrita em path invalido gera erro claro em modo estrito.
- Replicacao cliente/servidor permanece inalterada.
- Fluxo de load/save de perfil permanece inalterado.

## FAQ rapido

### "Preciso migrar tudo agora?"

Nao. A compatibilidade legada foi mantida para migracao incremental.

### "Isso quebra o cliente?"

Nao. O cliente continua recebendo snapshot e atualizacoes normalmente; apenas ganhou suporte ao novo formato de caminho.

### "Como evito quebra por typo de path?"

Use o formato novo `data.Currencies.Coins` e mantenha `StrictPaths = true`.

