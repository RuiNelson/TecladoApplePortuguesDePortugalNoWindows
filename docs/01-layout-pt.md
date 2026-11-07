# Layout Português do Windows (`00000816`)

## Porquê este layout

- O layout Apple PT-PT do Boot Camp (`a0000416`, `PortuguA.dll`) não vem com o
  Windows: só é instalado pelos drivers de teclado da Apple do Boot Camp, que são
  x64. Numa VM, ou em Windows ARM64, não existe.
- O layout **Português** (`00000816`, `kbdpo.dll`) vem com qualquer Windows.
  Comparado tecla a tecla com os keycaps Apple PT-PT, só 6 teclas não coincidem
  em Normal/Shift, e essas mudam-se de sítio com o `Scancode Map`
  ([`02-scancode-map.md`](02-scancode-map.md)). Não é preciso instalar nada.

## Como foi feita a comparação

- **Apple:** layout Portuguese do próprio macOS (`com.apple.keylayout.Portuguese`),
  exportado com [`../tools/macos/dump-mac-layout.swift`](../tools/macos/dump-mac-layout.swift)
  para [`data/mac-portuguese.json`](data/mac-portuguese.json): teclado ISO, estados
  normal, Shift, Option, Shift+Option e Caps Lock, e teclas mortas com as
  respectivas composições.
- **Windows:** tabelas do `kbdpo.dll` 10.0.25393.1, publicadas em
  [kbdlayout.info](https://kbdlayout.info/kbdpo/) (ficheiro KLC).
- **Posições:** os códigos de tecla do macOS correspondem aos scancodes PC pela
  posição física. As duas teclas ISO são `0x32` → `0x29` (canto superior
  esquerdo, keycap `<>`) e `0x0A` → `0x56` (ao lado do Shift esquerdo, keycap
  `§ ±`), o que bate com o que o Windows recebeu no Boot Camp.

## Teclas que mudam de sítio

| Posição física | Scancode | Keycap Apple | Tecla do layout PT usada |
|---|---|---|---|
| canto superior esquerdo | `0x29` | `<` `>` | `0x56` (`<` `>`) |
| ao lado do Shift esquerdo | `0x56` | `§` `±` | `0x0D` (`«` `»`) |
| à direita de `' ?` | `0x0D` | `+` `*` | `0x1A` (`+` `*`, `AltGr`: `¨` morta) |
| à direita do `P` | `0x1A` | `º` `ª` | `0x28` (`º` `ª`) |
| à direita do `Ç` | `0x28` | `~` `^` (mortas) | `0x2B` (`~` `^`, mortas) |
| à esquerda do Enter | `0x2B` | `\` `\|` | `0x29` (`\` `\|`) |

- O layout Português não tem nenhuma tecla com `§ ±`. Essa posição fica com a
  única tecla PT que sobra, `« »`; o `§` está em `AltGr + 4` e o `±` não existe.
- Todas as outras teclas já coincidem em Normal e Shift: letras, números,
  `' ?`, `` ´ ` `` (mortas), `ç Ç`, `, ;`, `. :`, `- _` e espaço.
- As teclas mortas (`´`, `` ` ``, `~`, `^` e `¨`) compõem as vogais acentuadas,
  `ã`, `õ` e `ñ` como no macOS.

As diferenças com `AltGr` (Option no macOS) estão na tabela **Símbolos com
`AltGr`** do [`README`](../README.md).

## O que o script faz

[`../scripts/enable-pt-layout.ps1`](../scripts/enable-pt-layout.ps1):

1. guarda um backup da lista de idiomas em `%TEMP%\opencode\winlang-backup.json`
   (só se ainda não existir, para não perder o original);
2. remove a substituição `HKCU\Keyboard Layout\Substitutes\00000816 = a0000416`,
   se existir (deixada pela versão anterior deste repositório, que usava o
   layout Apple do Boot Camp);
3. deixa `pt-PT` só com o tip `0816:00000816`, tira o layout Apple
   (`a0000416`) de todos os idiomas e confirma que o Windows aceitou a lista;
4. define `0816:00000816` como método de entrada predefinido;
5. força a janela em primeiro plano a mudar para o layout Português através de
   `WM_INPUTLANGCHANGEREQUEST`.

## Configuração final (registo)

```text
HKCU\Control Panel\International\User Profile
  InputMethodOverride = 0816:00000816

HKCU\Keyboard Layout\Substitutes
  (sem entrada 00000816)
```

## Verificação

- [`../tools/diagnostics/probe-klid.ps1`](../tools/diagnostics/probe-klid.ps1) —
  mostra o KLID activo (deve ser `00000816`) e a lista de idiomas.
- Depois de aplicar o `Scancode Map` e reiniciar, no Notepad: o canto superior
  esquerdo escreve `<`, a tecla `+ *` escreve `+` e a tecla `~ ^` seguida de `a`
  escreve `ã`. Se o canto superior esquerdo escrever `«`, ver `-SwapIsoKeys` em
  [`02-scancode-map.md`](02-scancode-map.md).

## Reverter

1. Repor o método de entrada original (`0409:00000409`) como predefinido. Se o
   `en-US` já não estiver na lista, é preciso voltar a adicioná-lo:

   ```powershell
   $list = Get-WinUserLanguageList
   if (-not ($list | Where-Object { $_.LanguageTag -eq 'en-US' })) { $list.Add('en-US') }
   Set-WinUserLanguageList -LanguageList $list -Force
   Set-WinDefaultInputMethodOverride -InputTip '0409:00000409'
   ```

2. Opcionalmente, remover o idioma `pt-PT` da lista:

   ```powershell
   $list = Get-WinUserLanguageList
   $list = $list | Where-Object { $_.LanguageTag -ne 'pt-PT' }
   Set-WinUserLanguageList -LanguageList $list -Force
   ```

3. Reiniciar sessão/aplicações.

A lista original de idiomas está no backup `%TEMP%\opencode\winlang-backup.json`
(no iMac de teste continha apenas `en-US` com `0409:00000409`).
