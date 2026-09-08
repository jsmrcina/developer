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
## (for alacritty, that is the Back/Control binding in
## terminal/alacritty-keybindings.toml, which alacritty.toml has to import).

## Windows-style Escape. In Windows edit mode Escape throws away whatever is
## on the line; in Emacs mode it is the Meta prefix instead, so the key does
## nothing on its own here. Binding it directly replaces that prefix, and the
## Escape,<key> chords it served (Escape,b, Escape,d, ...) are all bound as
## Alt+<key> as well, so nothing is actually lost.
Set-PSReadLineKeyHandler -Chord 'Escape' -Function RevertLine

## Windows-style history recall on the function keys. PSReadLine defaults to
## Emacs edit mode everywhere except Windows, which leaves F8 unbound; in
## Windows mode it walks backward through the history entries that start with
## whatever is already typed (an empty buffer matches everything).
Set-PSReadLineKeyHandler -Chord 'F8' -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Chord 'Shift+F8' -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

## F7 is not a PSReadLine binding at all on Windows, it is the legacy console
## host's history popup, so it gets rebuilt here on top of fzf. Falls back to
## the F8 search when fzf is missing rather than swallowing the key.
Set-PSReadLineKeyHandler -Chord 'F7' -BriefDescription 'HistoryPopup' -LongDescription 'Pick a command out of history' -ScriptBlock {
    param($key, $arg)

    $fzf = Get-Command fzf -CommandType Application -ErrorAction Ignore | Select-Object -First 1
    if (-not $fzf)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward($key, $arg)
        return
    }

    $line = ''
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    ## fzf is line oriented, so multi-line entries cannot survive the round
    ## trip and are dropped. Newest first, and only the first occurrence of a
    ## repeated command is kept.
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $items = @(
        $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
        for ($i = $history.Count - 1; $i -ge 0; $i--)
        {
            $command = $history[$i].CommandLine
            if ($command -notmatch "`n" -and $seen.Add($command))
            {
                $command
            }
        }
    )

    if ($items.Count -eq 0)
    {
        return
    }

    ## --height keeps the list inline under the prompt the way the console
    ## host's popup sat over the buffer, instead of taking the whole screen.
    $choice = $items | & $fzf --no-sort --height 40% --layout reverse --prompt 'history> ' --query $line

    ## fzf leaves the cursor wherever it finished drawing, so the prompt and
    ## the buffer have to be painted again before either is touched.
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, $null)

    if ($choice)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $choice, $null, $null)
    }
}
