#!/bin/bash

echo "Staring main script for Domain Proxy HA"

source_vars(){
	echo "Sourcing the vars"
	source ./variables.global
	
	if [ -z "$DPMED_INT_IP" ] || [ -z "$LVS_EXT_IP" ] || [ -z "$LVS_INT_IP" ] 
	then
	        echo "!! Please check the variables in the file ./variables.global !!"
        	echo "   Item DPMED_INT_IP - Internal IP for the DP Medication server" 
		echo "   Item LVS_EXT_IP - External IP for the LVSRouter server"
                echo "   Item LVS_INT_IP - Internal IP for the LVSRouter server"
	        exit 0
	else
		IP_CALC=$(ipcalc -c4 $DPMED_INT_IP || echo invalid_ip ; ipcalc -c4 $LVS_EXT_IP || echo invalid_ip ; ipcalc -c4 $LVS_INT_IP || echo invalid_ip )
		if [ -n "$IP_CALC" ]
		then 
			exit 0
		else 
			echo "Loaded vars sucessfully"
		fi 
	fi
}

exec_script_sed(){

	./adjust-sed.sh
}

exec_script_dp_med(){

	./adjust-dp-med.sh
}

exec_script_dp_med_def(){

	./adjust-dp-med-def.sh
}

exec_script_lvs(){

	./adjust-lvs.sh
}

exec_script_lvs_def(){
	./adjust-lvs-def.sh
}

exec_stack(){

	DEPLOY_ID=$(echo $DEPLOY_ID | sed s/-dpha//g)
	echo "= Creating the stack LVS-HA and DP-MED-HA"
	openstack stack create -t $DP_MED_FILE -e $SED_FILE -f shell --tag enm_stack_name=DP_HA_dpmediation,enm_deployment_id=DP_HA_$DEPLOY_ID DP_HA_"$DEPLOY_ID"_dpmediation --wait  --insecure
	openstack stack create -t $LVS_FILE -e $SED_FILE -f shell --tag enm_stack_name=DP_HA_lvs,enm_deployment_id=DP_HA_$DEPLOY_ID DP_HA_"$DEPLOY_ID"_lvs --wait --insecure 
}


OPT=$1

case $OPT in
  --create-stack)
	source_vars
  	exec_stack		
  	;;
  --adjust-heat-template) 
  	source_vars
        exec_script_sed
        exec_script_dp_med
        exec_script_dp_med_def
        exec_script_lvs
        exec_script_lvs_def
  	;;
   *) 
    echo "Bad argument!" 
    echo "Usage: ./main.sh --create-stack or --adjust-heat-template"
    echo "	--create-stack : Create the stack for LVSROUTE and DP-MEDIATION HA."
    echo "	--adjust-heat-template : Backup and Heat Template adjustment to deploy the HA solution"
    ;;
esac

