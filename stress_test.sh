#!/bin/bash

##____________________________________________________________________________##
##----------------------------------------------------------------------------##
##    RPi Stress Test - Use sysbench to stress test the Raspberry Pi          ##
##                      while logging temperature and clock speed             ##
##    Copyright (C) 2019  voltavidTony                                        ##
##                                                                            ##
##    This program is free software: you can redistribute it and/or modify    ##
##    it under the terms of the GNU General Public License as published by    ##
##    the Free Software Foundation, either version 3 of the License, or       ##
##    (at your option) any later version.                                     ##
##                                                                            ##
##    This program is distributed in the hope that it will be useful,         ##
##    but WITHOUT ANY WARRANTY; without even the implied warranty of          ##
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           ##
##    GNU General Public License for more details.                            ##
##                                                                            ##
##    You should have received a copy of the GNU General Public License       ##
##    along with this program. If not, see <https://www.gnu.org/licenses/>    ##
##____________________________________________________________________________##
##----------------------------------------------------------------------------##

# Display command help when 0 stress tests are scheduled to run
if [ $# -eq 0 ]; then
    echo -e "Command usage: \e[93m./stress_test.sh \e[91m[\e[93mamount\e[91m] [\e[93minterval\e[91m]"
    echo "No arguments: Display this information"
    echo "Arguments:"
    echo "    <name>     <default>   <description>"
    echo "    amount   - 1         - Number of consecutive stress tests"
    echo "                            If 0, displays this information"
    echo "    interval - 5         - Time in seconds between temperature measurement"
    echo "                            If 0, measures once after each stress test"
    echo -e "\e[93mNote: \e[39mArguments are stripped of any non-digit characters!"
    exit 0
fi

# Get required package 'sysbench', install if necessary
if [ $(dpkg-query -W -f='${Status}' sysbench 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    if [[ $EUID -ne 0 ]]; then
        echo -e "\e[91mMissing required package 'sysbench'!\e[39m"
        echo -e "\e[93mPlease run as root or intall sysbench manually!\e[39m"
        exit 1
    fi
    echo -e "\e[93mInstalling required package 'sysbench'\e[39m"
    apt-get -y install sysbench
    echo -e "\e[93mDone installing 'sysbench'\e[39m"
fi

# Number of consecutive stress tests
arg1=${1:-0}
arg1=${arg1//[!0-9]/}
# Grammar variable 1
if [ $arg1 -ne 1 ]; then
    ess1=s
fi
# Time interval between CPU measurements
arg2=${2:-5}
arg2=${arg2//[!0-9]/}
# Grammar variable 2
if [ $arg2 -ne 1 ]; then
    ess2=s
fi

# Proper keyboard interupt abort mesage
function ctrl_c() {
    echo -e "\r\e[93mStress test$f manually aborted\e[39m"
    exit 0
}

# Display current temperature and frequency, colored by the Pi's throttle state
function measure() {
    case $(($(vcgencmd get_throttled | cut -d '=' -f 2) & 12)) in
    4)
        color="\\e[91m"
        ;;
    8)
        color="\\e[93m"
        ;;
    *)
        color="\\e[92m"
        ;;
    esac
    echo -e "temperature:$color $(echo $((($(cat /sys/class/thermal/thermal_zone0/temp) + 50) / 100)) | sed 's/.$/.&/')°C\e[39m |" \
            "frequency:$color $(($(vcgencmd measure_clock arm | cut -d '=' -f 2) / 1000000))mHz\e[39m"
}

# CPU measurement loop
function monitor() {
    time=$(date +%s)
    while true; do
        while [[ $(($(date +%s) - $time)) -lt $1 ]]; do :; done
        time=$(date +%s)
        measure
    done
}

# Stress test execution message
echo -e "Running \e[93m$arg1\e[39m stress test$ess1"
if [ $arg2 -eq 0 ]; then
    echo "Measuring cpu after every test"
else
    echo -e "Measuring CPU every \e[93m$arg2\e[39m second$ess2"
    monitor $arg2 &
fi

# Trap keyboard interupt for proper abort message
trap ctrl_c INT

# Run the stress test(s) while measuring the CPU
measure
for ((i=1; i<=$arg1; i++)); do
    echo -e "\e[96m-------------\e[39m Stress test $i \e[96m-------------\e[39m"
    sysbench --test=cpu --cpu-max-prime=20000 --num-threads=$(cat /proc/cpuinfo | grep -c "processor") run > /dev/null 2>&1
    if [ $arg2 -eq 0 ]; then
        measure
    fi
done

# Stop execution of measurement loop, if started
if [ $arg2 -ne 0 ]; then
    kill $! &> /dev/null
    wait $! &> /dev/null
fi

# Stress test finish message
echo -e "\e[92mFinished stress test$ess1\e[39m"
measure
exit 0
