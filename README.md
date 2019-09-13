# Raspberry Pi Stress Test
Use sysbench to stress test the Raspberry Pi while logging temperature and clock speed

## Description
Test your cooling solution (or lack of) against the heat production of your Pi's processor with this script, all the while logging temperature and clock speed to console. The output is colorized to indicate the current throttling level of the Pi, red for throttled, yellow for soft-throttled, and green for A-OK!

Optionally, create a log file by piping the output into `tee` and specifying an output file. 

## Command usage
`./stress_test.sh {[iterations] <interval>} {| tee [filename]}`
* `[iterations] <interval>` : omittable
  * If arguments are supplied, then
  * `iterations` : required
    * How many stress tests to perform
    * Default: 1
  * `interval` : optional
    * The time in seconds inbetween CPU measurements
    * When 0, measure CPU after completion of each stress test
    * Default 5
  * All non-digit characters (incluing '-' and '.') are stripped, and
  * If the result is empty, then default values are used
* `| tee [filename]` : omittable
  * Include this to display and save console output, then
  * `filename` : required
    * Name of the file to save output to
    * Absolute and relative path allowed

## Requirements
This script requires execution permission. Enable execution of this script by running `sudo chmod +x stress_test.sh`

This script requires `sysbench`. If it is not installed, either run the script in `sudo`, or install it manually with `sudo apt install sysbench` or `sudo apt-get install sysbench`
