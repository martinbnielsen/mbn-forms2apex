import ConfigParser
import StringIO
import os

# read flyway configuration
with open('flyway.conf') as file:
    props = dict(line.strip().split('=', 1) for line in file)

print props['flyway.url']

# Flyway clean
os.system('flyway clean')

# Install
os.system('flyway migrate')

# Install logger
os.system('cd tools/logger_3.0.0; echo exit | sql ' + props['flyway.user'] + '/' + props['flyway.password'] + '@' + props['flyway.url'] + ' @logger_install')

