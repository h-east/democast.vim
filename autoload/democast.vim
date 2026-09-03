vim9script
# Plays a demo in this Vim and writes down what was pressed and when, so the
# keys can be drawn over the GIF afterwards.
#
# The keys are fed from a timer rather than from a script body: a script does
# not read the typeahead while it runs, so Insert mode would end at every step
# and a completion menu would never be on screen.

# How long between the characters of something that is typed out, in ms.
const TYPE_MS = 100
const SLOW_MS = 400

# A mark the terminal ignores, so the overlay can line its times up with the
# recording rather than guessing how long Vim took to start.
const MARK = "\<Esc>]1337;DEMOCAST\<Esc>\\"

def Setting(name: string, fallback: any): any
  return get(g:, 'democast', {})->get(name, fallback)
enddef

# Spell the typed steps out, one character at a time, so the label grows the
# way the text does.  Only what is typed is split up: a mapping of more than
# one key, "gd" among them, does not answer to its keys arriving apart.
def Spelled(steps: list<list<any>>): list<list<any>>
  var out: list<list<any>> = []
  var typed = ''
  for [kind, payload, label, wait] in steps
    var last = strchars(payload) - 1
    # The <CR> that ends a typed line is named after the line it ends.
    if label ==# '↩'
      add(out, [kind, payload, typed .. '↩', wait])
      continue
    endif
    if (kind !=# 'type' && kind !=# 'slow') || last < 0
      add(out, [kind, payload, label, wait])
      continue
    endif
    typed = payload
    var gap = kind ==# 'slow' ? SLOW_MS : TYPE_MS
    var sofar = ''
    for i in range(last + 1)
      var ch = strcharpart(payload, i, 1)
      sofar ..= ch
      add(out, ['keys', ch, sofar, i == last ? wait : gap])
    endfor
  endfor
  return out
enddef

var play: list<list<any>> = []
var step = 0
var started: list<any> = []
var log: list<string> = []

def Next(_: number)
  if step >= len(play)
    # The recording script says where they go; a run by hand falls back.
    var where = $DEMOCAST_LABELS
    if where->empty()
      where = Setting('labels', 'democast-labels.tsv')
    endif
    writefile(log, where)
    execute 'qa!'
    return
  endif
  var [kind, payload, label, wait] = play[step]
  ++step
  # When each label goes up and comes down, for the overlay drawn on the GIF.
  var at = reltime(started)->reltimefloat()
  add(log, printf("%.2f\t%.2f\t%s", at, at + wait / 1000.0, label))
  if kind ==# 'cmd'
    execute payload
  elseif !payload->empty()
    feedkeys(payload, 't')
  endif
  timer_start(wait, Next)
enddef

# Play what "steps" in g:democast says, then leave.
export def Play()
  var steps = Setting('steps', [])
  if steps->empty()
    echomsg 'democast: nothing to play; see :help democast'
    return
  endif
  # A clean screen: what is recorded should be the demo, not the setup.
  set laststatus=2 noruler noshowcmd shortmess+=IFA
  # The file opens wherever it was left, so a search has to be able to wrap.
  set wrapscan
  # A jump to another file while this one is changed needs somewhere to put
  # it; the demo is thrown away at the end either way.
  set hidden
  # The top, wherever the file was last left, so a demo plays the same way
  # every time.
  cursor(1, 1)
  for line in Setting('before', [])
    execute line
  endfor

  play = Spelled(steps)
  step = 0
  log = []
  echoraw(MARK)
  started = reltime()
  timer_start(Setting('start_delay', 600), Next)
enddef
