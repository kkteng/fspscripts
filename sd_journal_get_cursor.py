#!/usr/bin/python
# SCRIPT NAME		: sd_journal_get_cursor.py
# DESCRIPTION		: to fix the bug causing by rsyslog version v8.24.0-34.el7, see https://access.redhat.com/solutions/3925511 
# USE CASE NAME		: Use case for UC023-event
# Script version	: 1 .0
# Author 		: Teng, Kong_Keong

import os
import sys 
import platform


# Check supported OS
def check_ostype(os_type):
    if os_type in ['Linux','linux']:
        print "" + str(os_type) + " is supported"
	print
    else:
        print "The OS type : " + str(os_type) + " is not supported"
        exit(1)


# To validate the affected rsyslog version 
def validate_rsyslog_version():
    COMMAND=r"/usr/bin/rpm -qa | grep 'rsyslog'"
    STATUS=r"rsyslog-8.24.0-3.16.1.x86_64"
    result=""

    result = os.popen(COMMAND).read()
    if STATUS in result :
	print "This rsyslog version " + str(STATUS) + " is having bug, modify /etc/rsyslog.conf to fix the problem."
 	print
    else :
	print "The rsyslog version is not affected, exiting...."
	sys.exit(1)

# To check the rsyslog status 
def check_rsyslog_status():
#    chk_rsyslog_cmd = "/usr/bin/systemctl status ntpd | grep active | grep running | wc -l" 
#    chk_rsyslog_cmd = "/usr/bin/systemctl status rsyslog | grep active | grep running | wc -l" 
#    chk_rsyslog_result = os.popen(chk_rsyslog_cmd).read()
    chk_rsyslog_result = os.system("/usr/bin/systemctl status rsyslog")
    if  chk_rsyslog_result == 0:
	print "Rsyslog daemon is running..."
    else :
	print
	print "Service is not runnning, restarting rsyslog daemon." 


def restart_rsyslog():
    print
    print "#########  restarting rsyslogd, the process ID is running diffrently now. ########"
    chk_rsyslog_result = os.system("/usr/bin/systemctl stop rsyslog")
    # Check if rsyslog running in new process ID
    os.system("sleep 3")	
    check_rsyslog_status()


def check_file_availability(file):
    print
    chk_file = os.path.isfile(file)
    if chk_file:
   	 print "File " + file + " is available."
    else:
   	 print "File not found."
   	 sys.exit(1)


def search_replace_string(file):
    file_in = file
    file_out = "/tmp/rsyslog.conf_new"
    with open(file_in, "r") as fin:
        with open(file_out, "w") as fout:
            for line in fin:
                fout.write(line.replace('$ModLoad imuxsock.so', '### $ModLoad imuxsock.so'))
    #os.rename(file_out, file_in)



##############################################
#	MAIN
##############################################

print
print "#######################################################################"

os_type = platform.system()
os_version = platform.release()
chkfile = "/tmp/rsyslog.conf"
os_alias = platform.system_alias()

check_ostype(os_type)
validate_rsyslog_version()
check_rsyslog_status()
check_file_availability(chkfile)
search_replace_string(chkfile)
#restart_rsyslog()

print "#######################################################################"
