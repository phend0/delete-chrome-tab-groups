-- delete_saved_tab_groups.applescript
-- Bulk-deletes Chrome saved tab groups via  ⋮ > Tab groups > <group> > Delete group.
-- Only groups marked "Closed" are deleted; currently open groups are left alone
-- (deleting them would close their tabs).
--
-- Usage:   osascript delete_saved_tab_groups.applescript [maxToDelete]
--          (no argument = delete all closed saved groups)
-- Requires: System Settings > Privacy & Security > Accessibility enabled for the
--           app running this (Terminal, Antigravity, ...). Don't use the mouse/keyboard
--           while it runs. Press Ctrl+C in the terminal to stop.

property kDown : 125
property kRight : 124
property kReturn : 36
property kEsc : 53

on menuOf(w)
	tell application "System Events" to return menu 1 of group 1 of group 1 of group 1 of w
end menuOf

-- name of the selected item among the first n items of the top-most menu
on selectedName(n)
	tell application "System Events" to tell process "Google Chrome"
		set m to my menuOf(window 1)
		set items_ to menu items of m
		if n > (count of items_) then set n to count of items_
		repeat with i from 1 to n
			try
				if selected of (item i of items_) then return name of (item i of items_) as text
			end try
		end repeat
	end tell
	return ""
end selectedName

on closeMenus()
	tell application "System Events" to tell process "Google Chrome"
		repeat 4 times
			if (count of windows) ≤ 1 then exit repeat
			key code kEsc
			delay 0.25
		end repeat
	end tell
end closeMenus

-- Opens ⋮ > Tab groups submenu. Returns true on success.
on openTabGroupsMenu()
	tell application "System Events" to tell process "Google Chrome"
		set mainWin to (first window whose subrole is "AXStandardWindow")
		set btn to first pop up button of toolbar 1 of group 1 of group 1 of group 1 of group 1 of group 1 of mainWin whose description is "Chrome"
		click btn
		delay 0.8
		set m to my menuOf(window 1)
		set names_ to name of menu items of m
		-- walk down with the keyboard until "Tab groups" is highlighted
		repeat with i from 1 to (count of names_)
			key code kDown
			delay 0.08
			if (selected of menu item "Tab groups" of m) then exit repeat
		end repeat
		if not (selected of menu item "Tab groups" of m) then return false
		key code kRight
		delay 0.8
		return true
	end tell
end openTabGroupsMenu

-- Deletes the first closed saved group. Returns its label, or "" if none left.
on deleteFirstClosedGroup()
	if not my openTabGroupsMenu() then error "Could not open the Tab groups menu"
	tell application "System Events" to tell process "Google Chrome"
		set target to ""
		-- highlight the first item whose label ends with "group - Closed"
		repeat 12 times
			set s to my selectedName(12)
			if s ends with "group - Closed" then
				set target to s
				exit repeat
			end if
			key code kDown
			delay 0.1
		end repeat
		if target is "" then
			my closeMenus()
			return ""
		end if
		key code kRight -- open the group's submenu
		delay 0.6
		set ok to false
		repeat 8 times
			if my selectedName(8) is "Delete group" then
				set ok to true
				exit repeat
			end if
			key code kDown
			delay 0.1
		end repeat
		if not ok then
			my closeMenus()
			error "Could not find 'Delete group' for " & target
		end if
		key code kReturn
		delay 0.6
		my closeMenus()
		return target
	end tell
end deleteFirstClosedGroup

on run argv
	set maxCount to 100000
	if (count of argv) > 0 then set maxCount to (item 1 of argv) as integer
	tell application "Google Chrome" to activate
	delay 0.5
	tell application "System Events" to set frontmost of process "Google Chrome" to true
	set deleted to 0
	set failures to 0
	repeat while deleted < maxCount
		try
			set g to my deleteFirstClosedGroup()
			if g is "" then exit repeat
			set deleted to deleted + 1
			log "Deleted #" & deleted & ": " & g
			set failures to 0
		on error e
			set failures to failures + 1
			log "Retry after error: " & e
			my closeMenus()
			delay 1
			if failures ≥ 3 then exit repeat
		end try
	end repeat
	return "Done. Deleted " & deleted & " saved tab group(s)."
end run
