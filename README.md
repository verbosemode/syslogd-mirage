# Syslog daemon for MirageOS

... at least it should become one some day

# Installation
	# You need the latest Decompress version from git
	opam pin add decompress https://github.com/oklm-wsh/Decompress.git -y
	
	# Pin and Install syslog-message
	opam pin add syslog-message https://github.com/verbosemode/syslog-message.git -y
	
	# Generate build files 
	# If --net=socket is broken with opam upgrading, 
	# or you don't want to reinstall everytime you build, use:
	# --no-opam flag with
	mirage configure --unix --net=socket --port=5514
	
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
