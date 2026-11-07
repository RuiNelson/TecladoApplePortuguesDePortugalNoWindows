# Scancode Map

## Porquê

O mapa depende do layout activo e de como o Windows recebe as teclas:

1. **Posições** — com o layout Apple PT-PT ([`01-layout-apple.md`](01-layout-apple.md)),
   as teclas já estão no sítio certo. Com o layout Português do Windows
   ([`02-layout-pt.md`](02-layout-pt.md)), 5 teclas têm keycaps que estão
   noutras teclas, e o mapa muda-as de sítio.
2. **Teclas ISO** — no Boot Camp, o teclado Apple ISO envia trocadas a tecla do
   canto superior esquerdo (`§ ±`) e a do lado do Shift esquerdo (`< >`). Numa
   VM no macOS chegam na posição normal, porque o macOS já as corrige.
3. **Modificadores** — `Command` esquerdo → `Ctrl` esquerdo,
   `Ctrl` esquerdo → tecla `Windows` esquerda e `Command` direito →
   `Ctrl` direito (o teclado Apple não tem tecla `Ctrl` do lado direito).

O `set-scancode-map.ps1` escolhe sozinho: se o layout Apple estiver instalado
(drivers do Boot Camp), usa o mapa do layout Apple com a troca ISO; senão, o
mapa do layout Português sem a troca. As opções abaixo permitem forçar outra
combinação.

## Formato do `Scancode Map`

- Chave: `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout`
- Valor: `Scancode Map` (`REG_BINARY`)
- Estrutura:
  - 8 bytes de cabeçalho a zero;
  - um `DWORD` com o número de entradas **incluindo o terminador**;
  - cada entrada tem 4 bytes: `[novo lo] [novo hi] [antigo lo] [antigo hi]`;
  - teclas *extended* usam o byte alto `0xE0`;
  - terminador: 4 bytes a zero.

## Boot Camp: layout Apple

36 bytes (5 entradas + terminador). É o mapa confirmado no iMac de teste:

```text
00 00 00 00 00 00 00 00 06 00 00 00
56 00 29 00
29 00 56 00
1D 00 5B E0
5B E0 1D 00
1D E0 5C E0
00 00 00 00
```

| Bytes | Novo | Recebido | Efeito |
|---|---|---|---|
| `56 00 29 00` | `0x0056` | `0x0029` | Tecla `< >` (chega como `0x29`) escreve `<` / `>` |
| `29 00 56 00` | `0x0029` | `0x0056` | Tecla `§ ±` (chega como `0x56`) escreve `§` / `±` |
| `1D 00 5B E0` | `0x001D` | `0xE05B` | `Command` esquerdo passa a `Ctrl` esquerdo |
| `5B E0 1D 00` | `0xE05B` | `0x001D` | `Ctrl` esquerdo passa a tecla `Windows` esquerda |
| `1D E0 5C E0` | `0xE01D` | `0xE05C` | `Command` direito passa a `Ctrl` direito |

## VM: layout Português

48 bytes (8 entradas + terminador):

```text
00 00 00 00 00 00 00 00 09 00 00 00
0D 00 29 00
1A 00 0D 00
28 00 1A 00
2B 00 28 00
29 00 2B 00
1D 00 5B E0
5B E0 1D 00
1D E0 5C E0
00 00 00 00
```

| Bytes | Novo | Recebido | Efeito |
|---|---|---|---|
| `0D 00 29 00` | `0x000D` | `0x0029` | Canto superior esquerdo (`§ ±`) escreve `«` / `»` |
| `1A 00 0D 00` | `0x001A` | `0x000D` | Tecla `+ *` escreve `+` / `*` |
| `28 00 1A 00` | `0x0028` | `0x001A` | Tecla `º ª` escreve `º` / `ª` |
| `2B 00 28 00` | `0x002B` | `0x0028` | Tecla `~ ^` escreve `~` / `^` (mortas) |
| `29 00 2B 00` | `0x0029` | `0x002B` | Tecla `\ \|` escreve `\` / `\|` |
| `1D 00 5B E0` | `0x001D` | `0xE05B` | `Command` esquerdo passa a `Ctrl` esquerdo |
| `5B E0 1D 00` | `0xE05B` | `0x001D` | `Ctrl` esquerdo passa a tecla `Windows` esquerda |
| `1D E0 5C E0` | `0xE01D` | `0xE05C` | `Command` direito passa a `Ctrl` direito |

As 5 primeiras entradas formam um único ciclo: cada tecla do layout Português
continua acessível, só numa posição diferente. A tecla `< >` (`0x56`) já
coincide e não precisa de entrada.

## Opções do `set-scancode-map.ps1`

### `-Layout Auto | Apple | Portuguese`

Escolhe o mapa. Por omissão (`Auto`) é `Apple` se o layout `a0000416` estiver
instalado e `Portuguese` caso contrário. Tem de ser o mesmo layout que o
`enable-layout.ps1` activou.

### `-SwapIsoKeys`

Compensa a troca das teclas ISO. Por omissão liga-se quando há drivers do Boot
Camp (o layout Apple está instalado) e desliga-se nas VMs; `-SwapIsoKeys`
liga-a e `-SwapIsoKeys:$false` desliga-a à força. Sinal de que está errada:
depois de reiniciar, a tecla `< >` não escreve `<`.

Por exemplo, com o layout Português no Boot Camp (`-Layout Portuguese`, troca
ligada), o mapa fica com 9 entradas (52 bytes):

```text
00 00 00 00 00 00 00 00 0A 00 00 00
0D 00 56 00
56 00 29 00
1A 00 0D 00
28 00 1A 00
2B 00 28 00
29 00 2B 00
1D 00 5B E0
5B E0 1D 00
1D E0 5C E0
00 00 00 00
```

### `-KeepModifiers`

Não grava as 3 entradas dos modificadores. Para VMs que já traduzem o
`Command` para `Ctrl` (por exemplo, com perfis de atalhos do Parallels ou do
VMware Fusion): sem esta opção, o `Ctrl` que a VM envia passaria a tecla
`Windows`.

## Notas sobre os scancodes

- `0x29` — tecla do canto superior esquerdo (keycap `§ ±` neste teclado).
- `0x56` — tecla extra do ISO, ao lado do Shift esquerdo (keycap `< >`).
- No Boot Camp, estas duas chegam trocadas (ver `-SwapIsoKeys`).
- `0x0D`, `0x1A`, `0x28`, `0x2B` — teclas à direita de `' ?`, do `P`, do `Ç` e
  à esquerda do Enter.
- `0x1D` — `Ctrl` esquerdo.
- `0xE05B` — tecla `Windows` esquerda (no teclado Apple, `Command` esquerdo).
- `0xE05C` — tecla `Windows` direita (no teclado Apple, `Command` direito).
- `0xE01D` — `Ctrl` direito. É o destino do `Command` direito, porque o teclado
  Apple não tem tecla `Ctrl` desse lado.

> Os scancodes podem ser confirmados com
> [`../tools/diagnostics/key-spy-gui.ps1`](../tools/diagnostics/key-spy-gui.ps1)
> **antes** de aplicar o mapa (o hook já vê os scancodes remapeados). Por
> exemplo, o `Command` direito deve aparecer como `scan=0x5C ext=SIM`.

## Aplicar

```powershell
# Executar como administrador; opções: -Layout, -SwapIsoKeys, -KeepModifiers
powershell -ExecutionPolicy Bypass -File .\scripts\set-scancode-map.ps1
```

Reiniciar o Windows.

## Reverter

```powershell
# Executar como administrador
powershell -ExecutionPolicy Bypass -File .\scripts\undo-scancode-map.ps1
```

Reiniciar o Windows.

## Efeitos secundários

- O mapa é **global**: afecta todos os teclados e o ecrã de início de sessão.
  Com o layout Português, num teclado de PC português as 5 teclas mudadas
  ficam erradas.
- Só funciona como esperado com o layout para que foi gravado.
- Só remapeia *scancodes*. Teclas HID *consumer* (Eject, volume, multimedia)
  não passam por aqui — ver [`04-eject-key.md`](04-eject-key.md).
