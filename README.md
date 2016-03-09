# Syslog daemon for MirageOS

... at least it should become one some day

# Installation

	opam pin add syslog-message https://github.com/verbosemode/syslog-message
	mirage configure --unix --net=socket --port=5514
	make
	./main.native

# Testing

	$ logger --port 5514 --server 127.0.0.1 -p mail.emerg -t server001 "foobar"

	or

	$ logger --port 5514 --rfc3164 --server 127.0.0.1 -p mail.emerg -t server001 "foobar"

# TODO

* Store messages
  - Append to file?
  - Irmin?
* Src IP ACL?
* Support for TCP and TLS
