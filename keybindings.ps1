## PSReadLine is only loaded in interactive sessions, so there is nothing to
## bind in script or remoting hosts.
if (-not (Get-Module -Name PSReadLine))
{
    return
}

## Windows-style word editing. Ctrl+Backspace and Ctrl+Delete delete a whole
## word rather than a single character, and Ctrl+Arrow moves a whole word.
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord

## The Windows console delivers these chords on its own. A Unix terminal only
## does if it emits the sequence PSReadLine expects: 0x08 for Ctrl+Backspace,
## ESC[3;5~ for Ctrl+Delete, ESC[1;5D / ESC[1;5C for Ctrl+Left / Ctrl+Right.
## Most terminals send all but Ctrl+Backspace, which usually needs configuring
## (for alacritty, see the Back/Control binding in alacritty.toml).
