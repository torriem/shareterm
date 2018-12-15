# Share a terminal with a remote user

## Consider using these instead
These scripts are nearly 10 years old and not actively maintained. They work
fine, but they aren't nearly as polished as a couple of tools currently being
offered:

- [tmate](https://tmate.io/) - an open source program and a free on-line
  service that does everything shareterm does and more, and way easier
- [teleconsole](https://www.teleconsole.com/) - very similar to tmate. Both an
  open source project and a free service to provide an easy connection.

## Why shareterm?
On several occasions I've wished for a way to share a terminal in a manner
similar to [vncviewer's ''--listen''
mode](http://www.tightvnc.com/vncviewer.1.php ).  shareterm is a set of scripts
that use [tmux](http://tmux.sourceforge.net/) and
[socat](http://www.dest-unreach.org/socat/) to do just that.  This has several
advantages over other methods of sharing a terminal (such as ssh and tunnelling
games):

 - remote host operator needs no login information
 - minimal software requirements
 - server (remote host receiving the terminal session) needs only python,
   [socat](http://www.dest-unreach.org/socat/), openssl, an ssl   key and
   cert
 - client (local host sending the terminal session) needs only bash,
   [socat](http://www.dest-unreach.org/socat/), openssl,
   [tmux](http://tmux.sourceforge.net/), and an optional certificate authority
   file.
 - Host sharing the terminal can be behind a firewall on a private network
 - Access to the shared terminal and the computers being worked on can be
   controlled and monitored by a local admin.

Before I created these scripts, if I needed to assist someone in managing their
linux machine I either had to grant them access to one of my computers, or have
them grant me access to their computer.  In many cases this is not always
desirable.  On several occasions I've seen folks on IRC tell others who are
having problems, "Just give me a login and I'll come in and fix it for you."
Hopefully no one has beent that gullible.  But with shareterm, someone could
assist another in a more secure manner without any passwords or logins being
shared.  Any passwords that are needed can be entered by the local user who is
sharing the terminal with the remote user.  And since everything is running
locally and only the "image" of the terminal is being shared, no passwords are
ever transmitted, encrypted or otherwise, across the wire.

## How does it work?
shareterm works by creating a tmux session, and then connecting the local
user's terminal to that session while simultaneously using socat to create a
local pty, connecting it to the tmux session, and then connecting the pty to a
remote host over an SSL socket.  Ahead of time on the remote host, the
shareterm-listen.py program is run which uses socat to listen for incoming SSL
connections on a port and then connect them to the terminal socat was running
in.

## Caveats
This works pretty well but has a couple of downsides and caveats.

 - both people connected to the shared tmux session have to have the same
   terminal type
 - the socat pty always defaults to 80x24, so that constrains the size of the
   shared terminal
 - the listening socket on the remote host rarely closes cleanly

## How to use
Using shareterm is very simple, although you will need an SSL key and
certificate (I use [[http://xca.sf.net/ | xca]] to generate and manage keys).
On the remote host you need to have socat installed, then just run the
shareterm-listen.py script:
<code>
shareterm-listen.py --key /path/to/key --cert /path/to/cert -p <port number>
</code>

The script will then wait for a successful SSL connection on that port, then it
will connect the socket directly to the terminal you ran the script in.  As
noted above, make sure the terminal is at least 80x24, as that's what the size
of the terminal being shared will be.

On the machine you want to share a terminal from, just run the shareterm.sh
script (provided you are using a self-signed key and don't want to verify it):
<code>
shareterm.sh -v <remotehost> <remoteport>
</code>
If you have a public CA certificate that was used to sign the SSL key used by
shareterm-listen.py, then you would leave off the ''-v'' flag and use the CA
cert:
<code>
shareterm.sh -c /path/to/cacert.crt <remotehost> <remoteport>
</code>

Once the terminal is shared, the local user and the remote user will both be
connected to the same tmux session.  Please see the tmux manual for the
keystrokes to operate tmux.  If you've ever used Screen before, the commands
are very similar, but tmux uses ^B as the default command key, rather than ^A.
tmux allows multiple screens (similar to virtual terminals) to be created, and
switch between them.  Both the local and remote user will always see the same
virtual screen, so if the local user switches to screen 1, the remote user will
be switched as well.

Note that there is absolutely no good reason for the shareterm-listen script to
be written in Python.  I mainly did it because there are slightly more command
line arguments available in that script and Python's optparse module beats
Bash's getopt by a large margin.  But in reality both scripts could have been
written in plain Bash (or even sh).

## ChangeLog
 - 2010-12-13  Michael Torrie  <torriem@gmail.com>
   - shareterm.sh: Finally fixed PSALL so it really works.  Before it always
     returned an error that was simply ignored.  Now it properly executes
     whatever is in PSALL.  Set version to 1.2 in shareterm.sh
 - 2010-06-12  Michael Torrie  <torriem@gmail.com>
   - shareterm.sh: Clean up old tmux clients still attached to our session
     before starting a new client to send to remote host
   - shareterm.sh: If local side disconnects while remote host still attached,
     give warning and option to reattach or terminate the session.
