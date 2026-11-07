# Teclado Apple Português de Portugal no Windows

Configura o Windows para que um teclado Apple PT-PT (por exemplo, o Magic Keyboard) escreva o que está gravado nas teclas. Os scripts escolhem sozinhos entre dois modos:

- **Boot Camp** (com os drivers de teclado da Apple): usa o layout **Apple PT-PT** (`a0000416`), igual ao macOS, incluindo os símbolos com `Option` (`⌥⇧8` / `⌥⇧9` = `{` / `}`, `⌥3` = `€`, …).
- **VM ou Windows sem os drivers do Boot Camp** (Parallels, VMware Fusion, UTM…, x64 e ARM64): usa o layout **Português** que já vem com o Windows, sem instalar drivers nem DLLs. Alguns símbolos com `AltGr` ficam noutras teclas (ver abaixo).

Em ambos os modos, um `Scancode Map` no registo:

- troca o `Command` esquerdo por `Ctrl`, o `Ctrl` esquerdo pela tecla `Windows` e o `Command` direito por `Ctrl` direito;
- no Boot Camp, destroca as teclas `§ ±` e `< >`, que o teclado Apple envia trocadas;
- com o layout Português, muda 5 teclas de lugar para os caracteres coincidirem com os keycaps.

Inclui também a investigação da tecla **Eject** (consumida pelo filtro `KeyMagic2` do Boot Camp).

> **Estado:**
> - **Boot Camp:** o layout e os bytes do `Scancode Map` são os da configuração confirmada num iMac a 6 de Novembro de 2026. Os scripts foram reescritos desde então e ainda não foram corridos no Boot Camp.
> - **VM:** em teste.

---

## Resultado

| Tecla física (keycap Apple) | Boot Camp (layout Apple) | VM (layout Português) |
|---|---|---|
| Letras, números e as outras teclas de símbolos | iguais ao keycap | iguais ao keycap |
| `§ ±` (canto superior esquerdo) | `§` / `±` | `«` / `»` (o layout Português não tem `§ ±` numa tecla) |
| `Command` esquerdo | `Ctrl` esquerdo | `Ctrl` esquerdo |
| `Ctrl` esquerdo | tecla `Windows` (menu Iniciar) | tecla `Windows` (menu Iniciar) |
| `Command` direito | `Ctrl` direito | `Ctrl` direito |
| `Option` direito | `AltGr` | `AltGr` |
| Símbolos com `Option` | como no macOS, com `AltGr` (`AltGr + 2` = `@`, `AltGr + 3` = `€`, `AltGr + Shift + 8 / 9` = `{` / `}`) | ver a tabela abaixo |
| Print Screen | não existe; usar `Win + Shift + S` | não existe; usar `Win + Shift + S` |

O `AltGr` também se obtém com `Command` + `Option` esquerdo (que ficam `Ctrl` + `Alt`). O `Option` esquerdo sozinho é `Alt`.

### Símbolos com `AltGr` numa VM (layout Português)

| Símbolo | macOS (teclado Apple) | Windows (layout Português) |
|---|---|---|
| `@` | `⌥ 2` | `AltGr + 2` (igual) |
| `[` `]` | `⌥ 8` / `⌥ 9` | `AltGr + 8` / `AltGr + 9` (igual) |
| `{` `}` | `⇧ ⌥ 8` / `⇧ ⌥ 9` | `AltGr + 7` / `AltGr + 0` |
| `€` | `⌥ 3` | `AltGr + E` ou `AltGr + 5` |
| `£` | `⌥ 4` | `AltGr + 3` |
| `§` | tecla `§ ±` | `AltGr + 4` |
| `¨` (morta) | `⌥ ´` | `AltGr` + tecla `+ *` |
| `«` `»` | `⌥ X` / `⇧ ⌥ X` | tecla `§ ±` |
| `±`, `œ`, `æ`, `©`, `®`, `™`, `…`, etc. | `⌥` + tecla | não existem no layout Português |

O ponto do teclado numérico escreve `.` (no macOS escreve `,`).

---

## Como funciona

- O layout Apple PT-PT (`a0000416`, `PortuguA.dll`) só existe com os drivers do Boot Camp, que são x64. Quando está instalado, os scripts usam-no. Detalhes em [`docs/01-layout-apple.md`](docs/01-layout-apple.md).
- Sem ele, usam o layout Português do Windows (`00000816`, `kbdpo.dll`), que só difere dos keycaps Apple, em Normal e Shift, em 5 teclas. A comparação foi feita com o layout Portuguese do próprio macOS, exportado com [`tools/macos/dump-mac-layout.swift`](tools/macos/dump-mac-layout.swift) para [`docs/data/mac-portuguese.json`](docs/data/mac-portuguese.json). Detalhes em [`docs/02-layout-pt.md`](docs/02-layout-pt.md).
- O `Scancode Map` de cada modo está em [`docs/03-scancode-map.md`](docs/03-scancode-map.md).

---

## Aplicar

Requer **administrador** para o mapa de scancodes e **reinício** para ele entrar em vigor. Os comandos correm-se a partir da pasta do repositório (a que tem o `README.md`).

```powershell
# 1) Layout: Apple no Boot Camp, Português nas VMs (por utilizador; não precisa de admin)
powershell -ExecutionPolicy Bypass -File .\scripts\enable-layout.ps1

# 2) Mapa de scancodes (executar como administrador)
powershell -ExecutionPolicy Bypass -File .\scripts\set-scancode-map.ps1

# 3) Reiniciar o Windows
```

Os dois scripts detectam o modo da mesma forma. Para o forçar, passa `-Layout Apple` ou `-Layout Portuguese` aos dois.

O script `set-scancode-map.ps1` tem `#requires -RunAsAdministrator`. Se não estiveres numa consola elevada, abre o PowerShell como administrador ou usa:

```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',"`"$((Resolve-Path .\scripts\set-scancode-map.ps1).Path)`""
```

O caminho tem de ser absoluto: com `-Verb RunAs`, o PowerShell elevado arranca sempre em `C:\Windows\System32` e ignora o `-WorkingDirectory`. O `-NoExit` mantém a janela aberta para veres o resultado (também fica em `%TEMP%\opencode\scancode-log.txt`). Para passar opções (ver abaixo), acrescenta-as no fim da lista, por exemplo `...,'-SwapIsoKeys'`.

### Confirmar depois de reiniciar

O Windows pode receber scancodes diferentes para algumas teclas, conforme corre numa VM ou no Boot Camp. Abre o Notepad e confirma:

- **Tecla `< >` (ao lado do Shift esquerdo):** deve escrever `<`. Se escrever outra coisa (e a do canto superior esquerdo escrever `<`), a troca das teclas ISO está ao contrário do que este Windows precisa. Por omissão, liga-se no Boot Camp e desliga-se nas VMs. Volta a correr o passo 2 com `-SwapIsoKeys` (para a ligar) ou `-SwapIsoKeys:$false` (para a desligar) e reinicia.
- **`Command` + `C` / `Command` + `V`:** devem copiar e colar. Se o `Command` abrir o menu Iniciar ou não funcionar como `Ctrl`, a VM já está a traduzir os modificadores (por exemplo, com perfis de atalhos do Parallels ou do VMware Fusion): volta a correr o passo 2 com `-KeepModifiers`, ou desliga essa tradução na VM.

As duas opções podem ser usadas em conjunto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-scancode-map.ps1 -SwapIsoKeys -KeepModifiers
```

---

## Reverter

```powershell
# Remover o mapa de scancodes (como administrador) e reiniciar
powershell -ExecutionPolicy Bypass -File .\scripts\undo-scancode-map.ps1
```

Para voltar ao layout original, ver a secção **Reverter** em [`docs/01-layout-apple.md`](docs/01-layout-apple.md) (Boot Camp) ou [`docs/02-layout-pt.md`](docs/02-layout-pt.md) (VM).

---

## Avisos

- O `Scancode Map` é **global**: aplica-se a todos os teclados ligados ao PC e ao ecrã de início de sessão. Com o layout Português, num teclado de PC português as 5 teclas mudadas ficam erradas (por exemplo, a tecla `« »` passa a escrever `+ *`); em ambos os modos, a tecla `Windows` direita passa a `Ctrl` direito.
- As alterações ao `Scancode Map` só entram em vigor **depois de reiniciar**.
- O `Scancode Map` só remapeia *scancodes*. Não vê teclas HID do tipo *consumer* (Eject, volume, multimedia); para essas é preciso software/driver.
- O mapa só serve com o layout para que foi gravado. Se mudares de layout, corre de novo o `set-scancode-map.ps1` com o mesmo `-Layout`.
- Algumas aplicações mantêm o layout antigo até serem reiniciadas; `Win + Space` ajuda a alternar.

---

## Ficheiros

| Caminho | Descrição |
|---|---|
| [`docs/01-layout-apple.md`](docs/01-layout-apple.md) | Layout Apple PT-PT do Boot Camp: diagnóstico, registo e como reverter |
| [`docs/02-layout-pt.md`](docs/02-layout-pt.md) | Layout Português do Windows vs keycaps Apple, como foi comparado e como reverter |
| [`docs/03-scancode-map.md`](docs/03-scancode-map.md) | Formato do `Scancode Map`, bytes de cada modo, opções e efeitos |
| [`docs/04-eject-key.md`](docs/04-eject-key.md) | Investigação da tecla Eject e do filtro `KeyMagic2` |
| [`docs/data/mac-portuguese.json`](docs/data/mac-portuguese.json) | Layout Portuguese do macOS exportado (teclado ISO) |
| [`scripts/enable-layout.ps1`](scripts/enable-layout.ps1) | Activa o layout Apple (Boot Camp) ou Português (VM) e define-o como predefinido |
| [`scripts/set-scancode-map.ps1`](scripts/set-scancode-map.ps1) | Grava o `Scancode Map` (opções `-Layout`, `-SwapIsoKeys` e `-KeepModifiers`) |
| [`scripts/undo-scancode-map.ps1`](scripts/undo-scancode-map.ps1) | Remove o `Scancode Map` |
| [`tools/diagnostics/`](tools/diagnostics/) | Ferramentas de diagnóstico no Windows (key spy, dump do layout, KLID) |
| [`tools/macos/dump-mac-layout.swift`](tools/macos/dump-mac-layout.swift) | Exporta um layout de teclado do macOS para JSON |

---

## Contexto

- **Teclado:** Apple Magic Keyboard PT-PT (ISO), `VID&0001004C_PID&0267`.
- **Boot Camp:** Apple iMac18,3, Windows 11 Pro `10.0.26300`, teclado por Bluetooth; layout Apple `a0000416`, `C:\Windows\System32\PortuguA.dll` (MSKLC 1.4, criado pela Apple e assinado pela Microsoft WHCP).
- **VM:** layout Português, KLID `00000816`, `kbdpo.dll` (tabelas da versão 10.0.25393.1, publicadas em [kbdlayout.info](https://kbdlayout.info/kbdpo/)).
- **Layout de referência:** Portuguese do macOS (`com.apple.keylayout.Portuguese`).

---

## Licença

Apache-2.0 — ver [`LICENSE`](LICENSE).
