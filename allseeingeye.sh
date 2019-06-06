#!/bin/bash

# Max time per host (Seconds)
TIMEOUT=2
# Number of ping packets to send per host
PPACKETS=4
# Time between sending packets (Seconds)
PPACKETT=0.4

touch allseeingeye.csv
touch allseeingsearch.txt
touch allseeinglimit.txt
touch launcher.txt

function setlauncher() {
clear
echo "How to connect or what to launch?"
echo "(1) Netcat (Apple Binary)"
echo "(2) NCat (NMap Binary)"
echo "(3) VLC"
echo "(Anything Else) Arbitrary command with IP:PORT at the end"
read launcher
case $launcher in
1) echo "nc" > launcher.txt ;;
2) echo "ncat" > launcher.txt ;;
3) echo "/Applications/VLC.app/Contents/MacOS/VLC rtsp://" > launcher.txt ;;
*) echo $launcher" " > launcher.txt ;;
esac
}

function seppuku() {
killall -9 VLC
exit 0
}

trap seppuku SIGINT SIGTERM

function allseeingsearchfree() {
clear
echo "Running shodan search with search parameters: " `cat allseeingsearch.txt`
`shodan search --fields ip_str,port,info,hostnames,org --separator , --limit \`cat allseeinglimit.txt\` \`cat allseeingsearch.txt\` > allseeingeye.csv`
# Fixes result count being +1 but breaks OS X
# head -n -1 allseeingeye.csv > allseeingeye2.csv ; mv allseeingeye2.csv allseeingeye.csv
}

function allseeingsearch() {
clear
echo "Running shodan download with search parameters: " `cat allseeingsearch.txt`
mv allseeing.json.gz allseeing_old.json.gz
`shodan download allseeing "\`cat allseeingsearch.txt\`" --limit \`cat allseeinglimit.txt\``
`shodan parse --fields ip_str,port,info,hostnames,org --separator , allseeing.json.gz > allseeingeye.csv`
# head -n -1 allseeingeye.csv > shodan2.csv ; mv shodan2.csv allseeingeye.csv
}


function changesearch() {
clear
echo "Feed me your search parameters"
read search
echo $search > allseeingsearch.txt
echo "How many results to download?"
read limit
echo $limit > allseeinglimit.txt
}

function check() {
# Check hosts
echo "Checking hosts in allseeingeye.csv"
rm shodan_alive.csv
touch shodan_alive.csv
for SERVER in $(cat allseeingeye.csv | cut -d"," -f1)
do
if ping -i $PPACKETT -c $PPACKETS -W $TIMEOUT $SERVER &> /dev/null
then
echo "$SERVER alive"
echo $SERVER >> shodan_alive.csv
else
echo "$SERVER dead"
fi
done
osxsucks1=`wc -l shodan_alive.csv | cut -d"s" -f1`
osxsucks2=`wc -l allseeingeye.csv | cut -d"s" -f1`
echo "End result: " `echo $((osxsucks1))` "/" `echo $((osxsucks2))` "hosts up"
read -rsp $'Hit a key to continue' -n 1 key
}

function connect() {
# Make a little menu
clear
echo "Choose a host to connect to"
HOSTS=(`cat shodan_alive.csv`)
HOSTS2=()
for HOSTINFO in "${HOSTS[@]}"
do
NEWHOST=`cat allseeingeye.csv | grep "$HOSTINFO"","`
INFO=`echo "$NEWHOST" | cut -d"," -f3`
ISP=`echo "$NEWHOST" | cut -d"," -f5`
if [ ${#INFO} -ge 1 ]; then INFO=" INFO:""$INFO"; else INFO=""; fi
if [ ${#ISP} -ge 1 ]; then ISP=" ISP:""$ISP"; else ISP=""; fi
HOSTS2+=(`echo $NEWHOST | cut -d"," -f1`", ("`echo $NEWHOST | cut -d"," -f4 `") Port:"`echo $NEWHOST | cut -d"," -f2`" ""$INFO""$ISP")
done
while [ "1" = "1" ]; do
select HOST in "${HOSTS2[@]}"
do
    if [[ " ${HOSTS2[@]} " =~ " ${HOST} " ]]
    then
    if [[ ${#HOST} < 10 ]]; then
    killall -9 VLC
    exit
    fi
    echo "Attempting to connect to host: $HOST"
    CONNHOST=`echo $HOST | cut -d"," -f1`
    #nc $CONNHOST `cat allseeingeye.csv | grep "$CONNHOST""," | cut -d"," -f2` 
    launch=`cat launcher.txt`
    if [ `echo $launch  | cut -d"/" -f2` == "Applications" ]; then
    $launch$CONNHOST &> /dev/null &
    elif [ `echo $launch` == "nc" ]; then 
    echo $CONNHOST
    nc $CONNHOST `cat allseeingeye.csv | grep "$CONNHOST""," | cut -d"," -f2`
    elif [ `echo $launch` == "ncat" ]; then
    ncat $CONNHOST `cat allseeingeye.csv | grep "$CONNHOST""," | cut -d"," -f2`
    else
    $launch$CONNHOST":"`cat allseeingeye.csv | grep "$CONNHOST""," | cut -d"," -f2`
    fi
    else
    echo "Invalid. Try again"
    fi

done
done
}


while [ "1" = "1" ]; do
clear
echo "*** 
 █████╗ ██╗     ██╗     ███████╗███████╗███████╗██╗███╗   ██╗ ██████╗ ███████╗██╗   ██╗███████╗
██╔══██╗██║     ██║     ██╔════╝██╔════╝██╔════╝██║████╗  ██║██╔════╝ ██╔════╝╚██╗ ██╔╝██╔════╝
███████║██║     ██║     ███████╗█████╗  █████╗  ██║██╔██╗ ██║██║  ███╗█████╗   ╚████╔╝ █████╗  
██╔══██║██║     ██║     ╚════██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██║   ██║██╔══╝    ╚██╔╝  ██╔══╝  
██║  ██║███████╗███████╗███████║███████╗███████╗██║██║ ╚████║╚██████╔╝███████╗   ██║   ███████╗
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝
Welcome to ALLSEEINGEYE. Please make a selection.                                                                                               
 ***"
osxsucks3=`wc -l allseeingeye.csv | cut -d "s" -f1`
echo "Last # search results: " `echo $osxsucks3`
echo "Current search parameter: " `cat allseeingsearch.txt` "(Limit: " `cat allseeinglimit.txt` ")"
echo "Launcher: " `cat launcher.txt`
echo ""
echo "(1) Connect to current hosts"
echo "(2) Check current hosts"
echo "(3) Search for free (100 results)"
echo "(4) Search via download (>100 results)"
echo "(5) Change search parameter and limit"
echo "(6) Change launcher"
echo "(9) Quit"
read choice
case $choice in
1) connect ;;
2) check ;;
3) allseeingsearchfree ;;
4) allseeingsearch ;;
5) changesearch ;;
6) setlauncher ;;
9) exit ;;
*) echo "Try again" ;;
esac
done

#Originally by Jack Darcy & Chris Wasiuk
