#!/bin/bash
# dyobj_routes.sh
# Author: CB Currier <ccurrier@checkpoint.com>
# Version 1
# Date 6/12/2018 12:47:00

timeout=43200
LOG_FILE="$FWDIR/log/route_dynObj.log"
y=0
x=0
z=0
is_fw_module=1

is_fw_module=$($CPDIR/bin/cpprod_util FwIsFirewallModule)

function log_line {
        # add timestamp to all log lines
        message=$1
        local_log_file=$2
        echo "$(date) $message" >> $local_log_file
}

function remove_existing_sam_rules {
        log_line "remove existing sam rules for $objName" $LOG_FILE
        dynamic_objects -do $objName
}

function convert {
        for ip in ${addrs[@]} ; do
		#echo $ip
		addr=$(echo $ip| awk -F"/" '{print $1}' )
		laddr=$(echo $addr| awk -F"." '{print $4}')
		if [[ "$laddr" -eq 0 ]]; then
			addr=$(echo $addr| awk -F"." '{print $1"."$2"."$3".1"}')
		fi	
		bcast=$(echo $ip | awk -F"/" '{print $2}' )
		bctest=$(echo $addr" "$bcast)
                first=$addr
                last=$(ipcalc -b $bctest | awk -F"=" '{print $2}')
                #echo $first"-"$last
                todo[$y]+=" $first $last"
                if [[ "$z" -eq 2000 ]]
                        then
                                z=0
                                let y=$y+1
                        else
                                let z=$z+1
                        fi
        done

        ok=$( dynamic_objects -do "$objName" )
        ok=$( dynamic_objects -n "$objName" )

        for i in "${todo[@]}" ;
        do
                ok=$( dynamic_objects -o "$objName" -r $i -a )
        done
        unset todo
        unset addrs
}

function print_help {
                echo ""
                echo "This script is intended to run on a Check Point Firewall"
                echo ""
                echo "Usage:"
                echo "  dyobj_routes.sh <options>"
                echo ""
                echo "Options:"
                echo "  -o                      Dynamic Object Name (required)"
                echo "  -i                      Network Interface to populate from"
                echo "  -a                      action to perform (required) includes:"
                echo "                          run (once), on (schedule), off (from schedule), stat (status)"
                echo "  -h                      show help"
                echo ""
                echo ""
}

while getopts o:i:a:h: option
  do
        case "${option}"
        in
        o) objName=${OPTARG};;
        i) iface=${OPTARG};;
        a) action=${OPTARG};;
        h) dohelp=${OPTARG};;
        ?) dohelp=${OPTARG};;
        esac
done

objName="DYOBJ_"$objName
fiface="/etc/sysconfig/network-scripts/ifcfg-"$iface
if [ ! -e "${fiface}" ]; then
        echo "Interface $iface  not found"
        log_line "Interface $iface for $objName not found" $LOG_FILE
        exit 1
fi

if [[ "$is_fw_module" -eq 1 && /etc/appliance_config.xml ]]; then
        case "$action" in

                on)
                log_line "adding dynamic object $objName to cpd_sched " $LOG_FILE
                $CPDIR/bin/cpd_sched_config add $objName -c "$CPDIR/bin/dyobj_routes.sh" -v "-a run -o $objName -i $iface" -e $timeout -r -s
                log_line "Automatic updates of $objName is ON" $LOG_FILE
                ;;

                off)
                log_line "Turning off dyamic object updates for $objName" $LOG_FILE
                $CPDIR/bin/cpd_sched_config delete $objName -r
                remove_existing_sam_rules
                log_line "Automatic updates of $objName is OFF" $LOG_FILE
                ;;

                stat)
                cpd_sched_config print | awk 'BEGIN{res="OFF"}/Task/{flag=0}/'$objName'/{flag=1}/Active: true/{if(flag)res="ON"}END{print "'$objName' list status is "res}'
                ;;

                run)
                log_line "running update of dyamic object $objName" $LOG_FILE
		adrcmd="route | grep $iface | awk '{if(\$1!=\"default\") print \"\"\$1\"/\"\$3\"\"}'"
		#echo $adrcmd
		addrs=($(eval $adrcmd))
		#addrs=($(route | grep "$(iface)" | awk '{if($1!="default") print ""$1"/"$3""}'))
		addrsLen=${#addrs[@]}
		if [[ "$addrsLen" -ne 0 ]]; then
			echo "Converting"
			convert
		        logProds+=$objName" "$addrsLen" ranges updated\n"
		fi
		log_line "update of dynamic object $objName completed" $LOG_FILE
		echo -e $logProds
                ;;

                *)
                print_help
        esac
fi

