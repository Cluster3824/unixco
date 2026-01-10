# Linux Dotfiles Configuration

A complete and modular Linux dotfiles configuration featuring **Hyprland** (Wayland compositor) with a modern aesthetic, productivity tools, and system customizations.

## 📋 Project Structure

```
├── hypr/                          # Hyprland WM Configuration
│   ├── hyprland.conf             # Main configuration file
│   ├── bind.conf                 # Keyboard & mouse bindings
│   ├── animation.conf            # Window animations
│   ├── looknfeel.conf            # Visual styling & decorations
│   ├── env.conf                  # Environment variables
│   ├── input.conf                # Input devices & gestures
│   ├── startup.conf              # Autostart applications
│   ├── hypridle.conf             # Idle/lock management
│   ├── hyprlock.conf             # Lock screen configuration
│   ├── hyprpaper.conf            # Wallpaper settings
│   ├── colors.conf               # Color theme variables
│   ├── permissions.conf          # Permission settings
│   └── gruvbox.conf              # Gruvbox color scheme
├── waybar/                        # Status bar configuration
│   ├── config                    # Main waybar config
│   ├── style.css                 # Styling
│   └── scripts/                  # Custom scripts
├── kitty/                         # Terminal emulator config
│   ├── kitty.conf
│   └── colors.conf
├── wofi/                          # Application launcher
│   ├── config
│   ├── style.css
│   └── gruvbox.css
├── wlogout/                       # Logout menu
│   ├── layout
│   ├── style.css
│   └── icons/
├── swaync/                        # Notification daemon
│   ├── config.json
│   └── style.css
├── vesktop/                       # Discord client
│   ├── settings.json
│   ├── themes/
│   └── settings/
├── spicetify/                     # Spotify client customization
│   ├── config-xpui.ini
│   ├── Themes/
│   └── CustomApps/
├── btop/                          # System monitor
│   ├── btop.conf
│   └── themes/
├── cava/                          # Audio visualizer
│   ├── config
│   └── shaders/
├── fastfetch/                     # System info display
│   ├── config.jsonc
│   ├── profiles/
│   └── config.jsonc variants
├── yazi/                          # File manager
│   ├── yazi.toml
│   ├── keymap.toml
│   └── theme.toml
├── zathura/                       # PDF viewer
│   └── zathurarc
├── swappy/                        # Screenshot editor
│   └── config
└── assets/                        # Images and resources
```

## ✨ Features

### Hyprland Window Manager
- **Modern Wayland compositor** with tiling/floating layouts
- **Dynamic animations** with custom bezier curves
- **Multi-monitor support** with dedicated workspaces
- **Split monitor workspaces** plugin for organized workflows
- **Vim-style keybindings** (hjkl navigation)
- **Custom keybinds** for all major applications

### Visual Theme
- **Gruvbox color scheme** for consistent aesthetics
- **Rounded corners** with custom shadows
- **Blur effects** on inactive windows
- **Custom border colors** for active/inactive windows
- **Gradient borders** for visual appeal

### Productivity Tools
- **Waybar** - Customizable status bar with system info, network, audio, bluetooth
- **Wofi** - Fast application launcher
- **Kitty** - GPU-accelerated terminal with true color support
- **Yazi** - Modern TUI file manager
- **Zathura** - Minimal PDF viewer with vim keybindings

### System Integration
- **Swaync** - Notification daemon for Wayland
- **Hypridle** - Idle management with auto-lock
- **Hyprlock** - Modern lock screen
- **Swappy** - Screenshot annotation tool
- **Spicetify** - Spotify client theming

### Multimedia
- **Vesktop** - Discord client with custom themes
- **Cava** - Audio visualizer with custom shaders
- **Btop** - Modern system monitor
- **FastFetch** - System information display

## 🚀 Installation

### Prerequisites
- **Hyprland** - Install from your package manager
- **Wayland** - Required for Hyprland
- **Required packages:**
  ```bash
  pacman -S hyprland kitty waybar wofi hyprlock hypridle \
            swaync wl-clipboard cliphist swww hyprpaper \
            brightnessctl playerctl wpctl blueman thunar
  ```

### Setup Steps

1. **Clone or copy this configuration:**
   ```bash
   # If from GitHub
   git clone https://github.com/Cluster3824/unixco.git ~/.config/dotfiles
   
   # Copy to ~/.config
   cp -r ./hypr ~/.config/
   cp -r ./waybar ~/.config/
   cp -r ./kitty ~/.config/
   # ... copy other configs as needed
   ```

2. **Update asset paths (if needed):**
   - Wallpapers: Update `hyprpaper.conf` paths
   - Lock screen: Update `hyprlock.conf` asset paths
   - Profile pictures: Update paths as needed

3. **Install fonts (recommended):**
   ```bash
   pacman -S ttf-iosevka-nerd ttf-noto-nerd ttf-dseg7-nerd
   ```

4. **Set up symbolic links (optional for easy updates):**
   ```bash
   ln -s ~/.config/dotfiles/hypr ~/.config/hypr
   ln -s ~/.config/dotfiles/waybar ~/.config/waybar
   # ... etc
   ```

## ⌨️ Key Bindings

| Binding | Action |
|---------|--------|
| `SUPER + Q` | Kill active window |
| `SUPER + H/L/K/J` | Focus window (left/right/up/down) |
| `SUPER + 1-6` | Switch workspace |
| `SUPER + SHIFT + 1-6` | Move window to workspace |
| `SUPER + V` | Toggle floating |
| `SUPER + R` | Application launcher |
| `SUPER + E` | File manager |
| `SUPER + L` | Lock screen |
| `SUPER + N` | Toggle notifications |
| `SUPER + Z` | Next theme |
| `SUPER + SHIFT + Z` | Theme list |
| `Volume/Brightness keys` | Adjust volume/brightness |

## 🎨 Customization

### Change Color Scheme
1. Edit `colors.conf` or create a new color file
2. Update `gruvbox.conf` with your preferred colors
3. Source the new file in `hyprland.conf`

### Modify Keybindings
Edit `bind.conf` - add/remove/modify bindings as needed

### Adjust Monitor Configuration
Edit the `[monitors]` section in `hyprland.conf`:
```conf
monitor=HDMI-A-1,1920x1080@60,0x0,1
monitor=eDP-1,2560x1600@60,1920x0,1.25
```

### Add Startup Applications
Edit `startup.conf` and add new `exec-once` commands

## 📦 Dependencies

- **Window Manager:** `hyprland`
- **Bar:** `waybar`
- **Terminal:** `kitty`
- **Launcher:** `wofi`
- **Lock Screen:** `hyprlock`, `hypridle`
- **Notifications:** `swaync`
- **Wallpaper:** `swww`, `hyprpaper`
- **Utilities:** `thunar`, `wl-clipboard`, `cliphist`, `brightnessctl`, `playerctl`, `wpctl`

## 🔧 Troubleshooting

### Hyprland won't start
- Ensure Wayland session is selected at login
- Check logs: `journalctl -xe`

### Missing fonts in lock screen
- Install required fonts: `ttf-iosevka-nerd`, `ttf-dseg7-nerd`

### Wallpaper not showing
- Verify wallpaper paths in `hyprpaper.conf`
- Ensure file exists at specified location

### Keybindings not working
- Check `bind.conf` syntax
- Verify application names (`$terminal`, `$browser`, etc.)
- Reload Hyprland: `SUPER + SHIFT + R`

## 📝 Notes

- Paths use `~` for home directory (generic for all users)
- Color variables are centralized in `colors.conf` for easy theming
- Configuration is modular - each component can be customized independently
- All configs follow Hyprland 0.40+ syntax

## 🔗 Resources

- [Hyprland Wiki](https://wiki.hyprland.org)
- [Wayland Documentation](https://wayland.freedesktop.org)
- [Gruvbox Theme](https://github.com/morhetz/gruvbox)

## 📄 License

This configuration is provided as-is. Feel free to fork, modify, and use for your own setup.

## 💡 Contributing

Found improvements? Feel free to create issues or pull requests!

---

**Last Updated:** January 2026  
**Tested On:** Arch Linux / Hyprland 0.40+
# unixco
