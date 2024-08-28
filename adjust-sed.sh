#!/bin/bash
source ./variables.global 

DATE_NOW=$(date +%F_%H%M%S)

Adjust_SED(){

echo "== Preparing safe copy from files"
	cp -arf $SED_FILE "$SED_FILE"_"$DATE_NOW"

echo "== Adjusting SED File"

echo "==== Adjusting the deployment ID on ENM.json"
	DEPLOY_ID_LINE=$(grep -n "deployment_id" $SED_FILE | head -n 1 | cut -d: -f1)
	sed -i "$DEPLOY_ID_LINE"d $SED_FILE
        sed -i " "$DEPLOY_ID_LINE"a\ \""deployment_id"\":\""$DEPLOY_ID-dpha"\"\," $SED_FILE

echo "==== Adjusting DP Mediation server"
	DP_MED_ID=$(cat $SED_FILE | grep dpmediation_instances | sed 's/\"/\\\"/g' | sed 's/\,/\\\,/g')
	NEW_DP_MED_ID=$(echo $DP_MED_ID | sed s/2/1/g)
	sed -i s/$DP_MED_ID/$NEW_DP_MED_ID/g $SED_FILE
	DP_MED_SERVER_LINE=$(grep -n "dpmediation_internal_ip_list" $SED_FILE | head -n1 | cut -d: -f1)
	sed -i "$DP_MED_SERVER_LINE"d $SED_FILE
	sed -i " "$DP_MED_SERVER_LINE"a\ \"dpmediation_internal_ip_list\":\""$DPMED_INT_IP"\"\," $SED_FILE

echo "==== Adjusting LVS server"
	LVS_ID=$(cat $SED_FILE | grep lvsrouter_instances | sed 's/\"/\\\"/g' | sed 's/\,/\\\,/g')
        NEW_LVS_ID=$(echo $LVS_ID | sed s/2/1/g)
        sed -i s/$LVS_ID/$NEW_LVS_ID/g $SED_FILE

        LVS_INT_IP_LINE=$(grep -n "lvsrouter_internal_ip_list" $SED_FILE | head -n1 | cut -d: -f1)
        sed -i "$LVS_INT_IP_LINE"d $SED_FILE
        sed -i " "$LVS_INT_IP_LINE"a\ \"lvsrouter_internal_ip_list\":\""$LVS_INT_IP"\"\," $SED_FILE
	
	LVS_EXT_IP_LINE=$(grep -n "lvsrouter_external_ip_list" $SED_FILE | head -n1 | cut -d: -f1)
        sed -i "$LVS_EXT_IP_LINE"d $SED_FILE
        sed -i " "$LVS_EXT_IP_LINE"a\ \"lvsrouter_external_ip_list\":\""$LVS_EXT_IP"\"\," $SED_FILE


}


Adjust_SED
