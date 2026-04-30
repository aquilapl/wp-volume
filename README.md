## Budgie Wayland Volume Applet

Prosty i lekki aplet głośności dla środowiska Budgie Desktop, pod kompozytor Labwc na systemie Solus. Aplet wykorzystuje wireplumber do sterowania dźwiękiem oraz gtk-layer-shell dla natywnej obsługi okien na Waylandzie.

## Opis zależności i instalacja

Aby skompilować i zainstalować aplet w systemie Solus, wykonaj poniższe komendy w terminalu:
```bash
# 1. Instalacja wymaganych pakietów deweloperskich
sudo eopkg it budgie-desktop-devel libgtk-layer-shell-devel libgtk-3-devel vala meson ninja

# 2. Konfiguracja i kompilacja projektu
meson setup build
ninja -C build

# 3. Instalacja apletu w systemie
sudo ninja -C build install
```

## FUNKCJE I OBSŁUGA 
 * Pionowy suwak: Wyświetlany pod ikoną panelu z obramowanym tekstem %.
 * Autohide: Okno zamyka się po kliknięciu w pulpit lub inne okno.
 * Sterowanie myszą:
    - Lewy klik: Otwiera/zamyka suwak.
    - Środkowy klik: Wycisza dźwięk (mute).
    - Kółko myszy: Zmiana głośności (na ikonie i suwaku).
 * Menu: Prawy klik otwiera menu z dostępem do Wiremix.

## URUCHOMIENIE I KONFIGURACJA 
Aby system wykrył nową wtyczkę, zrestartuj panel:
```bash
budgie-panel --replace &
```
Następnie dodaj aplet w Ustawieniach pulpitu Budgie (Panel -> Dodaj aplet).

## ODINSTALOWANIE
W tym samym katalogu:
```bash
sudo ninja -C build uninstall
```
