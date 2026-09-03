# democast.vim

Record a Vim session as a GIF, with the keys drawn on it.

A demo of an editor is worth more as a picture than as a description, and a
picture of Vim is worth little if the keys that made it happen are not in it.
This plays a session you have written down, records it, and draws each key
over the GIF as it goes in.

The session is played from inside Vim, by a timer, which is what lets it wait
for something slow: a language server answering, a plugin drawing a popup.  A
tool that types at a terminal from the outside cannot know when that has
happened.

## Requirements

- Vim 9.1 or later, with `+timers` and `+eval`
- [asciinema](https://asciinema.org) 3, to record the terminal
- [agg](https://github.com/asciinema/agg), to turn the recording into a GIF
- ffmpeg with the `drawtext` filter, to draw the keys over it

## Installation

With a plugin manager, vim-plug for instance:

```vim
Plug 'h-east/democast.vim'
```

## Writing a demo

Put what to play in `democast.vim`, next to the project it is about:

```vim
vim9script

g:democast = {
  dir: expand('~/src/hello'),
  file: 'main.c',
  steps: [
    ['keys', '', '', 1500],		# let the server attach
    ['type', '/^main', '', 400],
    ['keys', "\<CR>", '↩', 1000],
    ['keys', 'o', 'o', 700],
    ['slow', 'str', '', 800],		# the menu narrows with each letter
    ['keys', "\<C-N>", '<C-N>', 2000],
    ['type', '(s);', '', 800],
    ['keys', "\<Esc>", '<Esc>', 500],
    ['keys', 'K', 'K', 2500],		# what the server knows about it
  ],
}
```

Each step is `[kind, keys, label, wait]`.

| kind | what it does |
| --- | --- |
| `keys` | Sends the keys at once.  A mapping of more than one key, `gd` among them, has to go this way. |
| `type` | Sends them a character at a time, 100ms apart, with the label growing as it goes. |
| `slow` | The same at 400ms, for where something is worth watching happen. |
| `cmd` | Runs an Ex command without it being seen, for what the demo needs but nobody would type. |

`wait` is how long to hold afterwards, in milliseconds; it is what gives an
answer time to arrive and the eye time to read it.  The label `↩` is written
out as the line it ends, so the `<CR>` after a command reads
`:LspReferences↩` rather than an arrow on its own.

`:DemocastPlay` plays it in the current Vim without recording, which is how
to see whether it does what you meant.

## Recording

Recording has to start outside Vim: asciinema is what runs Vim, so it cannot
be done from within the session being recorded.  Put the `bin` directory on
your `PATH`:

```sh
export PATH="$HOME/.vim/plugged/democast.vim/bin:$PATH"
```

Then:

```
democast
```

The GIF is left as `democast.gif` in the same directory.  `DEMOCAST_VIM`
names which Vim to record, `DEMOCAST_OUT` where the GIF goes.

Every key that can go in `g:democast`, and the rest of it, is under
`:help democast`.

## A note on the cursor

The cursor in the GIF is drawn by agg, which inverts the colors of the cell
it is on.  Neither the color your terminal draws the cursor in nor the one
`'guicursor'` names reaches the recording, so it will not match what you see
while recording.

## AI

This plugin is developed with the support of AI (Claude).

## License

MIT; see `LICENSE`.
