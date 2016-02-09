# fdpass [![Build Status](https://secure.travis-ci.org/kubo39/fdpass.png?branch=master)](http://travis-ci.org/kubo39/fdpass)

fdpass is an implementation of file descriptor passing over Unix sockets on Linux.

## Tips

* Avoid the constrant of safe function (std.socket.Socket.send/receive), using `@trusetd` for `_send/_receive` in UnixSocket.
