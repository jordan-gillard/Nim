discard """
  matrix: "--mm:refc; --mm:orc"
  disabled: windows
"""

# Test Posix interface

when not defined(windows):

  import posix
  import std/[assertions, syncio]

  var
    u: Utsname

  discard uname(u)

  writeLine(stdout, u.sysname)
  writeLine(stdout, u.nodename)
  writeLine(stdout, u.release)
  writeLine(stdout, u.machine)

  when not (defined(nintendoswitch) or defined(macos) or defined(macosx)):
    block:
      type Message = object
        value: int

      const MQ_PATH: cstring = "/top_level_file"
      const MQ_PRIORITY: cuint = 170
      const MQ_MESSAGE_SIZE: csize_t = csize_t(sizeof(Message))

      let mqd_a: posix.MqAttr = MqAttr(mq_maxmsg: 10, mq_msgsize: clong(MQ_MESSAGE_SIZE))
      let writable: posix.Mqd = posix.mq_open(
        MQ_PATH,
        posix.O_CREAT or posix.O_WRONLY or posix.O_NONBLOCK,
        posix.S_IRWXU,
        addr(mqd_a)
      )
      let readable: posix.Mqd = posix.mq_open(
        MQ_PATH,
        posix.O_RDONLY or posix.O_NONBLOCK,
        posix.S_IRWXU,
        addr(mqd_a)
      )

      let sent: Message = Message(value: 88)
      block:
        let success: int = writable.mq_send(
          cast[cstring](sent.addr),
          MQ_MESSAGE_SIZE,
          MQ_PRIORITY
        )
        doAssert success == 0, $success

      block:
        var buffer: Message
        var priority: cuint
        let bytesRead: int = readable.mq_receive(
          cast[cstring](buffer.addr),
          MQ_MESSAGE_SIZE,
          priority
        )
        doAssert buffer == sent
        doAssert bytesRead == int(MQ_MESSAGE_SIZE)
