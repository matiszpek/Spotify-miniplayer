# 🎵 Spotify Miniplayer — AutoHotkey

> Mini overlay para Windows que muestra la canción actual de Spotify con carátula, sin cambiar de ventana.

<img width="1919" height="1199" alt="Preview desktop" src="https://github.com/user-attachments/assets/4e7f3b50-1ece-4727-9ba2-0366c3571876" />

<br>

<img width="401" height="157" alt="Preview overlay" src="https://github.com/user-attachments/assets/4c01a176-5c10-433e-af6b-c681c43016ac" />

---

## ✨ Features

- Muestra **canción, artista y carátula** del álbum en tiempo real
- Overlay flotante en la esquina inferior derecha, **no interrumpe el foco**
- Se cierra solo a los 4 segundos
- Controla Spotify con atajos de teclado sin cambiar de ventana
- Avisa cuando no hay nada reproduciéndose

---

## ⚙️ Requisitos

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/)
- Cuenta de Spotify (cualquier plan)

---

## 🚀 Instalación

### 1. Clonar el repo

```bash
git clone https://github.com/TU_USUARIO/spotify-miniplayer
cd spotify-miniplayer
```

### 2. Crear una app en Spotify

1. Entrá a [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Click en **Create app**
3. Poné cualquier nombre y descripción
4. En **Redirect URI** agregá exactamente: `http://127.0.0.1:8888/callback`
5. Guardá y copiá el **Client ID** y **Client Secret** desde Settings

### 3. Configurar credenciales

```bash
copy config.example.ini config.ini
```

Abrí `config.ini` y completá con tus datos:

```ini
[Spotify]
ClientID     = tu_client_id
ClientSecret = tu_client_secret
RedirectURI  = http://127.0.0.1:8888/callback
```

> ⚠️ `config.ini` está en `.gitignore` — nunca se sube al repo.

### 4. Ejecutar

Click derecho en `Spotify_miniplayer.ahk` → **Run with AutoHotkey v2**

La primera vez se abre el browser para autorizar la app. Aceptás, copiás la URL completa de la barra de direcciones y la pegás en el cuadro que aparece. El token se guarda automáticamente y no vuelve a pedirlo.

---

## ⌨️ Atajos

| Atajo | Acción |
|---|---|
| `Ctrl + Alt + →` | Siguiente canción |
| `Ctrl + Alt + ←` | Canción anterior |
| `Ctrl + Alt + Space` | Play / Pausa |
| `Ctrl + \` | Mostrar overlay |
| `Alt + \` | Mostrar overlay |

---

## 🔁 Iniciar con Windows

Para que arranque automáticamente, poné un acceso directo al `.ahk` en la carpeta de inicio:

1. `Win + R` → escribí `shell:startup` → Enter
2. Pegá un acceso directo a `Spotify_miniplayer.ahk` en esa carpeta

---

## 📁 Archivos del repo

| Archivo | Descripción |
|---|---|
| `Spotify_miniplayer.ahk` | Script principal |
| `config.example.ini` | Plantilla de configuración |
| `config.ini` | Tu configuración personal *(no se sube)* |
| `spotify_token.ini` | Token OAuth guardado *(no se sube)* |

---

## 🛠️ Tecnologías

- [AutoHotkey v2](https://www.autohotkey.com/)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- GDI+ para renderizado de imágenes
