#!/usr/bin/env python
import time
from datetime import datetime, timedelta
import sys

if ((len(sys.argv) > 1 )):
    print """\
This script does not require to enter any argument.
"""
    sys.exit(1)
#print "today date is : ", time.strftime("%d")
t_date = int(time.strftime("%d"))
t_month = int(time.strftime("%m"))

deploy = datetime(2019, t_month, t_date, 12, 0) # assume local time
cur_time = datetime.now()
#timestamp = time.mktime(deploy.timetuple()) # may fail, see the link below
#deploy_utc = datetime.utcfromtimestamp(timestamp)
elapsed = deploy - datetime.now() # `deploy` is in the future

#print "Target  time :", deploy
#print "Current time :", cur_time
#print
print "elapsed :", elapsed

#print "Total second left : ", elapsed.days*86400 + elapsed.seconds

#print "elapsed.days", elapsed.days
#print "elapsed.hours", elapsed.hours


seconds = elapsed.days*86400 + elapsed.seconds # drop microseconds
minutes, seconds = divmod(seconds, 60)
hours, minutes = divmod(minutes, 60)


minl = hours*60 + minutes
print "Minute left is : ", minl


pgl = int(input("How many pages left : "))
#pgl = int(input("How many chapters left : "))
#minl = int(input("How many minutes left :"))

print "Average pages per minute is :",float(pgl)/float(minl)
#print "Average  minutes per chapter is :",float(minl)/float(pgl)
