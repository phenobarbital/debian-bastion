#!/bin/bash
# ================================================================================
# Bastion Debian Linux: Secure a Server-Based Debian GNU/Linux
#
# Copyright © 2013 Jesús Lara Giménez (phenobarbital) <jesuslarag@gmail.com>
# Version: 0.1  
#
#    Developed by Jesus Lara (phenobarbital) <jesuslara@phenobarbital.info>
#    https://github.com/phenobarbital/debian-bastion
#    
#    License: GNU GPL version 3  <http://gnu.org/licenses/gpl.html>.
#    This is free software: you are free to change and redistribute it.
#    There is NO WARRANTY, to the extent permitted by law.
# ================================================================================

# get configuration
if [ -e /etc/debian-bastion.conf ]; then
    . /etc/debian-bastion.conf
else
    . ./etc/debian-bastion.conf
fi


# common functions
if [ -e /usr/lib/debian-bastion/libbastionado ]; then
    . /usr/lib/debian-bastion/libbastionado
else
    . ./lib/libbastionado
fi

if [ "$(id -u)" != "0" ]; then
   error "==== MUST BE RUN AS ROOT ====" >&2
   exit 1
fi

# commands
CAT="$(which cat)"
MOUNT="$(which mount)"
ECHO="$(which echo)"
SYSCTL="$(which sysctl)"
APT="$(which apt-get)"
APTITUDE="$(which aptitude)"
#

check_name()
{
	if [[ "${#1}" -gt 20 ]] || [[ "${#1}" -lt 2 ]]; then
		usage_err "hostaname '$1' is an invalid name"
	fi
}

check_domain()
{
	if [[ "${#1}" -gt 254 ]] || [[ "${#1}" -lt 2 ]]; then
		usage_err "domain name '$1' is an invalid domain name"
	fi
	dom=$(echo $1 | grep -P '(?=^.{5,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')
	if [ -z $dom ]; then
		usage_err "domain name '$1' is an invalid domain name"
	fi
}

SIZE=''
IP=''
IFACE=''
LAN_INTERFACE=''
DIST=''
DEBUG='false'
VERBOSE='true'

usage() {
	echo "Usage: $(basename $0) [-n|--hostname=<hostname>] [-D|--domain=DOMAIN] [--debug] [-h|--help]"
}

help() {
	usage
cat <<EOF

This script is a helper to Secure a Debian GNU/Linux Server-Oriented

Automate, Secure and easily install a Debian Enterprise-ready Server

Options:
  -n, --hostname             specify the name of the debian server
  -D, --domain               define Domain Name
  -l, --lan                  define LAN Interface (ej: eth0)
  --debug                    Enable debugging information
  Help options:
      --help     give this help list
      --usage	 Display brief usage message
      --version  print program version
EOF
	echo ''
	get_version
	exit 1
}

# si no pasamos ningun parametro
if [ $# = 0 ]; then
	usage
	exit 0
fi

# processing arguments
ARGS=`getopt -n$0 -u -a -o r:n:D:l:h --longoptions packages:,debug,usage,verbose,version,help,lan::,domain::,hostname:: -- "$@"`
eval set -- "$ARGS"

while [ $# -gt 0 ]; do
	case "$1" in
        -n|--hostname)
			optarg_check $1 "$2"
            check_name "$2"
            NAME=$2
            shift
            ;;
        -D|--domain)
			optarg_check $1 "$2"
            check_domain $2
            DOMAIN=$2
            shift
            ;;
        -l|--lan)
			optarg_check $1 "$2"
            LAN_INTERFACE=$2
            shift
            ;;            
        --packages)
			optarg_check $1 "$2"
			PACKAGES="$2"
			shift
			;;         
        --debug)
            VERBOSE='true'
            ;;
        --verbose)
            VERBOSE='true'
            ;;     
        --version)
			get_version
			exit 0;;
        -h|--help)
            help
            exit 1
            ;;
        --)
            break;;
        -?)
            usage_err "unknown option '$1'"
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
	esac
    shift
done

### main execution program ###

main()
{
	
	## discover Debian suite (ex: wheezy)
	DIST=`get_distribution`
	SUITE=`get_suite`

	# descubrir el nombre del equipo
	get_hostname

	# descubrir el dominio
	get_domain

# deteccion de interface
firstdev
SERVERNAME=$NAME.$DOMAIN
# get first account
ACCOUNT=`getent passwd | grep 1000 | cut -d':' -f1`
hooksdir

# FS OPTIONS
BOOTFS=$(cat /etc/fstab | grep boot | grep UUID | awk '{print $3}')
ROOTFS=$(cat /etc/fstab | grep " / " | grep UUID | awk '{print $3}')

firstdev
LAN_IPADDR="$(ip addr show $LAN_INTERFACE | awk "/^.*inet.*$LAN_INTERFACE\$/{print \$2}" | sed -n '1 s,/.*,,p')"
if [ -z "$LAN_INTERFACE" ]; then
	error "LAN Interface its not defined"
	exit 1
fi
if [ -z "$LAN_IPADDR" ]; then
	error "LAN Interface $LAN_INTERFACE not configured, please assign a IP Address"
	exit 1
fi
GATEWAY=$(get_gateway)
# network options
NETMASK=$(get_netmask $LAN_INTERFACE)
NETWORK=$(get_network $GATEWAY $NETMASK)
SUBNET=$(get_subnet $LAN_INTERFACE)
BROADCAST=$(get_broadcast $LAN_INTERFACE)

if [ "$SSH_PORT" == 'random' ]; then
	SSH_PORT=$((RANDOM%9000+2000))
else
	SSH_PORT="$SSH_PORT"
fi

debug "= Debian Bastion Summary = "
## show summary of changes
show_summary

# TODO, ¿pedir confirmación para proceder luego del sumario?
read -p "Continue with installation (y/n)?" WORK
	if [ "$WORK" != "y" ]; then
		exit 0
	fi
	
	
	# installing a package list
	if [ ! -z "$PACKAGES" ]; then
		install_package $(echo $PACKAGES | tr ',' ' ')
	fi
	
	for f in $(find $HOOKSDIR/* -maxdepth 1 -executable -type f ! -iname "*.md" ! -iname ".*" | sort --numeric-sort); do
		if [ "$DEBUG" == 'true' ]; then 
			read -p "Continue with $f (y/n)?" WORK
			if [ "$WORK" != "y" ]; then
				exit 0
			else
				. $f
			fi
		else
			. $f
		fi
	done	
		
	if [ "$?" -ne "0" ]; then
    	error "Error en la ejecucion del script, revise log para informacion"
    	exit 1
    else
		warning "Reinicio necesario!"
		info "= Todo terminado, por favor reinicie el sistema para aplicar los cambios ="
		info "Recuerde asignar clave al usuario $SUPPORT antes de reiniciar el sistema"
	fi
}
	
# = end = #
main

exit 0
