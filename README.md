# Teclado Apple Português de Portugal no Windows 11

O layout foi testado num iMac 2017 com teclado Apple Magic Keyboard 2, mas deve funcionar noutros sistemas, incluindo portáteis, e incluindo computadores não Apple que estejam a usar um teclado da Apple.

- layout Apple PT-PT correcto (`a0000416`) em vez do layout PT standard;
- correcção das teclas `<>` e `§ ±`, que neste teclado estão invertidas em relação ao layout do Boot Camp;
- troca do `Command` esquerdo por `Ctrl` e do `Ctrl` esquerdo pela tecla `Windows`;
- troca do `Command` direito (o teclado Apple não tem `Ctrl` desse lado) por `Ctrl` direito;
- investigação da tecla **Eject** (consumida pelo filtro `KeyMagic2` do Boot Camp).

> **Estado:** a funcionar e confirmado após reinício (6 de Novembro de 2026).

---

## Resultado final

| Tecla física | Comportamento no Windows |
|---|---|
| `<>` (canto superior esquerdo) | `§` / `±` |
| `§ ±` (ao lado do Shift esquerdo) | `<` / `>` |
| `Command` esquerdo | `Ctrl` esquerdo |
| `Ctrl` esquerdo | tecla `Windows` (menu Iniciar) |
| `Command` direito | `Ctrl` direito |
| `Ctrl` direito (noutros teclados) | `Ctrl` direito (inalterado) |
| `Option` direito | `AltGr` |
| `AltGr + 2` | `@` |
| `AltGr + 3` | `€` |
| `AltGr + Shift + 8` / `9` | `{` / `}` |
| `Fn` + tecla | F1–F12, Delete, Home, End |
| Print Screen | não existe; usar `Win + Shift + S` |

---

## O que foi feito

1. **Layout Apple em vez do layout PT standard**
   O Windows só tinha `English (US)` activo. Foi instalado/seleccionado o layout `a0000416` — *Portuguese (Portugal) – Portuguese (Apple)* — e definido como predefinido.

2. **Correcção `<>` / `§ ±`**
   O Boot Camp mapeia o scancode `0x29` para `§ ±` e o `0x56` para `<>`. Os keycaps deste teclado estão ao contrário: `0x29` é `<>` e `0x56` é `§ ±`. Os dois scancodes foram trocados através do `Scancode Map`.

3. **Command / Ctrl**
   O `Command` esquerdo (`0xE05B`) passou a `Ctrl` esquerdo (`0x001D`); o `Ctrl` esquerdo passou a tecla `Windows` (`0xE05B`). No lado direito, como o teclado Apple não tem `Ctrl`, o `Command` direito (`0xE05C`) passou a `Ctrl` direito (`0xE01D`).

4. **Eject**
   Investigada. O Windows não recebe nada porque o filtro de teclado da Apple (`KeyMagic2`) intercepta as teclas especiais antes de elas chegarem às aplicações. Não foi alterado nada. Detalhes em [`docs/03-eject-key.md`](docs/03-eject-key.md).

---

## Aplicar

Requer **administrador** para o mapa de scancodes e **reinício** para ele entrar em vigor.

```powershell
# 1) Layout Apple PT-PT (por utilizador; não precisa de admin)
powershell -ExecutionPolicy Bypass -File .\scripts\enable-apple-layout.ps1

# 2) Mapa de scancodes (executar como administrador)
powershell -ExecutionPolicy Bypass -File .\scripts\set-scancode-map.ps1

# 3) Reiniciar o Windows
```

O script `set-scancode-map.ps1` tem `#requires -RunAsAdministrator`. Se não estiveres numa consola elevada, abre o PowerShell como administrador ou usa:

```powershell
Start-Process powershell.exe -Verb RunAs -WorkingDirectory (Get-Location) -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','.\scripts\set-scancode-map.ps1'
```

---

## Reverter

```powershell
# Remover o mapa de scancodes e reiniciar
powershell -ExecutionPolicy Bypass -File .\scripts\undo-scancode-map.ps1
```

Para voltar ao layout original, ver a secção **Reverter** em [`docs/01-layout-apple-pt-pt.md`](docs/01-layout-apple-pt-pt.md).

---

## Avisos

- O `Scancode Map` é **global**: aplica-se a todos os teclados ligados ao PC (incluindo o Logitech) e ao ecrã de início de sessão.
- As alterações ao `Scancode Map` só entram em vigor **depois de reiniciar**.
- O `Scancode Map` só remapeia *scancodes*. Não vê teclas HID do tipo *consumer* (Eject, volume, multimedia); para essas é preciso software/driver.
- Algumas aplicações mantêm o layout antigo até serem reiniciadas; `Win + Space` ajuda a alternar.
- Se usares outro teclado com frequência, tem em conta que o `Scancode Map` também lhe troca as teclas correspondentes (incluindo a tecla `Windows` direita, que passa a `Ctrl` direito).

---

## Ficheiros

| Caminho | Descrição |
|---|---|
| [`docs/01-layout-apple-pt-pt.md`](docs/01-layout-apple-pt-pt.md) | Como o layout Apple foi seleccionado, valores de registo e como reverter |
| [`docs/02-scancode-map.md`](docs/02-scancode-map.md) | Formato do `Scancode Map`, bytes usados, tabela de trocas e efeitos |
| [`docs/03-eject-key.md`](docs/03-eject-key.md) | Investigação da tecla Eject e do filtro `KeyMagic2` |
| [`scripts/enable-apple-layout.ps1`](scripts/enable-apple-layout.ps1) | Activa o layout Apple PT-PT e define-o como predefinido |
| [`scripts/set-scancode-map.ps1`](scripts/set-scancode-map.ps1) | Grava o `Scancode Map` (5 trocas) |
| [`scripts/undo-scancode-map.ps1`](scripts/undo-scancode-map.ps1) | Remove o `Scancode Map` |
| [`tools/diagnostics/`](tools/diagnostics/) | Ferramentas de diagnóstico (key spy, dump do layout, KLID) |

---

## Contexto testado

- **Máquina:** Apple iMac18,3 (Boot Camp), Windows 11 Pro `10.0.26300`.
- **Teclado:** Apple Magic Keyboard PT-PT, ligado por Bluetooth, `VID&0001004C_PID&0267`.
- **Layout Apple:** KLID `a0000416`, implementado por `C:\Windows\System32\PortuguA.dll` (MSKLC 1.4, criado pela Apple e assinado pela Microsoft WHCP).
- **Teclado secundário:** Logitech (o `Scancode Map` também o afecta).

---

## Licença

Apache-2.0 — ver [`LICENSE`](LICENSE).
