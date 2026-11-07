# Teclado Apple Português de Portugal no Windows

Configura o Windows para que um teclado Apple PT-PT (por exemplo, o Magic Keyboard) escreva o que está gravado nas teclas. Usa só o layout **Português** que já vem com o Windows e um `Scancode Map` no registo: não instala drivers nem DLLs. Por isso funciona no Boot Camp e em máquinas virtuais (Parallels, VMware Fusion, UTM…), em x64 e em ARM64.

- 6 teclas trocadas de lugar para os caracteres coincidirem com os keycaps Apple;
- `Command` esquerdo → `Ctrl`, `Ctrl` esquerdo → tecla `Windows`, `Command` direito → `Ctrl` direito;
- opção para VMs que trocam entre si as teclas `<>` e `§ ±`;
- investigação da tecla **Eject** (consumida pelo filtro `KeyMagic2` do Boot Camp).

> **Estado:** esta versão (layout Português do Windows + `Scancode Map`) ainda não foi testada no Windows. A versão anterior, que usava o layout Apple do Boot Camp, foi confirmada num iMac a 6 de Novembro de 2026.

---

## Resultado

| Tecla física (keycap Apple) | No Windows |
|---|---|
| Letras, números, `' ?`, `` ´ ` `` (mortas), `ç Ç`, `, ;`, `. :`, `- _` | iguais ao keycap |
| `<>` (canto superior esquerdo) | `<` / `>` |
| `+ *` | `+` / `*` |
| `º ª` | `º` / `ª` |
| `~ ^` | `~` / `^` (teclas mortas) |
| `\ \|` | `\` / `\|` |
| `§ ±` (ao lado do Shift esquerdo) | `«` / `»` (o layout Português não tem `§ ±` numa tecla) |
| `Command` esquerdo | `Ctrl` esquerdo |
| `Ctrl` esquerdo | tecla `Windows` (menu Iniciar) |
| `Command` direito | `Ctrl` direito |
| `Option` direito | `AltGr` |
| Print Screen | não existe; usar `Win + Shift + S` |

### Símbolos com `AltGr`

O layout Português do Windows tem alguns símbolos noutras teclas do que o macOS:

| Símbolo | macOS (teclado Apple) | Windows (esta configuração) |
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

- O `AltGr` também se obtém com `Command` + `Option` esquerdo (que ficam `Ctrl` + `Alt`).
- O ponto do teclado numérico escreve `.` (no macOS escreve `,`).

---

## Como funciona

O layout Português do Windows (`00000816`, `kbdpo.dll`) e os keycaps Apple PT-PT só diferem, em Normal e Shift, em 6 teclas. O `Scancode Map` muda essas 6 teclas de sítio e troca os modificadores. A comparação foi feita com o layout Portuguese do próprio macOS, exportado com [`tools/macos/dump-mac-layout.swift`](tools/macos/dump-mac-layout.swift) para [`docs/data/mac-portuguese.json`](docs/data/mac-portuguese.json). Detalhes em [`docs/01-layout-pt.md`](docs/01-layout-pt.md) e [`docs/02-scancode-map.md`](docs/02-scancode-map.md).

O layout Apple do Boot Camp (`a0000416`) deixou de ser usado: só existe com os drivers do Boot Camp, que são x64, e não está disponível em VMs nem em Windows ARM64.

---

## Aplicar

Requer **administrador** para o mapa de scancodes e **reinício** para ele entrar em vigor. Os comandos correm-se a partir da pasta do repositório (a que tem o `README.md`).

```powershell
# 1) Layout Português do Windows (por utilizador; não precisa de admin)
powershell -ExecutionPolicy Bypass -File .\scripts\enable-pt-layout.ps1

# 2) Mapa de scancodes (executar como administrador)
powershell -ExecutionPolicy Bypass -File .\scripts\set-scancode-map.ps1

# 3) Reiniciar o Windows
```

O script `set-scancode-map.ps1` tem `#requires -RunAsAdministrator`. Se não estiveres numa consola elevada, abre o PowerShell como administrador ou usa:

```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',"`"$((Resolve-Path .\scripts\set-scancode-map.ps1).Path)`""
```

O caminho tem de ser absoluto: com `-Verb RunAs`, o PowerShell elevado arranca sempre em `C:\Windows\System32` e ignora o `-WorkingDirectory`. O `-NoExit` mantém a janela aberta para veres o resultado (também fica em `%TEMP%\opencode\scancode-log.txt`). Para passar opções (ver abaixo), acrescenta-as no fim da lista, por exemplo `...,'-SwapIsoKeys'`.

### Confirmar depois de reiniciar (sobretudo em VMs)

Cada programa de virtualização pode enviar ao Windows scancodes diferentes para algumas teclas. Abre o Notepad e confirma:

- **Tecla do canto superior esquerdo (`<>`):** se escrever `<`, está certo. Se escrever `«`, a VM troca as duas teclas ISO: volta a correr o passo 2 com `-SwapIsoKeys` e reinicia.
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

Para voltar ao layout original, ver a secção **Reverter** em [`docs/01-layout-pt.md`](docs/01-layout-pt.md).

---

## Avisos

- O `Scancode Map` é **global**: aplica-se a todos os teclados ligados ao PC e ao ecrã de início de sessão. Num teclado de PC português, as 6 teclas trocadas ficam erradas (por exemplo, a tecla `« »` passa a escrever `+ *`), e a tecla `Windows` direita passa a `Ctrl` direito.
- As alterações ao `Scancode Map` só entram em vigor **depois de reiniciar**.
- O `Scancode Map` só remapeia *scancodes*. Não vê teclas HID do tipo *consumer* (Eject, volume, multimedia); para essas é preciso software/driver.
- O mapa pressupõe o layout **Português** activo. Com outro layout (por exemplo, o Apple do Boot Camp), as teclas trocadas escrevem outros caracteres; o `enable-pt-layout.ps1` tira o layout Apple da lista de idiomas.
- Algumas aplicações mantêm o layout antigo até serem reiniciadas; `Win + Space` ajuda a alternar.

---

## Ficheiros

| Caminho | Descrição |
|---|---|
| [`docs/01-layout-pt.md`](docs/01-layout-pt.md) | Layout Português do Windows vs keycaps Apple, como foi comparado e como reverter |
| [`docs/02-scancode-map.md`](docs/02-scancode-map.md) | Formato do `Scancode Map`, bytes usados, opções e efeitos |
| [`docs/03-eject-key.md`](docs/03-eject-key.md) | Investigação da tecla Eject e do filtro `KeyMagic2` |
| [`docs/data/mac-portuguese.json`](docs/data/mac-portuguese.json) | Layout Portuguese do macOS exportado (teclado ISO) |
| [`scripts/enable-pt-layout.ps1`](scripts/enable-pt-layout.ps1) | Activa o layout Português do Windows e define-o como predefinido |
| [`scripts/set-scancode-map.ps1`](scripts/set-scancode-map.ps1) | Grava o `Scancode Map` (opções `-SwapIsoKeys` e `-KeepModifiers`) |
| [`scripts/undo-scancode-map.ps1`](scripts/undo-scancode-map.ps1) | Remove o `Scancode Map` |
| [`tools/diagnostics/`](tools/diagnostics/) | Ferramentas de diagnóstico no Windows (key spy, dump do layout, KLID) |
| [`tools/macos/dump-mac-layout.swift`](tools/macos/dump-mac-layout.swift) | Exporta um layout de teclado do macOS para JSON |

---

## Contexto

- **Teclado:** Apple Magic Keyboard PT-PT (ISO), `VID&0001004C_PID&0267`.
- **Layout Windows:** Português, KLID `00000816`, `kbdpo.dll` (tabelas da versão 10.0.25393.1, publicadas em [kbdlayout.info](https://kbdlayout.info/kbdpo/)).
- **Layout de referência:** Portuguese do macOS (`com.apple.keylayout.Portuguese`).
- **Versão anterior (layout Apple do Boot Camp):** testada num Apple iMac18,3 com Windows 11 Pro `10.0.26300`.

---

## Licença

Apache-2.0 — ver [`LICENSE`](LICENSE).
