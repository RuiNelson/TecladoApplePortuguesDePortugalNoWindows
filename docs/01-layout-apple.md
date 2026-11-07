# Layout Apple PT-PT (`a0000416`) — Boot Camp

## Quando é usado

- Só existe com os drivers de teclado da Apple do Boot Camp
  (`C:\Windows\System32\PortuguA.dll`). Quando está instalado, o
  `enable-layout.ps1` e o `set-scancode-map.ps1` usam-no automaticamente
  (`-Layout Auto`).
- É igual ao macOS também com `AltGr` (`Option` direito): por exemplo
  `AltGr + 2` = `@`, `AltGr + 3` = `€` e `AltGr + Shift + 8 / 9` = `{` / `}`.
- Numa VM, ou em Windows ARM64, não existe; aí usa-se o layout Português do
  Windows ([`02-layout-pt.md`](02-layout-pt.md)).

## Sintoma (no iMac de teste)

O Windows escrevia caracteres de layout US e o layout PT standard não correspondia aos keycaps do teclado Apple. O sistema só tinha `English (US)` activo; os layouts Apple do Boot Camp estavam instalados mas não seleccionados.

## Diagnóstico

- `Get-WinUserLanguageList` mostrava apenas `en-US` com o tip `0409:00000409`.
- `C:\Windows\System32\PortuguA.dll` existe, foi criado pela Apple (MSKLC 1.4,
  versão 1.0.3.40) e está assinado pela Microsoft WHCP, com o KLID `a0000416`.
- Descrição do layout: **Portuguese (Portugal) – Portuguese (Apple)**.
- Valores HKL observados:
  - US: `67699721`
  - PT standard: `135661590`
  - Apple: `-254933994`

## Teclas ISO

O layout Apple põe `§ ±` no scancode `0x29` (canto superior esquerdo) e `< >` no
`0x56` (ao lado do Shift esquerdo), que são as posições dos keycaps. No Boot
Camp, porém, o teclado Apple ISO envia estas duas teclas trocadas, por isso o
`Scancode Map` troca-as de volta (`-SwapIsoKeys`, ligado por omissão quando há
drivers do Boot Camp). Ver [`03-scancode-map.md`](03-scancode-map.md).

## Configuração final (registo)

```text
HKCU\Keyboard Layout\Preload
  1 = 00000816

HKCU\Keyboard Layout\Substitutes
  00000816 = a0000416

HKCU\Control Panel\International\User Profile
  InputMethodOverride = 0816:a0000416
```

- O *default input method override* fica `0816:a0000416`, com a descrição
  `Portuguese (Portugal) - Portuguese (Apple)`.
- `00000816` é a "ranhura" do layout PT standard; a entrada em `Substitutes`
  redirecciona-a para a DLL da Apple (`a0000416`).

## Script

[`../scripts/enable-layout.ps1`](../scripts/enable-layout.ps1), com o layout
Apple:

1. confirma que o layout `a0000416` está instalado (chave
   `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416` e DLL em
   `System32`); com `-Layout Apple` e sem o layout, pára sem alterar nada;
2. guarda um backup da lista de idiomas em `%TEMP%\opencode\winlang-backup.json`
   (só se ainda não existir, para não perder o original);
3. adiciona/mantém `pt-PT` com o tip `0816:a0000416` (fallback: `0409:a0000416`)
   e confirma que o Windows o manteve na lista;
4. define o tip como predefinido;
5. força a janela em primeiro plano a mudar para o HKL Apple através de
   `WM_INPUTLANGCHANGEREQUEST`.

## Verificação

- [`../tools/diagnostics/probe-klid.ps1`](../tools/diagnostics/probe-klid.ps1) —
  mostra o KLID activo (deve ser `A0000416`) e a lista de idiomas.
- Processos novos (por exemplo, `notepad`) devem arrancar já com `A0000416`.
- [`../tools/diagnostics/kbdump.ps1`](../tools/diagnostics/kbdump.ps1) —
  compara o layout `00000816` com o `a0000416` para as teclas físicas
  (`0x29`, `0x56`, etc.).

## Reverter

1. Repor o método de entrada original (`0409:00000409`) como predefinido. Se o
   `en-US` já não estiver na lista, é preciso voltar a adicioná-lo:

   ```powershell
   $list = Get-WinUserLanguageList
   if (-not ($list | Where-Object { $_.LanguageTag -eq 'en-US' })) { $list.Add('en-US') }
   Set-WinUserLanguageList -LanguageList $list -Force
   Set-WinDefaultInputMethodOverride -InputTip '0409:00000409'
   ```

2. Remover a substituição do layout PT standard:

   ```powershell
   Remove-ItemProperty 'HKCU:\Keyboard Layout\Substitutes' -Name '00000816' -ErrorAction SilentlyContinue
   ```

3. Opcionalmente, remover o idioma `pt-PT` da lista:

   ```powershell
   $list = Get-WinUserLanguageList
   $list = $list | Where-Object { $_.LanguageTag -ne 'pt-PT' }
   Set-WinUserLanguageList -LanguageList $list -Force
   ```

4. Reiniciar sessão/aplicações.

O backup original (`winlang-backup.json`) do iMac de teste continha apenas:

```json
{
  "Tag": "en-US",
  "Tips": ["0409:00000409"]
}
```
