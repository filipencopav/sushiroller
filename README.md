# sushiroller

This is an s-expression to HTML templating engine written in common lisp.

The `sushiroller:sushiroller` readtable uses the `@` character as a subchar
for the `#` dispatch macro character. Merges with the standard readtable.

`sushiroller:roll` names the function that the reader invokes when it hits
`#@`. You may want to bind it to something else, so I exported it to make
that easier.

## License

BSD 3-Clause

