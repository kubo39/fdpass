# ipc

ipc is an implementation of file descriptor passing over Unix sockets on Linux.

## Tips

* Avoid the constrant of safe function (std.socket.Socket.send/receive), using `@trusetd` for `_send/_receive` in UnixSocket.
