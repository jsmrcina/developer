This repository is a set of developer scripts used in Windows and Linux for making development using VS Code and Visual Studio simpler.

# Windows

First, you'll need to create a `_location.ps1` file which contains a global definition for $global:developerConfigPath. That will point to the `config.json` you want to use in this location.

To source these on powershell start, simply run the following commands:

- Open `$profile`:

    `notepad $profile`

- Paste in:
    `# Source config file location`
    `. <folder path to this repo>\_location.ps1`

    `# Source developer scripts`
    `. <folder path to this repo>\source.ps1`
    ` e.g. C:\Users\jsmrc\Documents\Git\developer\source.ps1>`

- Save file