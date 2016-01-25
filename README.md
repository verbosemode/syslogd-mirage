# Syslog daemon for MirageOS

... at least it should become one some day

The ports is hardcoded to 5514 at the moment to not interfere with local running syslog daemons.

# Installation

	opam pin add syslog-message https://github.com/verbosemode/syslog-message
	env NET=socket mirage configure --unix
	make
	./main.native

# Testing

	$ logger --port 5514 --server 127.0.0.1 -p mail.emerg -t server001 "foobar"

	or

	$ logger --port 5514 --rfc3164 --server 127.0.0.1 -p mail.emerg -t server001 "foobar"

# TODO

* Allow to configure port number via environment variable
* Store messages
  - Append to file?
  - Irmin?
* Src IP ACL?
* Support for TCP and TLS
