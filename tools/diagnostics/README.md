# Ferramentas de diagnóstico

Scripts auxiliares usados durante a configuração. Não são necessários para o
funcionamento normal do teclado.

## `key-spy-gui.ps1`

Janela visível que mostra:

- `[TECLA] DOWN/UP scan=0x.. ext=sim/nao vk=0x.. (Nome)` — hook global de teclado;
- `[HID 0xPP:0xUU] dispositivo | bytes` — relatórios HID crus (todas as
  colecções registadas).

```powershell
powershell -ExecutionPolicy Bypass -File .\key-spy-gui.ps1
```

- **Não** arrancar com `-WindowStyle Hidden`: isso esconde também a janela do WinForms.
- Registo em `%TEMP%\opencode\keyspy-gui-log.txt`.
- Útil para descobrir scancodes e para confirmar se uma tecla chega ao Windows.

## `key-hook.ps1`

Hook global de teclado sem janela; escreve os scancodes em
`%TEMP%\opencode\key-hook-log.txt`.

```powershell
powershell -ExecutionPolicy Bypass -File .\key-hook.ps1
```

## `probe-klid.ps1`

Mostra o KLID activo (`GetKeyboardLayoutName`; deve ser `A0000416` no Boot Camp
e `00000816` numa VM), a lista de idiomas e o *default input method override*.

```powershell
powershell -ExecutionPolicy Bypass -File .\probe-klid.ps1
```

## `kbdump.ps1`

Compara o layout PT standard (`00000816`) com o layout Apple do Boot Camp
(`a0000416`) usando `ToUnicodeEx`, tecla a tecla (sem Shift / Shift / AltGr /
Shift+AltGr). Só é útil numa máquina com os drivers do Boot Camp; sem eles o
Windows não tem o layout `a0000416`.

```powershell
powershell -ExecutionPolicy Bypass -File .\kbdump.ps1
```
