#!/bin/bash
set -e


SELF="$0"


# CHECK ROOT
if [ "$(whoami)" != "root" ]; then
	echo "You are not root"

	if [ ! -z $@ ]; then
		echo "Add sudo before command: sudo $0 $@"
	else
		echo "Add sudo before command: sudo $0"
	fi

	exit 1
fi


# PARSE ARGUMENTS
POSITIONAL=()
while [[ $# -gt 0 ]]; do
key="$1"
case $key in
    --RKN|--rkn)
		rkn=true
		shift
    	;;
    --self)
		self=true
		shift
		;;
	-h|--help)
		need_help=true
		shift
		;;
    *)
		POSITIONAL+=("$1")
    	shift
    	;;
esac
done

set -- "${POSITIONAL[@]}"


if [ ! -z "$need_help" ]; then
	echo "This software raises the Tor socks proxy and enables" \
		 "proxying in settings to Wi-Fi network"
	echo ""
	echo "If no flags was specified this software will trigger current state"
	echo ""
	echo "Available flags:"
	echo "\t--RKN | --rkn: Raise Tor socks proxy and enable proxying in settings"
	echo "\t--self: Disable Tor socks proxy and removing it from settings"
	echo "\t-h | --help: Display this help"
	exit 0
fi


function raiseTor {
	if pgrep -x "tor" > /dev/null; then
		echo "Looks like Tor is already raised - skipping"
		return 0
	fi


	torRaising=$(su $(logname) -c "tor RunAsDaemon 1")

	if [[ "$?" == "0" ]]; then
		echo "Raised"
		return 0
	fi

	echo "Tor raising failed - exit"
	echo "Tor logs:"
	echo "$torRaising"
	exit 2
}


function killTor {
	killall tor

	if [[ "$?" == "0" ]]; then
		echo "Killed"
		return 0
	fi

	echo "WTF, Tor is a God - we can't kill him"
}


function enableProxyInSettings {
	networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 9050
	networksetup -setsocksfirewallproxystate Wi-Fi on

	echo "Enabled"
}


function disableProxyInSettings {
	networksetup -setsocksfirewallproxystate Wi-Fi off

	echo "Disabled"
}


if [ ! -z "$rkn" ]; then
	echo "Blocking RKN"

	echo -n "Raising Tor... "
	raiseTor

	echo -n "Enabling proxy in settings... "
	enableProxyInSettings

	exit 0
fi


if [ ! -z "$self" ]; then
	echo "Blocking self "

	echo -n "Killing Tor... "
	killTor

	echo -n "Disabling proxy in settings... "
	disableProxyInSettings

	exit 0
fi


echo "No flags provided - detecting current state"
echo

proxyingSettingsCorrect=false

echo "Network settings:"

networkSettings=$(networksetup -getsocksfirewallproxy Wi-Fi)

echo -n -e "\tProxying enabled: "
proxyingState=$(echo "$networkSettings" | head -n 1)
if [[ $proxyingState = *"Yes"* ]]; then
	proxyingEnabled=true
	echo "true"
else
	proxyingEnabled=false
	echo "false"
fi

echo -n -e "\tProxy server IP correct: "
server=$(echo "$networkSettings" | head -n 2 | tail -n 1)
if [[ $server = *"127.0.0.1"* ]]; then
	ipCorrect=true
	echo "true"
else
	ipCorrect=false
	echo "false"
fi

echo -n -e "\tProxy server port correct: "
serverPort=$(echo "$networkSettings" | head -n 3 | tail -n 1)
if [[ $serverPort = *" 9050"* ]]; then
	echo "true"
	portCorrect=true
else
	echo "false"
	portCorrect=false
fi

if [[ $ipCorrect == false || $portCorrect == false ]]; then
	echo "Network settings corrupted - launch this software with --rkn flag"
	exit 2
fi


torRaised=false
if pgrep -x "tor" > /dev/null; then
	torRaised=true
fi

echo "Tor raised: $torRaised"


echo


if [[ $torRaised == true && $proxyingEnabled == true ]]; then
	echo "RKN  is blocked - unblocking"
	echo
	$SELF --self
	exit 0
fi


if [[ $torRaised == false && $proxyingEnabled == false ]]; then
	echo "Self  is blocked - unblocking"
	echo
	$SELF --rkn
	exit 0
fi


echo "Unknow state - please launch this software with --rkn or --self flag"
