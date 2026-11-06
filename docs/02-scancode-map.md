# Scancode Map

## Porquê

Foram necessárias duas correcções:

1. **Teclas `<>` e `§ ±` trocadas** — o layout do Boot Camp mapeia `0x29`
   para `§ ±` e `0x56` para `<>`, mas os keycaps deste teclado estão ao
   contrário (`0x29` = `<>`, `0x56` = `§ ±`).
2. **Modificadores** — `Command` esquerdo → `Ctrl` esquerdo e
   `Ctrl` esquerdo → tecla `Windows` esquerda.

## Formato do `Scancode Map`

- Chave: `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout`
- Valor: `Scancode Map` (`REG_BINARY`)
- Estrutura:
  - 8 bytes de cabeçalho a zero;
  - um `DWORD` com o número de entradas **incluindo o terminador**;
  - cada entrada tem 4 bytes: `[novo lo] [novo hi] [antigo lo] [antigo hi]`;
  - teclas *extended* usam o byte alto `0xE0`;
  - terminador: 4 bytes a zero.

## Mapa actual

32 bytes:

```text
00 00 00 00 00 00 00 00 05 00 00 00
56 00 29 00
29 00 56 00
1D 00 5B E0
5B E0 1D 00
00 00 00 00
```

| Bytes | Novo scancode | Antigo scancode | Efeito |
|---|---|---|---|
| `56 00 29 00` | `0x0056` | `0x0029` | Tecla `<>` passa a `§` / `±` |
| `29 00 56 00` | `0x0029` | `0x0056` | Tecla `§ ±` passa a `<` / `>` |
| `1D 00 5B E0` | `0x001D` | `0xE05B` | `Command` esquerdo passa a `Ctrl` esquerdo |
| `5B E0 1D 00` | `0xE05B` | `0x001D` | `Ctrl` esquerdo passa a tecla `Windows` esquerda |

## Notas sobre os scancodes

- `0x29` — tecla do canto superior esquerdo (keycap `<>` neste teclado).
- `0x56` — tecla extra ao lado do Shift esquerdo (keycap `§ ±` neste teclado).
- `0x1D` — `Ctrl` esquerdo.
- `0xE05B` — tecla `Windows` esquerda (no teclado Apple, `Command` esquerdo).
- `0xE01D` — `Ctrl` direito (não alterado).
- `0xE05C` — tecla `Windows` direita (não alterada).

## Aplicar

```powershell
# Executar como administrador
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
- Só remapeia *scancodes*. Teclas HID *consumer* (Eject, volume, multimedia)
  não passam por aqui — ver [`03-eject-key.md`](03-eject-key.md).
