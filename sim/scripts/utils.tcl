
# findFiles
# https://stackoverflow.com/questions/429386/tcl-recursively-search-subdirectories-to-source-all-tcl-files/435094#435094
# basedir - the directory to start looking in
# pattern - A pattern, as defined by the glob command, that the files must match
proc findFiles { basedir pattern } {

	# Fix the directory name, this ensures the directory name is in the
	# native format for the platform and contains a final directory seperator
	set basedir [string trimright [file join [file normalize $basedir] { }]]
	set fileList {}

	# Look in the current directory for matching files, -type {f r}
	# means ony readable normal files are looked at, -nocomplain stops
	# an error being thrown if the returned list is empty
	foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
	    lappend fileList $fileName
	}

	# Now look for any sub direcories in the current directory
	foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
	    # Recusively call the routine on the sub directory and append any
	    # new files to the results
	    set subDirList [findFiles $dirName $pattern]
	    if { [llength $subDirList] > 0 } {
	        foreach subDirFile $subDirList {
	            lappend fileList $subDirFile
	        }
	    }
	}
	return $fileList
}