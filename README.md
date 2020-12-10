# moz_bookmarks.tcl

create bookmarks.html from firefox's places.sqlite

## requirements

-   [tcl](http://www.tcl-lang.org/)
-   [sqlite3 tcl interface](https://sqlite.org/tclsqlite.html)

## usage

```
$ tclsh moz_bookmarks.tcl /where/to/places.sqlite > bookmarks.html
```

or

```
$ ./moz_bookmarks.tcl /where/to/places.sqlite > bookmarks.html
```

## issue

- emoji are not supported
  - tcl do not support emoji by default. see: <https://wiki.tcl-lang.org/page/emoji>
- &lt;DD&gt; (description) elements are not exported
- LAST_CHARSET= attributes are not exported
