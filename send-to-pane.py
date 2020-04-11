#!/usr/bin/env python3

import socket
import argparse
import re
import subprocess
import time


def sendtmuxstring(data, target):
    subprocess.run(["tmux", "send-keys", "-t", target, data])


def run_server(HOST, PORT, target):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        print("bound to", HOST, "at", PORT)
        s.listen(1)
        conn, addr = s.accept()
        with conn as c:
            print("Socket opened")
            while True:
                data = c.recv(4096).decode()
                if not data: break
                sendtmuxstring(data, target)


def get_target():
    subprocess.run(["tmux", "set-environment", "-u", "vimtarget"])
    subprocess.run(["tmux", "choose-tree", "set-environment vimtarget '%%'"])
    msg = subprocess.run(["tmux", "show-environment",  "vimtarget"],
                         capture_output = True)
    while (msg.stdout == b''):
        time.sleep(1)
        msg = subprocess.run(["tmux", "show-environment",  "vimtarget"],
                         capture_output = True)
    target = msg.stdout.decode()
    pattern = "(?<==).*?(?=\n)"
    prog = re.compile(pattern)
    return prog.search(target).group()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="send-to-pane",
                                     description="Start a server to send received commands to a specified tmux pane",
                                     formatter_class=argparse.RawDescriptionHelpFormatter,
                                     epilog="Start from vim with the vim plugin send-to-pane. Example command line usage:\n\tsend-to-pane -t =0:0.%1\n\tsend-to-pane -t .%5\n\tsend-to-pane -t =sessionname:.%4")
    parser.add_argument('-n', '--hostname', default='',
                        help="Server hostname. Defaults to localhost if unspecified.")
    parser.add_argument('-p', '--port', default='7654',
                        help="Server port. Defaults to 7654.", type=int)
    parser.add_argument('-t', '--target', default='interactive',
                        help="Tmux pane target, of the standard form. Defaults to interactive pane choice if unspecified.")
    args = parser.parse_args()
    if args.target == "interactive":
        args.target = get_target()

    run_server(args.hostname, args.port, args.target)
