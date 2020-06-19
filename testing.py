#!/usr/bin/python



import os
import sys
import platform

os_alias = platform.system_alias()

os_type = platform.system()
os_version = platform.release()

print os_alias
print os_type
print os_version
