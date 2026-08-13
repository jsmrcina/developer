This repository is a set of developer scripts used in Windows and Linux for making development using VS Code and Visual Studio simpler.

Everything is written in PowerShell and runs on both Windows PowerShell 5.1 and PowerShell 7+ (`pwsh`) on Linux/macOS. Anything that can only work on Windows (`trace`, `switchgdk`, `addpath -Machine`) detects the platform and tells you so instead of failing.

# Setup

Each machine picks a config by sourcing one of the `_<location>.ps1` files, which sets `$global:developerConfigFile` to the matching `<name>_config.json`. Then source `source.ps1`.

## Linux / macOS

Install PowerShell, then edit your profile:

```
pwsh
code $PROFILE.CurrentUserAllHosts     # ~/.config/powershell/profile.ps1
```

Paste in:

```powershell
# Source config file location
. <folder path to this repo>/_linux.ps1

# Source developer scripts
. <folder path to this repo>/source.ps1
```

e.g. `/home/jsmrcina/Documents/git/developer/source.ps1`

## Windows

Open `$profile`:

```
notepad $profile
```

Paste in:

```powershell
# Source config file location
. <folder path to this repo>\_home.ps1

# Source developer scripts
. <folder path to this repo>\source.ps1
```

e.g. `C:\Users\jsmrc\Documents\Git\developer\source.ps1`

# Config file format

All keys are optional except `gitFolderPath`.

| Key | Meaning |
| --- | --- |
| `gitFolderPath` | Root folder holding your clones. `cdgit` jumps here, `cloneall` checks here. |
| `mainBranchName` | Trunk branch name, exposed as `$global:officialBranch`. Defaults to `main`. |
| `gitEditor` | Value for `core.editor`. Defaults to `gvim` on Windows, `vim` elsewhere. |
| `githubUser` | Default owner for `cloneall`. |
| `p4User` | Default user for `p4_describe`. |
| `extraPaths` | Array of folders to append to `PATH`. Entries that don't exist are skipped. |
| `editorPath`, `githubClPath`, `godotPath`, `dotnetPath` | Individual tool folders to append to `PATH`. |
| `developerUnrealPath` | Unreal editor binary, used by `diffunreal`. `Engine/Binaries/Win64/UnrealEditor.exe` on Windows, `Engine/Binaries/Linux/UnrealEditor` on Linux. |

`developerFolderPath` and `pathSep` used to live in these files. They are now derived automatically (from `$PSScriptRoot` and `[System.IO.Path]::PathSeparator`) and are ignored if present.

# Platform helpers

`platform.ps1` is sourced first and defines what everything else builds on:

- `$global:isWindowsPlatform` / `$global:isLinuxPlatform` / `$global:isMacOSPlatform`
- `$global:pathSep` (`;` or `:`) and `$global:dirSep` (`\` or `/`)
- `Test-IsElevated` — Administrator on Windows, uid 0 on Unix
- `Test-WindowsOnly <feature>` — prints a message and returns `$false` off Windows
- `ConvertTo-FileUrl <path>` — a `file://` URL git accepts on either platform

# Private files

Anything matching `p_*` is gitignored, as is the `pfunctions/` folder. Drop machine-specific functions in `pfunctions/` and aliases in `p_aliases.ps1`; both are loaded automatically. `funclist` lists public and private functions separately.

# Notes

- `addpath <dir>` adds to the current session and persists to `extraPaths` in your config file, which works on every platform. `addpath <dir> -Machine` is the old Windows behaviour of writing the machine-wide `PATH` and needs elevation.
- `touch` shadows the Unix `touch` binary inside PowerShell but matches its semantics: create if missing, otherwise bump the timestamp.
- Git aliases are rewritten on every shell start, so editing `aliases.ps1` is enough to change them.
