#!/usr/bin/env tclsh
package require Tk

proc callwindowify {number} {
  font create AppHighlightFont -size 40 -weight bold
  grid [ttk::label .l -text "In Call with $number" -font AppHighlightFont]
  grid [ttk::button .button -text "Return to Call Menu (unwindowify)" -command exit]
}

callwindowify [lindex $argv 0]
