#!/bin/bash
# RouteViews-bash
# Record changes in routing data using the data from routeviews.org
# by @tprime_

# Set our time variables here
# This is relevant because routeviews.org has new data every two hours
twohrsago=$(date +"%m%d%y%H" --date="2 hours ago")
now=$(date +'%m%d%y%H')

echo -e "[!] Hi! I'm the RouteViews-bash recording script.\n"

# First, check that AS numbers have been specified by the user
if [ -z $1 ]; then
	echo -e "[*] Error: A list of comma-seperated AS numbers is required. Syntax:"
	echo -e "./routeviews-bash.sh 123,456,789\n"
	exit 1
fi

# If AS variables are set, download the latest BGP data from archive.routeviews.org:
echo -e "[!] Downloading latest BGP data from Route Views...\n"
wget -q http://archive.routeviews.org/oix-route-views/oix-full-snapshot-latest.dat.bz2

# Extract our downloaded archive
echo -e "[!] Extracting archive...\n"
bzip2 -d oix-full-snapshot-latest.dat.bz2

# Build or write to our CSV file
# First, check if the rv.csv file exists.
# If the file rv.csv doesn't exist, fill in a value of 0 instead of a valid change
if [ ! -f rv.csv ]; then
        echo -e "[!] Looks like the script is being run for the first time. Inserting blank change values for each AS.\n"
	csv_results_exist=0
fi
echo -e "[!] Writing to CSV file...\n"
for as in $( echo $1 | sed s/,/\\n/g )
do
	echo -n $now",">> rv.csv
	echo -n $as",">> rv.csv
	CurrentASValue=$(/bin/grep $as oix-full-snapshot-latest.dat | wc -l)
	echo -n $CurrentASValue",">> rv.csv

if [ $csv_results_exist -eq 0 ]; then
        echo "0" >>rv.csv
else
echo -e "[!] Comparing data...\n"
for as in $( echo $1 | sed s/,/\\n/g ); do
        LastASValue=$(/bin/grep $as rv.csv | tail -n1 | cut -f3 -d",")
        ASChangeValue=$( echo "scale=2; (($CurrentASValue/$LastASValue)-1)" | bc )
        echo $ASChangeValue>> rv.csv
done
fi
done

# Inform user of completion and remove old routeviews data
echo -e "[!] All done.\n"
rm oix-full-snapshot-latest.dat
