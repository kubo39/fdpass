module ipc;

version(linux)
{
  private import core.sys.posix.sys.socket;
  private import core.stdc.string : memcpy;

  import std.socket : Socket,
    socket_t,
    SocketFlags,
    AddressFamily,
    SocketType,
    ProtocolType,
    SocketOSException;

  class UnixSocket : Socket
  {
    this(SocketType socketType)
    {
      super(AddressFamily.UNIX, socketType, ProtocolType.IP);
    }

    this(socket_t sock)
    {
      super(sock, AddressFamily.UNIX);
    }

    ptrdiff_t _send(const(void)[] buf, SocketFlags flags) @trusted
    {
      msghdr msg;
      iovec iov;
      cmsghdr cmsg;

      iov.iov_base = cast(void*)buf;
      iov.iov_len = buf.length;

      msg.msg_name = null;
      msg.msg_namelen = 0;
      msg.msg_control = &cmsg;
      msg.msg_controllen = cast(socklen_t)CMSG_LEN(int.sizeof);
      msg.msg_iov = &iov;
      msg.msg_iovlen = 1;
      msg.msg_flags = 0;

      cmsg.cmsg_level = SOL_SOCKET;
      cmsg.cmsg_type = SCM_RIGHTS;
      cmsg.cmsg_len = CMSG_LEN(int.sizeof);

      socket_t fd = this.handle(); /* access to sock. */
      memcpy(CMSG_DATA(&cmsg), cast(void*)&fd, int.sizeof);

      return sendmsg(fd, &msg, 0);
    }

    override ptrdiff_t send(const(void)[] buf, SocketFlags flags)
    {
      return _send(buf, flags);
    }

    override ptrdiff_t send(const(void)[] buf)
    {
      return send(buf, SocketFlags.NONE);
    }

    ptrdiff_t _receive(void[] buf, SocketFlags flags) @trusted
    {
      msghdr msg;
      iovec iov;
      cmsghdr cmsg;

      iov.iov_base = cast(void*)buf;
      iov.iov_len = buf.length;

      msg.msg_name = null;
      msg.msg_namelen = 0;
      msg.msg_control = &cmsg;
      msg.msg_controllen = cast(socklen_t)CMSG_LEN(int.sizeof);
      msg.msg_iov = &iov;
      msg.msg_iovlen = 1;
      msg.msg_flags = 0;

      cmsg.cmsg_level = SOL_SOCKET;
      cmsg.cmsg_type = SCM_RIGHTS;
      cmsg.cmsg_len = CMSG_LEN(int.sizeof);

      int fd = -1;
      memcpy(CMSG_DATA(&cmsg), cast(void*)&fd, int.sizeof);

      return recvmsg(this.handle() /* access to sock. */, &msg, 0);
    }

    override ptrdiff_t receive(void[] buf, SocketFlags flags)
    {
      return _receive(buf, flags);
    }

    override ptrdiff_t receive(void[] buf)
    {
      return receive(buf, SocketFlags.NONE);
    }
  }

  UnixSocket[2] socketPair()
  {
    int[2] socks;
    if (socketpair(AF_UNIX, SOCK_SEQPACKET, 0, socks) == -1) {
      throw new SocketOSException("Unable to create socket pair");
    }

    UnixSocket toUnixSocket(size_t id)
    {
      return new UnixSocket(cast(socket_t)socks[id]);
    }

    return [toUnixSocket(0), toUnixSocket(1)];
  }

  unittest
  {
    immutable ubyte[] data = [1, 2, 3, 4];
    UnixSocket[2] pair = socketPair();
    scope(exit) foreach (s; pair) s.close();

    pair[0].send(data);

    auto buf = new ubyte[data.length];
    pair[1].receive(buf);

    assert(buf == data);
  }
}
else {
  static assert(false);  // currently not supported other platform.
}
