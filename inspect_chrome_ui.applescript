-- inspect_chrome_ui.applescript
-- Read-only helper: dumps Chrome's native (non-web) accessibility tree so the
-- delete script can target the right buttons/menus. Changes nothing.
-- Usage: osascript inspect_chrome_ui.applescript

on dumpEl(el, depth, maxDepth)
	set out to ""
	tell application "System Events"
		try
			set r to role of el
		on error
			set r to "?"
		end try
		if r is "AXWebArea" then return ""
		set n to ""
		set d to ""
		try
			set n to name of el as text
		end try
		try
			set d to description of el as text
		end try
		set pad to ""
		repeat depth times
			set pad to pad & "  "
		end repeat
		set out to pad & r & " | name=" & n & " | desc=" & d & linefeed
		if depth < maxDepth then
			try
				repeat with c in (UI elements of el)
					set out to out & my dumpEl(c, depth + 1, maxDepth)
				end repeat
			end try
		end if
	end tell
	return out
end dumpEl

tell application "Google Chrome" to activate
delay 0.5
tell application "System Events" to tell process "Google Chrome"
	set frontmost to true
	return my dumpEl(front window, 0, 9)
end tell
