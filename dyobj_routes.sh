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
servName=$(cat /etc/nodename)

is_fw_module=$($CPDIR/bin/cpprod_util FwIsFirewallModule)

function log_line {
        # add timestamp to all log lines
        message=$1
        local_log_file=$2
        echo "$(date) $message" >> $local_log_file
}

function convert {
	oldObjName=""
        for ip in ${addrs[@]} ; do
		#echo $ip
		oName=$(echo $ip| awk -F"," '{print $1}' )
		if [[ $oldObjName != $oName ]]; then
		        ok=$( dynamic_objects -do "$oName" )
        		ok=$( dynamic_objects -n "$oName" )
		fi
		#echo "Iface:"$oName
		addr=$(echo $ip| awk -F"," '{print $2}' )
		#echo "Adr:"$addr
		laddr=$(echo $addr| awk -F"." '{print $4}')
		if [[ "$laddr" -eq 0 ]]; then
			addr=$(echo $addr| awk -F"." '{print $1"."$2"."$3".1"}')
		fi	
		bcast=$(echo $ip | awk -F"," '{print $3}' )
		bctest=$(echo $addr" "$bcast)
		#echo $bctest
                first=$addr
                last=$(ipcalc -b $bctest | awk -F"=" '{print $2}')
                #echo "$oName,$first,$last"
 #               todo[$y]+="$oName,$first,$last"
                if [[ "$z" -eq 2000 ]]
                        then
                                z=0
                                let y=$y+1
                        else
                                let z=$z+1
                        fi
                ocmd="dynamic_objects -o $oName -r $first $last -a "
		#echo $ocmd
                #ok=$( dynamic_objects -o "$objName" -r "$a" "$b" -a )
		ok=$(eval $ocmd)
		oldObjName=$oName
        done


#        for i in "${todo[@]}" ;
#        do
#		objName=$(echo $i | awk -F"," '{print $1}' )
#		a=$(echo $i | awk -F"," '{print $2}' )
#		b=$(echo $i | awk -F"," '{print $3}' )
#        done
#        unset todo
        unset addrs
}

if [[ "$is_fw_module" -eq 1 && /etc/appliance_config.xml ]]; then

 adrcmd="route | awk 'FNR > 2 {if(\$1!=\"default\") print \$8\",\"\$1\",\"\$3}'|sort"
 #echo $adrcmd
 addrs=($(eval $adrcmd))
 addrsLen=${#addrs[@]}
 if [[ "$addrsLen" -ne 0 ]]; then
	echo "Converting"
	convert
 fi
fi

