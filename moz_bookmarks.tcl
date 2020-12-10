#!/usr/bin/tclsh

package require sqlite3

# show usage
set db_filename [lindex $argv 0]
if {$db_filename eq ""} {
	puts "usage: $argv0 <places.sqlite>"
	exit
}

# open sqlite database
sqlite3 db1 $db_filename -readonly 1

# encode &'"<> in str
proc encode_title {str} {
	return [string map {& &amp; ' &#39; \" &quot; < &lt; > &gt;} $str]
}

# puts moz_bookmarks.id information recursively
# id: moz_bookmarks.id
# deep: recursion count, used of indentation
proc print_bookmark {id deep} {
	# LEFT JOIN: moz_bookmarks as b, moz_places as h, moz_keywords as k
	# condition: k.fk = h.id = k.place_id
	db1 eval "SELECT h.id, b.dateAdded, b.lastModified, b.type, b.title, h.url, k.keyword, k.post_data, b.guid
	FROM moz_bookmarks AS b
	LEFT JOIN moz_places AS h ON b.fk = h.id
	LEFT JOIN moz_keywords AS k ON  h.id = k.place_id
	WHERE b.id = $id" v_bhk {
		#parray v_bhk

		# ADD_DATE, LAST_MODIFIED; adjust to bookmarks.html
		set add_date [expr $v_bhk(dateAdded) / 1000000]
		set last_modified [expr $v_bhk(lastModified) / 1000000]
		# moz_bookmarks.type
		#   1: bookmark, 2: folder, 3: separator
		if {$v_bhk(type) == 1} {
			# bookmark item
			# indent
			puts -nonewline [string repeat {    } $deep]
			# puts url, add date, last modified
			puts -nonewline "<DT><A HREF=\"$v_bhk(url)\" ADD_DATE=\"$add_date\" LAST_MODIFIED=\"$last_modified\""

			# puts bookmark keyword
			if {$v_bhk(keyword) != ""} {
				puts -nonewline " SHORTCUTURL=\"$v_bhk(keyword)\""
			}
			if {$v_bhk(post_data) != ""} {
				puts -nonewline " POST_DATA=\"[encode_title $v_bhk(post_data)]\""
			}
			# puts title
			puts ">[encode_title $v_bhk(title)]</A>"
		} elseif {$v_bhk(type) == 2} {
			# folder item
			if {$v_bhk(guid) == "menu________"} {
				# Bookmarks Menu special folder: don't print
				incr deep -1
			} else {
				# not a Bookmarks Menu folder
				# indent
				puts -nonewline [string repeat {    } $deep]
				# puts add date, laste modified
				puts -nonewline "<DT><H3 ADD_DATE=\"$add_date\" LAST_MODIFIED=\"$last_modified\""

				if {$v_bhk(guid) == "toolbar_____"} {
					# Bookmarks Toolbar special folder
					puts -nonewline { PERSONAL_TOOLBAR_FOLDER="true"}
				} elseif {$v_bhk(guid) == "unfiled_____"} {
					# Other Bookmarks special folder
					puts -nonewline { UNFILED_BOOKMARKS_FOLDER="true"}
				}
				# puts title
				puts ">$v_bhk(title)</H3>"
				# indent
				puts -nonewline [string repeat {    } $deep]
				puts "<DL><p>"
			}

			# search items which parent = id from moz_bookmarks
			db1 eval "SELECT id FROM moz_bookmarks WHERE parent = $id" bmk {
				# recursion
				print_bookmark $bmk(id) [expr $deep + 1]
			}

			# not a Bookmarks Menu folder, puts </DL><p>
			if {$v_bhk(guid) != "menu________"} {
				# indent
				puts -nonewline [string repeat {    } $deep]
				puts "</DL><p>"
			}
		} elseif {$v_bhk(type) == 3} {
			# separator item
			# indent
			puts -nonewline [string repeat {    } $deep]
			# puts separator
			puts -nonewline "<HR>"
		}

	}
}

# print header
puts "<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks Menu</H1>

<DL><p>"

# Bookmarks Menu
print_bookmark 2 1
# Bookmarks Toolbar
print_bookmark 3 1
# Other Bookmarks
print_bookmark 5 1

puts {</DL>}

db1 close
