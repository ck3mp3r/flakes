# Portable Tmux Configuration

A fully portable tmux configuration with custom plugins, system monitoring, and Catppuccin theming. This flake wraps tmux so that wherever you run it, it will have the right configuration and plugins.

## Features

### 🎨 Theming
- **Catppuccin Mocha** theme with custom status modules
- Rounded window styling
- Custom background color (#242638)
- Heavy pane borders with status at bottom

### 📊 System Monitoring
- **CPU Usage** - Real-time CPU percentage
- **RAM Usage** - Memory usage with dynamic color coding
- **GPU Usage** - GPU utilization (Metal on macOS, NVIDIA/AMD on Linux)
- **Battery Status** - Battery level indicator
- **2-second caching** to reduce system overhead

### 🔧 Configuration Highlights
- **Prefix Key**: `C-a` (instead of default `C-b`)
- **Base Index**: 1 (windows and panes start at 1)
- **Key Mode**: Vi-style bindings
- **Shell**: Nushell integration
- **Mouse Support**: Enabled
- **Clipboard**: Full macOS clipboard integration
- **Vim Integration**: Smart pane navigation that works with Neovim

### 🎮 Key Bindings

#### Basic Navigation
- `C-a a` - Switch to last window
- `C-a r` - Reload configuration

#### Smart Vim-Tmux Navigation
- `C-h` - Move left (Vim-aware)
- `C-j` - Move down (Vim-aware)
- `C-k` - Move up (Vim-aware)
- `C-l` - Move right (Vim-aware)
- `C-\` - Move to last pane (Vim-aware)

#### Copy Mode (Vi-style)
- `v` - Begin selection
- `y` - Copy to clipboard
- Mouse drag - Copy selection to clipboard

#### Utility
- `M-k` (Alt+K) - Clear screen

### 🔌 Plugins
- **copycat** - Enhanced search functionality
- **pain-control** - Better pane navigation and resizing
- **yank** - Clipboard integration
- **catppuccin** - Custom Catppuccin theme with status modules
- **monitor** - Unified CPU/RAM/GPU/Battery monitoring plugin

## Usage

### Running Directly

```bash
nix run github:ck3mp3r/flakes?dir=tmux
```

Or from local clone:

```bash
cd /path/to/flakes/tmux
nix run
```

### Using in a Development Shell

```bash
nix develop github:ck3mp3r/flakes?dir=tmux
tmux
```

### Adding to Your System

Add to your `flake.nix`:

```nix
{
  inputs = {
    tmux-portable.url = "github:ck3mp3r/flakes?dir=tmux";
  };

  outputs = { self, nixpkgs, tmux-portable, ... }: {
    # Use in your system configuration
    environment.systemPackages = [
      tmux-portable.packages.${system}.default
    ];
  };
}
```

### Using with Home Manager

```nix
{ pkgs, tmux-portable, ... }:
{
  home.packages = [
    tmux-portable.packages.${pkgs.system}.default
  ];
}
```

## How It Works

This flake creates a wrapper around tmux that:

1. **Bundles all plugins** - Custom CPU/RAM/GPU monitoring and Catppuccin theme
2. **Generates configuration** - Creates a complete tmux.conf with all settings
3. **Sets up paths** - Automatically places config in `~/.config/tmux/tmux.conf`
4. **Wraps execution** - Ensures tmux always uses the bundled configuration

The result is a truly portable tmux setup that works identically anywhere you run it.

## Platform Support

### macOS
- CPU monitoring via `iostat`
- RAM monitoring via `vm_stat` with accurate page calculations
- GPU monitoring via `ioreg` (Metal GPU usage)
- Clipboard via `pbcopy`

### Linux
- CPU monitoring via `iostat` or `sar`
- RAM monitoring via `free`
- GPU monitoring via `nvidia-smi` (NVIDIA) or `radeontop` (AMD)
- Clipboard integration available

### FreeBSD/OpenBSD
- CPU monitoring via `iostat`
- RAM monitoring via `vm_stat`
- Basic clipboard support

## Customization

The flake is designed to be portable and self-contained, but you can fork and modify:

1. **Change theme flavor**: Edit `flake.nix` line with `@catppuccin_flavor`
2. **Adjust thresholds**: Modify `@cpu_medium_thresh`, `@cpu_high_thresh`, etc.
3. **Customize status bar**: Rearrange status modules in the `status-right` section
4. **Add plugins**: Include additional tmux plugins in the `plugins` list

## File Structure

```
tmux/
├── flake.nix                           # Main flake configuration
├── plugins/
│   ├── cpu/                            # Custom CPU/RAM/GPU monitoring plugin
│   │   ├── cpu.tmux                    # Plugin entry point
│   │   └── scripts/
│   │       ├── helpers.sh              # Utility functions + caching
│   │       ├── cpu_percentage.sh       # CPU usage script
│   │       ├── cpu_icon.sh             # CPU icon selector
│   │       ├── cpu_bg_color.sh         # CPU background color
│   │       ├── cpu_fg_color.sh         # CPU foreground color
│   │       ├── ram_percentage.sh       # RAM usage script
│   │       ├── ram_icon.sh             # RAM icon selector
│   │       ├── ram_bg_color.sh         # RAM background color
│   │       ├── ram_fg_color.sh         # RAM foreground color
│   │       └── gpu_percentage.sh       # GPU usage script
│   └── catppuccin/
│       └── status/
│           ├── gpu.conf                # GPU status module config
│           └── ram.conf                # RAM status module config
└── README.md                           # This file
```

## Monitoring Details

### CPU Monitoring
- Uses `iostat` for accurate CPU usage on most platforms
- Falls back to `sar` if iostat is unavailable
- Windows support via `WMIC`
- Format: 3.1 decimal places (e.g., "45.3%")

### RAM Monitoring
- **Linux**: Uses `free` command
- **macOS**: Uses `vm_stat` with sophisticated page calculation
  - Accounts for: active, inactive, speculative, wired, compressed pages
  - Excludes: purgeable and file-backed pages from "used" count
- Format: 3.1 decimal places

### GPU Monitoring
- **macOS**: Queries Metal GPU via IOAccelerator using `ioreg`
- **Linux NVIDIA**: Uses `nvidia-smi` for GPU utilization
- **Linux AMD**: Uses `radeontop` for GPU metrics
- Shows "N/A" if GPU monitoring is unavailable
- Format: 3.1 decimal places

### Caching
All metrics are cached for 2 seconds to reduce system overhead. This means:
- Scripts don't hammer the system with constant queries
- Status bar updates are smooth and efficient
- Minimal CPU overhead from monitoring itself

## License

MIT License - Feel free to use and modify as needed.

## Credits

- **Catppuccin**: [catppuccin/tmux](https://github.com/catppuccin/tmux)
- **Vim-Tmux Navigator**: Smart pane navigation pattern
- Original dotfiles configuration by Christian Kampka
