#!/bin/bash
# "Debian Testing" {e53e8e0b-b22c-455a-99f3-4f5788878ba3}
# Attualmente 10.10.24.20 - 5/11/2014
# ----
# Lista di tutte le vms
# "WindowsXP SP3" {56ce229c-f9bf-4df5-8643-33b9ab11d7b9}
# "openSuSE 13.2 64bit" {80dc0abf-083f-48e6-b15a-246800becd97}
# "LinuxUbuntuServer-tpl" {0bacc6e6-9b97-483a-95aa-705c9d7765a6}
# "IPCop1.4.20 (Stable)" {ef36f699-5be3-4bfc-b89f-2869f23f67ed}
# "IPCop1.9 (DHCP)" {51027828-8344-463c-93cb-b2296d8c55f1}
# "Fedora 20 Desktop 64" {a6fc6c4d-17aa-4e14-ab69-5b21e43ac326}
# "Windows 1.0" {24f0addf-4848-4dc7-a51a-028436d672d1}
# "CMDBuild Ubuntu 10.04LTS" {f4cc7970-2267-40ee-961e-fbda7ed96b5a}
# "FreeNAS 8 x86" {8d2878a6-1f4c-4fcb-938c-38803793f60b}
# "Template-centos6-64bit" {34732d7e-2918-4049-bb6c-36e8a70fdaed}
# "Android 4.3 x86" {c85e7e2e-e5e8-4dc6-a3bc-89c79aa7ea0f}
# "Android 4.2 x86" {f7f4f3c4-a591-4b37-8b46-4d167ac4b2c2}
# "Linux Mint 32" {9efdea41-1f0e-498e-b147-19251cd0163f}
# "zadmin" {07ccbd0c-138c-4367-b15f-9e41882c4d76}
# "Ubuntu 14.04LTS 64bit" {d3f0f321-42c6-4233-82c3-3885932e27ee}
# "Ubuntu Server 14.04LTS 64bit" {106f4bdd-3f98-4b69-b0f2-e84eae0f3ca6}
# "Debian 64 stable" {61abd1eb-c01c-4d93-9391-2e032e10b932}
# "Linux CentOS 7" {24436a76-0134-4d07-b59c-d392b646a94f}
# "Linux Mint Debian Edition 64bit" {52cd44b9-7aec-499d-a041-6693b0888c15}
# "Samsung Galaxy Note - 4.1.1 - API 16 - 800x1280" {d4f33508-9f6f-412a-a51d-1a61261ac379}
# "Debian Testing" {e53e8e0b-b22c-455a-99f3-4f5788878ba3}

basevm=$(basename ${0##*_} .sh)

# E' consigliabile usare VBoxHeadless --startvm <uuid|name>
case $basevm in
	debian*)
		vm="Debian Testing"
		vmuid="{e53e8e0b-b22c-455a-99f3-4f5788878ba3}"
		;;
	suse*|opensuse*)
		vm="openSuSE 13.2 64bit"
		vmuid="{80dc0abf-083f-48e6-b15a-246800becd97}"
		;;
	fedora*)
		vm="Fedora 20 Desktop 64" 
		vmuid="{a6fc6c4d-17aa-4e14-ab69-5b21e43ac326}"
		;;
	cos*|centos*)
		vm="Linux CentOS 7" 
		vmuid="{24436a76-0134-4d07-b59c-d392b646a94f}"
		;;
	*) 
		echo "No vm recognized to be started."
		echo
		;;
esac


# VBoxManage startvm "$vm" --type headless
/usr/bin/VBoxHeadless --startvm $vmuid &

# Provato a conoscere l'ip nei seguenti modi: 
#  VBoxManage --nologo guestcontrol "openSuSE 11.3 64bit" execute --image "/sbin/ifconfig"  --username user --password pass --wait-exit --wait-stdout -- -a
# VBoxManage list bridgedifs
# ....

givenIP=`VBoxManage guestproperty enumerate "$vm" | grep -o "Net.*IP.*value: [0-9\.]*" | cut -f2 -d ":" | sed "s/^\s*//" | sed "s/\s*$//"`

if [ -n "$givenIP" ]; then
	echo -e "\n IP Attribuito alla VM \"$vm\" = $givenIP \n"
	retval=0
else
	echo -e "\n WARNING: Non rilevo IP della VM \"$vm\". Probabilmente non sono"
	echo -e "installate le ultime Guest Addons di Virtual Box nella VM\n"
  retval=1
fi

exit $retval
