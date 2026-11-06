# Layout Apple PT-PT (`a0000416`)

## Sintoma

O Windows escrevia caracteres de layout US e o layout PT standard não correspondia aos keycaps do teclado Apple. O sistema só tinha `English (US)` activo; os layouts Apple do Boot Camp estavam instalados mas não seleccionados.

## Diagnóstico

- `Get-WinUserLanguageList` mostrava apenas `en-US` com o tip `0409:00000409`.
- `C:\Windows\System32\PortuguA.dll` existe e está assinado pela Apple (MSKLC 1.4), com o KLID `a0000416`.
- Descrição do layout: **Portuguese (Portugal) – Portuguese (Apple)**.
- Valores HKL observados:
  - US: `67699721`
  - PT standard: `135661590`
  - Apple: `-254933994`

## Configuração final (registo)

```text
HKCU\Keyboard Layout\Preload
  1 = 00000816
  2 = 00000409

HKCU\Keyboard Layout\Substitutes
  00000816 = a0000416

HKCU\Control Panel\International\User Profile
  InputMethodOverride = 0816:a0000416
```

- O *default input method override* ficou `0816:a0000416`, com a descrição
  `Portuguese (Portugal) - Portuguese (Apple)`.
- `00000816` é a "ranhura" do layout PT standard; a entrada em `Substitutes`
  redirecciona-a para a DLL da Apple (`a0000416`).

## Script

[`../scripts/enable-apple-layout.ps1`](../scripts/enable-apple-layout.ps1):

1. guarda um backup da lista de idiomas em `%TEMP%\opencode\winlang-backup.json`;
2. adiciona/mantém `pt-PT` com o tip `0816:a0000416` (fallback: `0409:a0000416`);
3. define o tip como predefinido;
4. força a janela em primeiro plano a mudar para o HKL Apple através de
   `WM_INPUTLANGCHANGEREQUEST`.

## Verificação

- [`../tools/diagnostics/probe-klid.ps1`](../tools/diagnostics/probe-klid.ps1) —
  mostra o KLID activo (deve ser `A0000416`) e a lista de idiomas.
- Processos novos (por exemplo, `notepad`) devem arrancar já com `A0000416`.
- [`../tools/diagnostics/kbdump.ps1`](../tools/diagnostics/kbdump.ps1) —
  compara o layout `00000816` com o `a0000416` para as teclas físicas
  (`0x29`, `0x56`, etc.).

## Reverter

1. Repor o método de entrada original (`0409:00000409`) como predefinido:

   ```powershell
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

O backup original (`winlang-backup.json`) continha apenas:

```json
{
  "Tag": "en-US",
  "Tips": ["0409:00000409"]
}
```
