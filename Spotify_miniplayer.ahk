#Requires AutoHotkey v2.0
#SingleInstance Force

DllCall("Shcore.dll\SetProcessDpiAwareness", "Int", 2)

si := Buffer(24, 0)
NumPut("UInt", 1, si)
DllCall("gdiplus\GdiplusStartup", "UPtr*", &gdipToken:=0, "Ptr", si, "Ptr", 0)

CLIENT_ID     := "cbe863fc68c04c49bfda61e897ac21be"
CLIENT_SECRET := "1d7e399c686548379607fd03490fbf98"
REDIRECT_URI  := "http://127.0.0.1:8888/callback"
TOKEN_FILE    := A_ScriptDir "\spotify_token.ini"

^!Right:: {
    SendInput("{Media_Next}")
    Sleep(300)
    if IsObject(overlayGui) && WinExist("ahk_id " overlayGui.Hwnd)
        MostrarOverlay()
}
^!Left:: {
    SendInput("{Media_Prev}")
    Sleep(300)
    if IsObject(overlayGui) && WinExist("ahk_id " overlayGui.Hwnd)
        MostrarOverlay()
}
^!Space:: SendInput("{Media_Play_Pause}")
^\::  MostrarOverlay()
!\::  MostrarOverlay()

overlayGui := ""

GetAccessToken() {
    global CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, TOKEN_FILE
    accessToken  := IniRead(TOKEN_FILE, "Token", "access_token",  "")
    refreshToken := IniRead(TOKEN_FILE, "Token", "refresh_token", "")
    expiresAt    := IniRead(TOKEN_FILE, "Token", "expires_at",    "0")
    if (accessToken != "" && A_NowUTC < expiresAt)
        return accessToken
    if (refreshToken != "") {
        creds := B64Encode(CLIENT_ID ":" CLIENT_SECRET)
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", "https://accounts.spotify.com/api/token", false)
        whr.SetRequestHeader("Authorization", "Basic " creds)
        whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        whr.Send("grant_type=refresh_token&refresh_token=" refreshToken)
        if (whr.Status = 200) {
            json := whr.ResponseText
            at  := RegExMatch(json, '"access_token"\s*:\s*"([^"]+)"',  &m) ? m[1] : ""
            ei  := RegExMatch(json, '"expires_in"\s*:\s*(\d+)',         &m) ? m[1] : 3600
            rt  := RegExMatch(json, '"refresh_token"\s*:\s*"([^"]+)"', &m) ? m[1] : refreshToken
            exp := DateAdd(A_NowUTC, ei - 60, "S")
            IniWrite(at,  TOKEN_FILE, "Token", "access_token")
            IniWrite(rt,  TOKEN_FILE, "Token", "refresh_token")
            IniWrite(exp, TOKEN_FILE, "Token", "expires_at")
            return at
        }
    }
    authUrl := "https://accounts.spotify.com/authorize"
        . "?client_id=" CLIENT_ID . "&response_type=code"
        . "&redirect_uri=" UriEncode(REDIRECT_URI)
        . "&scope=" UriEncode("user-read-currently-playing")
        . "&state=ahkoverlay"
    Run(authUrl)
    IB := InputBox("Después de aceptar en el browser, copiá la URL completa y pegala acá:", "Autenticación Spotify", "w500 h120")
    if (IB.Result != "OK") 
	return 
    code := RegExMatch(IB.Value, "[?&]code=([^&]+)", &m) ? m[1] : ""
    if (code = "") 
	return
    creds := B64Encode(CLIENT_ID ":" CLIENT_SECRET)
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", "https://accounts.spotify.com/api/token", false)
    whr.SetRequestHeader("Authorization", "Basic " creds)
    whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    whr.Send("grant_type=authorization_code&code=" code "&redirect_uri=" UriEncode(REDIRECT_URI))
    if (whr.Status = 200) {
        json := whr.ResponseText
        at  := RegExMatch(json, '"access_token"\s*:\s*"([^"]+)"',  &m) ? m[1] : ""
        rt  := RegExMatch(json, '"refresh_token"\s*:\s*"([^"]+)"', &m) ? m[1] : ""
        ei  := RegExMatch(json, '"expires_in"\s*:\s*(\d+)',         &m) ? m[1] : 3600
        exp := DateAdd(A_NowUTC, ei - 60, "S")
        IniWrite(at, TOKEN_FILE, "Token", "access_token")
        IniWrite(rt, TOKEN_FILE, "Token", "refresh_token")
        IniWrite(exp, TOKEN_FILE, "Token", "expires_at")
        return at
    }
    return ""
}

GetCurrentTrack(token) {
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", "https://api.spotify.com/v1/me/player/currently-playing", false)
    whr.SetRequestHeader("Authorization", "Bearer " token)
    whr.Send()
    if (whr.Status = 204)
        return {cancion: "", artista: "", imgUrl: "", playing: false}
    if (whr.Status != 200)
        return {cancion: "", artista: "", imgUrl: "", playing: false}
    json := whr.ResponseText
    isPlaying := InStr(json, '"is_playing" : true') || InStr(json, '"is_playing":true')
    if !isPlaying
        return {cancion: "", artista: "", imgUrl: "", playing: false}
    cancion := RegExMatch(json, '"item"\s*:\s*\{[^}]*?"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &m) ? m[1] : ""
    artista := RegExMatch(json, '"artists"\s*:\s*\[\s*\{[^}]*?"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &m) ? m[1] : ""
    imgUrl  := RegExMatch(json, '"images"\s*:\s*\[[^\]]*?"url"\s*:\s*"(https://i\.scdn\.co/image/[^"]+)"', &m) ? m[1] : ""
    return {cancion: cancion, artista: artista, imgUrl: imgUrl, playing: true}
}

DownloadImage(url, path) {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        if (whr.Status = 200) {
            stream := ComObject("ADODB.Stream")
            stream.Type := 1
            stream.Open()
            stream.Write(whr.ResponseBody)
            stream.SaveToFile(path, 2)
            stream.Close()
            return true
        }
    }
    return false
}

; Dibuja imagen directamente sobre el DC de la ventana usando GDI+
DrawImageOnWindow(hWnd, imgPath, x, y, w, h) {
    if DllCall("gdiplus\GdipLoadImageFromFile", "WStr", imgPath, "UPtr*", &img:=0) != 0
        return
    if !img
        return
    hDC := DllCall("GetDC", "Ptr", hWnd, "Ptr")
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hDC, "UPtr*", &g:=0)
    DllCall("gdiplus\GdipDrawImageRectI", "UPtr", g, "UPtr", img, "Int", x, "Int", y, "Int", w, "Int", h)
    DllCall("gdiplus\GdipDeleteGraphics", "UPtr", g)
    DllCall("gdiplus\GdipDisposeImage", "UPtr", img)
    DllCall("ReleaseDC", "Ptr", hWnd, "Ptr", hDC)
}

B64Encode(str) {
    bin := Buffer(StrPut(str, "UTF-8") - 1)
    StrPut(str, bin, "UTF-8")
    DllCall("Crypt32\CryptBinaryToStringA", "Ptr",bin, "UInt",bin.Size, "UInt",0x40000001, "Ptr",0, "UInt*",&len:=0)
    out := Buffer(len)
    DllCall("Crypt32\CryptBinaryToStringA", "Ptr",bin, "UInt",bin.Size, "UInt",0x40000001, "Ptr",out, "UInt*",&len)
    return StrReplace(StrGet(out, "CP0"), "`r`n", "")
}

UriEncode(str) {
    encoded := ""
    loop parse str {
        c := A_LoopField
        if c ~= "[A-Za-z0-9\-._~]"
            encoded .= c
        else {
            bin := Buffer(4)
            n   := StrPut(c, bin, "UTF-8") - 1
            loop n
                encoded .= Format("%{:02X}", NumGet(bin, A_Index-1, "UChar"))
        }
    }
    return encoded
}

MostrarOverlay() {
    global overlayGui

    token   := GetAccessToken()
    cancion := ""
    artista := ""
    imgPath := ""

    if (token != "") {
        track := GetCurrentTrack(token)
        if (!track.playing) {
            cancion := "No se está reproduciendo nada"
            artista := ""
            imgPath := ""
            try FileDelete(A_Temp "\spotify_cover.jpg")
        } else {
            cancion := track.cancion
            artista := track.artista
            if (track.imgUrl != "") {
                imgPath := A_Temp "\spotify_cover.jpg"
                DownloadImage(track.imgUrl, imgPath)
            }
        }
    }

    if (cancion = "") {
        try {
            titulo := WinGetTitle("ahk_exe Spotify.exe")
            if InStr(titulo, " - ") {
                partes  := StrSplit(titulo, " - ", , 2)
                artista := Trim(partes[1])
                cancion := Trim(partes[2])
            }
        }
    }

    if IsObject(overlayGui)
        try overlayGui.Destroy()

    winW    := 380
    winH    := 140
    imgSize := 100
    imgX    := winW - imgSize - 18
    imgY    := 20

    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlayGui.BackColor := "1C1C1C"
    overlayGui.MarginX := 0
    overlayGui.MarginY := 0

    overlayGui.SetFont("s9 Bold c2DB954", "Segoe UI Semibold")
    overlayGui.Add("Text", "x14 y14 w230", "● Spotify")

    overlayGui.SetFont("s10 Bold cFFFFFF", "Segoe UI Semibold")
    overlayGui.Add("Text", "x14 y40 w230", cancion)

    overlayGui.SetFont("s9 c999999", "Segoe UI")
    overlayGui.Add("Text", "x14 y66 w230", artista)

    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    posX := right  - winW - 20
    posY := bottom - winH - 12

    overlayGui.Show("x" posX " y" posY " w" winW " h" winH " NoActivate")

    hWnd := overlayGui.Hwnd
    hRgn := DllCall("CreateRoundRectRgn","Int",0,"Int",0,"Int",winW+1,"Int",winH+1,"Int",20,"Int",20,"Ptr")
    DllCall("SetWindowRgn","Ptr",hWnd,"Ptr",hRgn,"Int",1)

    ; dibujar imagen directo en el DC de la ventana, sin control Picture
    if (imgPath != "" && FileExist(imgPath))
        DrawImageOnWindow(hWnd, imgPath, imgX, imgY, imgSize, imgSize)

    SetTimer(CerrarOverlay, -4000)
}

CerrarOverlay() {
    global overlayGui
    if IsObject(overlayGui) {
        try overlayGui.Destroy()
        overlayGui := ""
    }
}
