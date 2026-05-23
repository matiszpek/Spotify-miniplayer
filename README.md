# Spotify Miniplayer — AutoHotkey

Mini overlay que muestra la canción y carátula actual de Spotify al presionar un atajo de teclado.

## Requisitos

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/)
- Cuenta de Spotify (cualquier plan)

## Instalación

### 1. Clonar el repo
```
git clone https://github.com/TU_USUARIO/spotify-miniplayer
cd spotify-miniplayer
```

### 2. Crear tu app en Spotify
1. Entrá a [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Click en **Create app**
3. Poné cualquier nombre y descripción
4. En **Redirect URI** agregá: `http://127.0.0.1:8888/callback`
5. Guardá y copiá el **Client ID** y **Client Secret** desde Settings

### 3. Configurar credenciales
```
copy config.example.ini config.ini
```
Abrí `config.ini` y reemplazá los valores:
```ini
[Spotify]
ClientID     = tu_client_id
ClientSecret = tu_client_secret
RedirectURI  = http://127.0.0.1:8888/callback
```

### 4. Ejecutar
Click derecho en `Spotify_miniplayer.ahk` → **Run with AutoHotkey v2**

La primera vez se abrirá el browser para autorizar. Aceptás, copiás la URL de redirección y la pegás en el cuadro que aparece. El token se guarda automáticamente.

## Atajos

| Atajo | Acción |
|---|---|
| `Ctrl+Alt+→` | Siguiente canción |
| `Ctrl+Alt+←` | Canción anterior |
| `Ctrl+Alt+Space` | Play / Pausa |
| `Ctrl+\` | Mostrar overlay |
| `Alt+\` | Mostrar overlay |

## Iniciar con Windows

Poné un acceso directo al `.ahk` en:
```
shell:startup
```
