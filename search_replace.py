#!/usr/bin/python
import os    

file_in = "/tmp/rsyslog.conf"
file_out = "/tmp/rsyslog.conf_new"
with open(file_in, "r") as fin:
    with open(file_out, "w") as fout:
        for line in fin:
            fout.write(line.replace('$ModLoad imuxsock.so', '### $ModLoad imuxsock.so'))

#os.rename(file_out, file_in)
