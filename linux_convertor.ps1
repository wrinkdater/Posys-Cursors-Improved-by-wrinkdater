$target_input = $args[0]

$search_pattern = if ($target_input) { "windows/$target_input/*.cur", "windows/$target_input/*.ani" }
					else { "windows/*/*.cur", "windows/*/*.ani" }

if ($target_input -and -not (test-path "windows/$target_input")) {
	write-error "folder not found: windows/$target_input"
	exit 1
}

function update_filename([string]$new_name, [string]$original_path, [string[]]$links) {

		$parent = $(split-path $original_path -parent)
		if (test-path $(join-path $parent $new_name)) { return }

        $parent_dir = split-path -parent $original_path
		rename-item -path $original_path -newname $new_name -force
        
        $original_location = get-location
        set-location $parent_dir
		foreach ($item in $links) { ln -sf $new_name $item }
        set-location $original_location
}

$conversions = @("context-menu", "left_ptr_watch", "xterm", "left_ptr", "crossed_circle", "hand2", "question_arrow",
"fleur", "pencil", "alias", "pin", "crosshair", "sb_h_double_arrow", "sb_v_double_arrow", "size_bdiag",
"size_fdiag", "watch")

foreach ($item in $search_pattern) {
	get-childitem $item | foreach-object {
		$root = (get-item "windows").parent.fullname
		$relative = $_.directoryname.replace($root, "").replace("windows", "linux").replace(" ", "_").tolower() + "/cursors"
		$new_dir = join-path $root $relative

		$target_file = join-path $new_dir $_.name.tolower().replace(" ", "_")

		$already_done = false
		foreach ($item in $conversions) {
			if (test-path $(join-path $new_dir $item)) {
				$already_done = true; break;
				"File exists"
			}
		}
		if ($already_done) { return }

		"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
		"Checking if folder exists: $new_dir"
		if (-not (test-path $new_dir)) {
			new-item -itemtype directory -path $new_dir -force | out-null
			"created: $new_dir"

			# INDEX.THEME GENERATION START
				$theme_folder = split-path (split-path $new_dir -parent) -leaf
				$theme_path   = join-path (split-path $new_dir -parent) "index.theme"

				$theme_content = "" +
				"[Icon Theme]`n"       +
				"Name=$theme_folder`n" +
				"Inherits=Adwaita"

				$theme_content | set-content -path $theme_path
				"created index.theme for: $theme_folder"
			# INDEX.THEME GENERATION END

		} else { "Folder already exists" }

		"`nPerforming Conversion:"
		"OLD: {0}`nNEW: {1}" -f $_, $target_file
		& win2xcur $_.fullname -o $new_dir
	}
}

"`nchanging names to linux conventions"
$rename_path = if ($target_input) { join-path "linux" $($target_input.replace(" ", "_").tolower()) "cursors" }
				else { join-path "linux" "*" "cursors" }

get-childitem $rename_path | foreach-object {
	get-childitem $_ -file | foreach-object {
		if ($_.name -match "context-menu|left_ptr_watch|xterm|left_ptr|crossed_circle|hand2|question_arrow|fleur|pencil|alias|crosshair|sb_h_double_arrow|sb_v_double_arrow|size_bdiag|size_fdiag|watch") {
			return
		}

		$new_name = ""
		$symlinks = @()
		if ($_.name.tolower() -like "*alt*") {
			$new_name = "context-menu"
            $symlinks = @("menu", "right_ptr")

		} elseif ($_.name.tolower() -like "*background max*") {
			$new_name = "left_ptr_watch"
            $symlinks = @("progress", "3ECB610", "half-busy")

		} elseif ($_.name.tolower() -like "*beam*") {
			$new_name = "xterm"
            $symlinks = @("text", "ibeam", "v_beam")

		} elseif ($_.name.tolower() -like "*cursor*") {
			$new_name = "left_ptr"
            $symlinks = @("default", "arrow", "top_left_arrow")

		} elseif ($_.name.tolower() -like "*forbidden*") {
			$new_name = "crossed_circle"
            $symlinks = @("not-allowed", "03B6E0F")

		} elseif ($_.name.tolower() -like "*hand*") {
			$new_name = "hand2"
            $symlinks = @("hand1", "pointer", "pointing_hand")

		} elseif ($_.name.tolower() -like "*help*") {
			$new_name = "question_arrow"
            $symlinks = @("help", "whats_this", "D965494")

		} elseif ($_.name.tolower() -like "*move*") {
			$new_name = "fleur"
            $symlinks = @("move", "all-scroll", "4498F0E")

		} elseif ($_.name.tolower() -like "*pen*") {
			$new_name = "pencil"
            $symlinks = @("draft", "stylus")

		} elseif ($_.name.tolower() -like "*person*") {
			$new_name = "alias"
            $symlinks = @("link", "3085A0E")

		} elseif ($_.name.tolower() -like "*pin*") {
			$new_name = "pin"
            $symlinks = @("waypoint")

		} elseif ($_.name.tolower() -like "*precise*") {
			$new_name = "crosshair"
            $symlinks = @("cross", "tcross", "precise")

		} elseif ($_.name.tolower() -like "*ew*") {
			$new_name = "sb_h_double_arrow"
            $symlinks = @("e-resize", "w-resize", "h_double_arrow", "ew-resize", "0280060")

		} elseif ($_.name.tolower() -like "*ns*") {
			$new_name = "sb_v_double_arrow"
            $symlinks = @("n-resize", "s-resize", "v_double_arrow", "ew-resize")

		} elseif ($_.name.tolower() -like "*nesw*") {
			$new_name = "size_bdiag"
            $symlinks = @("ne-resize", "sw-resize", "nesw-resize", "FCF1C00")

		} elseif ($_.name.tolower() -like "*nwse*") {
			$new_name = "size_fdiag"
            $symlinks = @("nw-resize", "se-resize", "nwse-resize", "C7088F0")

		} elseif ($_.name.tolower() -like "*wait max*") {
			$new_name = "watch"
            $symlinks = @("wait", "0426C0D")
		}

		if ($new_name -ne "") {
			$leaf   = split-path $_ -leaf
			$parent = split-path (split-path $_ -parent) -leaf
			$result = join-path $parent $leaf

			"updating filename: {0,-65} -> {1}" -f $result, $new_name
			 update_filename $new_name $_.fullname $symlinks
		}
	}
}
