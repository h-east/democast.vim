vim9script
# democast.vim: record a Vim session as a GIF, with the keys drawn on it.
# Maintainer: Hirohito Higashi
# License: MIT, see the LICENSE file.

if exists('g:loaded_democast')
  finish
endif
g:loaded_democast = 1

command! -bar DemocastPlay democast#Play()
