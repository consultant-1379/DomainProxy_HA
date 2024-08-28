#!/bin/bash

source ./variables.global
DATE_NOW=$(date +%F_%H%M%S)
DEPLOY_ID=$(cat $SED_FILE | grep deployment_id | cut -d: -f 2 | cut -d\" -f 2)
 
Adjust_LVS(){
 
echo "== Preparing safe copy from files"
        cp -arf $LVS_FILE "$LVS_FILE"_"$DATE_NOW"
 
echo "== Adjusting LVS YAML"
 
echo "==== Adjusting the description"
        sed -i s/'description: lvs'/'description: DP_HA-lvs'/g $LVS_FILE
 
echo "==== Adjusting the allowed_address_pairs param"
        LVS_ADDR_LINE=$(grep -n 'allowed_address_pairs' $LVS_FILE | head -n1 | cut -d: -f1)
        LVS_ADDR_LINE=$(($LVS_ADDR_LINE+3))
        awk 'NR=="$LVS_ADDR_LINE" {print " "} {print $0}' $LVS_FILE > $LVS_TMP_FILE && mv $LVS_TMP_FILE $LVS_FILE
        LVS_ADDR_LINE=$(($LVS_ADDR_LINE-1))
        sed -i ""$LVS_ADDR_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $LVS_FILE
 
echo "==== Adjusting the lvs_allowed_address_pairs param"
        LVS_ADDR1_LINE=$(grep -n 'lvs_allowed_address_pairs' $LVS_FILE | head -n1 | cut -d: -f1)
        LVS_ADDR1_LINE=$(($LVS_ADDR1_LINE+3))
        awk 'NR=="$LVS_ADDR1_LINE" {print " "} {print $0}' $LVS_FILE > $LVS_TMP_FILE && mv $LVS_TMP_FILE $LVS_FILE
        LVS_ADDR1_LINE=$(($LVS_ADDR1_LINE-1))
        sed -i ""$LVS_ADDR1_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $LVS_FILE

echo "==== Adjusting the nat_combined_security_groups param"
        LVS_NAT_LINE=$(grep -n 'nat_combined_security_groups' $LVS_FILE | head -n1 | cut -d: -f1)
        LVS_NAT_LINE=$(($LVS_NAT_LINE+3))
        awk 'NR=="$LVS_NAT_LINE" {print " "} {print $0}' $LVS_FILE > $LVS_TMP_FILE && mv $LVS_TMP_FILE $LVS_FILE
        EXT_SECURITY_GRP=$(cat $SED_FILE | grep enm_external_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
        INT_SECURITY_GRP=$(cat $SED_FILE | grep enm_internal_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
        LVS_NAT_LINE=$(($LVS_NAT_LINE-1))
        sed -i ""$LVS_NAT_LINE"a\    default: \""$INT_SECURITY_GRP,$EXT_SECURITY_GRP"\"" $LVS_FILE

echo "==== Adjusting tags param"
	LVS_TAG_LINE=$(grep -n 'tags' $LVS_FILE | head -n1 | cut -d: -f1)
	LVS_TAG_LINE=$(($LVS_TAG_LINE+3))
	sed -i "$LVS_TAG_LINE"d $LVS_FILE
        LVS_TAG_LINE=$((LVS_TAG_LINE-1))
        DEPLOY_ID=$(echo $DEPLOY_ID | sed s/-dpha//g)
        LVS_TAGS=$(echo "    default: {\"enm_deployment_id\": \""$DEPLOY_ID"\", \"enm_stack_name\": \"DP_HA-"$DEPLOY_ID"-lvs\"}")
	sed -i ""$LVS_TAG_LINE"a\replace_here" $LVS_FILE
	sed -i s/replace_here/"$LVS_TAGS"/g $LVS_FILE

}

Adjust_LVS

 
