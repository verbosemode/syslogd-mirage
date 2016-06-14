# Syslog daemon for MirageOS

... at least it should become one some day

# Installation
	# Pin and Install syslog-message
	opam update
	opam install syslog-message
	
	# Generate build files
	mirage configure --unix --net=socket --port=5514
	# IF --net=socket is broken with opam upgrading
	# OR you don't want to reinstall everytime you build, use:
	mirage configure --unix --net=socket --port=5514 --no-opam

	
	# Make and run! See testing for seeing printed messages to console.
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
