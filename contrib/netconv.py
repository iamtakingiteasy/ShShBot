#!/usr/bin/python

from select import select
from socket import socket
from time import sleep, ctime
import sys,os

def wait_for_line_and_possibly_send(conn, dec, enc, target):
    string = ""
    rlist, wlist, xlist = select([conn], [], [conn], 0.01)
    if (len(xlist) > 0):
        return -1
    if (len(rlist) > 0):
        while True:
            recvbyte = conn.recv(1)
            if (recvbyte == ""):
                if (string == ""):
                    return -1
                break
            string += recvbyte
            if (len(string) > 0 and string[-1] == "\n"):
                break
    else:
        return 0
    try:
        encstring = string.decode(dec).encode(enc) 
    except:
        encstring = string
    try:
        target.send(encstring)
    except:
        return -1
    return len(encstring)


def update_status(recv_count, send_count):
    sys.stdout.write(chr(13))
    sys.stdout.write("%s :: %s :: %d <=> %d\n"%(ctime(), os.getpid(),
                                                recv_count, send_count))

if (len(sys.argv) != 7):
    print "USAGE: " + sys.argv[0] + \
        " bind-addr bind-port here-coding " + \
        "remote-addr remote-port remote-coding"
    sys.exit(1)

bindsock = socket()
while True:
    try:
        bindsock.bind((sys.argv[1], int(sys.argv[2])))
        break
    except:
        print "bind failed, retrying..."
        sleep(1)
bindsock.listen(1)

while True:
    print "ok, awaiting for connections"
    conn1, addr = bindsock.accept()
    print "accepted connection from addr", addr
    if (os.fork() == 0):
        conn1.settimeout(30)
        conn2 = socket()
        conn2.settimeout(30)
        r = conn2.connect_ex((sys.argv[4], int(sys.argv[5])))
        recv_count = 0
        send_count = 0
        if (r == 0):
            while True:
                r = wait_for_line_and_possibly_send(
                    conn1, sys.argv[3], sys.argv[6], conn2)
                if (r == -1):
                    break
                else:
                    send_count += r
                    if (r > 0):
                        update_status(recv_count, send_count)
                    r = wait_for_line_and_possibly_send(
                        conn2, sys.argv[6], sys.argv[3], conn1)
                    if (r == -1):
                        break
                    else:
                        recv_count += r
                    if (r > 0):
                        update_status(recv_count, send_count)
            sys.stdout.write("%s :: %s :: connection closed\n"%(ctime(), 
                                                                os.getpid()))
            conn2.close()
            conn1.close()
            sys.exit(0)

