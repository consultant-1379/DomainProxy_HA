#!/bin/bash
source ./variables.global
DATE_NOW=$(date +%F_%H%M%S)
DEPLOY_ID=$(cat $SED_FILE | grep deployment_id | cut -d: -f 2 | cut -d\" -f 2)

Adjust_DP_MED(){

echo "== Preparing safe copy from files"
        cp -arf $DP_MED_FILE "$DP_MED_FILE"_"$DATE_NOW"

echo "== Adjusting DP Mediation YAML"

echo "==== Adjusting the description"
	sed -i s/'description: dpmediation'/'description: DP_HA-dpmediation'/g $DP_MED_FILE

echo "==== Adjusting the nat_combined_security_groups param"
	DP_MED_NAT_LINE=$(grep -n 'nat_combined_security_groups' $DP_MED_FILE | head -n1 | cut -d: -f1)
	DP_MED_NAT_LINE=$(($DP_MED_NAT_LINE+3))
	awk 'NR=="$DP_MED_NAT_LINE" {print " "} {print $0}' $DP_MED_FILE > $DP_MED_TMP_FILE && mv $DP_MED_TMP_FILE $DP_MED_FILE
	EXT_SECURITY_GRP=$(cat $SED_FILE | grep enm_external_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
	INT_SECURITY_GRP=$(cat $SED_FILE | grep enm_internal_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
	DP_MED_NAT_LINE=$(($DP_MED_NAT_LINE-1))
	sed -i ""$DP_MED_NAT_LINE"a\    default: \""$INT_SECURITY_GRP,$EXT_SECURITY_GRP"\"" $DP_MED_FILE

echo "==== Adjusting the allowed_address_pairs param"
	DP_MED_ADDR_LINE=$(grep -n 'allowed_address_pairs' $DP_MED_FILE | head -n1 | cut -d: -f1)
	DP_MED_ADDR_LINE=$(($DP_MED_ADDR_LINE+3))
	awk 'NR=="$DP_MED_ADDR_LINE" {print " "} {print $0}' $DP_MED_FILE > $DP_MED_TMP_FILE && mv $DP_MED_TMP_FILE $DP_MED_FILE
	DP_MED_ADDR_LINE=$(($DP_MED_ADDR_LINE-1))
	sed -i ""$DP_MED_ADDR_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $DP_MED_FILE

echo "==== Adjusting tags param"
	DP_MED_TAG_LINE=$(grep -n 'tags' $DP_MED_FILE | head -n1 | cut -d: -f1)
	DP_MED_TAG_LINE=$(($DP_MED_TAG_LINE+3))
	sed -i "$DP_MED_TAG_LINE"d $DP_MED_FILE
        DP_MED_TAG_LINE=$((DP_MED_TAG_LINE-1))
	DEPLOY_ID=$(echo $DEPLOY_ID | sed s/-dpha//g)
        DP_MED_TAGS=$(echo "    default: {\"enm_deployment_id\": \""$DEPLOY_ID"\", \"enm_stack_name\": \"DP_HA-"$DEPLOY_ID"-dpmediation\"}")
	sed -i ""$DP_MED_TAG_LINE"a\replace_here" $DP_MED_FILE
	sed -i s/replace_here/"$DP_MED_TAGS"/g $DP_MED_FILE

echo "==== Adjusting Gateway"
	DP_MED_GW_LINE=$(grep -n 'parameters' $DP_MED_FILE | head -n1 | cut -d: -f1)
	awk 'NR=="$DP_MED_GW_LINE" {print " "} {print $0}' $DP_MED_FILE > $DP_MED_TMP_FILE && mv $DP_MED_TMP_FILE $DP_MED_FILE
	sed -i ""$DP_MED_GW_LINE"a\  lvsrouter_internal_ip_list: \n    type: string\n" $DP_MED_FILE
	sed -i '$a\          lvsrouter_internal_ip_list: {get_param: lvsrouter_internal_ip_list}' $DP_MED_FILE
}

Adjust_DP_MED
 
