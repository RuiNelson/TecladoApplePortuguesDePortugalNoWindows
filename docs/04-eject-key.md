# Tecla Eject (investigação)

## Objectivo

Transformar a tecla **Eject** numa tecla de **suspender**. A investigação foi
abandonada a pedido do utilizador; **não foi alterado nada no sistema**.

## Sintomas

- Premir Eject no Windows não faz nada.
- O *low-level keyboard hook* não recebe scancode nem `vkCode`.
- O *raw input* HID não recebe qualquer relatório da tecla, nem na colecção
  *consumer* (`0x0C:0x01`) nem nas colecções *vendor* (`0xFF00:0x14`,
  `0xFF43:0x202`).

## Dispositivo

Teclado Apple Magic Keyboard PT-PT por Bluetooth:

```text
BTHENUM\{00001124-0000-1000-8000-00805F9B34FB}_VID&0001004C_PID&0267
```

Colecções HID observadas:

| Colecção | Usage page/usage | Função |
|---|---|---|
| `COL01` | teclado | teclas normais |
| `COL02` | `0xFF00:0x14` | vendor-defined (Apple) |
| `COL03` | `0x0C:0x01` | consumer control |

## Causa provável: `KeyMagic2`

O dispositivo Bluetooth do teclado tem:

```text
DEVPKEY_Device_Service    = HidBth
DEVPKEY_Device_LowerFilters = KeyMagic2
```

O `KeyMagic2` é o filtro de teclado HID do Boot Camp:

- serviço `KeyMagic2`, `C:\Windows\System32\drivers\KeyMagic2.sys`
  (57 752 bytes, 29/04/2021);
- instalado por `oem19.inf` / `oem3.inf`;
- parâmetros de registo observados em
  `HKLM\SYSTEM\CurrentControlSet\Services\KeyMagic2`:

```text
Keymap        = {105, 70, 106, 71, ...}
KeymapFn      = {12, 34, 13, 30, ...}
KeymapNumlock = {12, 93, 13, 89, ...}
enable        = {1}
OSXFnBehavior = {1}
```

Como é um *lower filter* (fica abaixo do `HidBth`/`hidclass`), consegue
consumir relatórios antes de chegarem ao *raw input* e ao `kbdhid`. É a
explicação mais provável para o Eject nunca aparecer no Windows.

## Opções consideradas (não executadas)

1. **Remover/desactivar o filtro `KeyMagic2`**
   - Editar `LowerFilters` do dispositivo (com backup) e reiniciar o
     dispositivo ou o PC.
   - Testar se o Eject passa a aparecer como *consumer* `0xB8`.
   - Risco: pode alterar o comportamento de outras teclas Apple
     (F-keys, brilho, media) e afecta também o teclado interno.

2. **Configurar a tabela `Keymap` do `KeyMagic2`**
   - Formato não documentado; exigiria engenharia inversa.

3. **Driver de terceiros**
   - Por exemplo *Magic Utilities* (pago), que suporta explicitamente o
     remapeamento da tecla Eject.

4. **Mapear outra tecla**
   - Alternativa sem mexer no driver: escolher outra tecla para suspender.

## Se for retomado

1. Fazer backup do valor `LowerFilters` do dispositivo.
2. Remover `KeyMagic2` e reiniciar o dispositivo.
3. Com o `key-spy-gui.ps1`, verificar se o Eject aparece como
   `[HID 0x0C:0x01] ... B8 ...`.
4. Se aparecer, uma pequena aplicação de *raw input* pode chamar
   `SetSuspendState` quando receber o usage `0xB8`.

## Nota sobre a ferramenta de diagnóstico

O primeiro `key-spy-gui.ps1` rebentava com `AccessViolationException` ao
receber `WM_INPUT`: o `lParam` é um **`HRAWINPUT`** (handle), não um ponteiro
para `RAWINPUT`. A versão em
[`../tools/diagnostics/key-spy-gui.ps1`](../tools/diagnostics/key-spy-gui.ps1)
já lê os dados via `GetRawInputData` e está corrigida.
