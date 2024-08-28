#!/bin/bash

source ./variables.global
DATE_NOW=$(date +%F_%H%M%S)
DEPLOY_ID=$(cat $SED_FILE | grep deployment_id | cut -d: -f 2 | cut -d\" -f 2)

Adjust_DP_MED_DEF(){

echo "== Preparing safe copy from files"
        cp -arf $DP_MED_DEF_FILE "$DP_MED_DEF_FILE"_"$DATE_NOW"

echo "== Adjusting DP Mediation YAML"

echo "==== Adjusting the description"
	sed -i s/'description: dpmediation'/'description: DP_HA-dpmediation'/g $DP_MED_DEF_FILE

echo "==== Adjusting the nat_combined_security_groups param"
	DP_MED_NAT_LINE=$(grep -n 'nat_combined_security_groups' $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
	DP_MED_NAT_LINE=$(($DP_MED_NAT_LINE+3))
	awk 'NR=="$DP_MED_NAT_LINE" {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
	EXT_SECURITY_GRP=$(cat $SED_FILE | grep enm_external_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
	INT_SECURITY_GRP=$(cat $SED_FILE | grep enm_internal_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
	DP_MED_NAT_LINE=$(($DP_MED_NAT_LINE-1))
	sed -i ""$DP_MED_NAT_LINE"a\    default: \""$INT_SECURITY_GRP,$EXT_SECURITY_GRP"\"" $DP_MED_DEF_FILE

echo "==== Adjusting the allowed_address_pairs param"
	DP_MED_ADDR_LINE=$(grep -n 'allowed_address_pairs' $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
	DP_MED_ADDR_LINE=$(($DP_MED_ADDR_LINE+3))
	awk 'NR=="$DP_MED_ADDR_LINE" {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
	DP_MED_ADDR_LINE=$(($DP_MED_ADDR_LINE-1))
	sed -i ""$DP_MED_ADDR_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $DP_MED_DEF_FILE

echo "==== Adjusting Gateway"
        DP_MED_ADDR_GW_LINE=$(grep -n 'parameters' $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
        awk 'NR=="$DP_MED_ADDR_GW_LINE" {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE 
        sed -i ""$DP_MED_ADDR_GW_LINE"a\  lvsrouter_internal_ip_list: \n    type: string\n" $DP_MED_DEF_FILE

echo "==== Adjusting the GATEWAY LVS IP"
	sed -i 's/get_param: svc_CM_vip_internal/get_param: lvsrouter_internal_ip_list/g' $DP_MED_DEF_FILE	

echo "==== Add the DISABLE HA conf on the launching"
        DP_MED_DISABLEHA_LINE=$(grep -n "sysctl -e -p" $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
        DP_MED_DISABLEHA_LINE=$(($DP_MED_DISABLEHA_LINE+1))
        awk 'NR=='"$DP_MED_DISABLEHA_LINE"' {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
        awk 'NR=='"$DP_MED_DISABLEHA_LINE"' {print "            - curl -X PUT -d \"0\" http://127.0.0.1:8500/v1/kv/enm/applications/lifecycle_management/services/sam_agents/'$DEPLOY_ID'-dpmediation-0_override_healthcheck;logger -s \"Disabling HA key on lauching\""}1' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE

echo "==== Backuping the files on  NFS mount point and configuring the crontab to disable-ha"
	DP_MED_NFS_LINE=$(grep -n 'curl -X PUT' $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
	DP_MED_NFS_LINE=$(($DP_MED_NFS_LINE+1))
	awk 'NR=='"$DP_MED_NFS_LINE"' {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
	DP_MED_NFS_LINE=$(($DP_MED_NFS_LINE+1))
        awk 'NR=='"$DP_MED_NFS_LINE"' {print "      - config: |\n          #cloud-config\n          merge_how: list(append)+dict(recurse_array,no_replace)+str()\n          write_files:\n            - path: /run/cloud-init/adjust-nfs-dp-ha.sh\n              owner: root:root\n              permissions: 0777\n              content : |\n                #!/bin/bash\n                logger -s \"adjust-nfs-dp-ha.sh - backuping folders\"; cp -arf /ericsson/tor/data/domainProxy /tmp; cp -arf /ericsson/tor/data/global.properties /tmp\n                logger -s \"adjust-nfs-dp-ha.sh - stop the autofs service\"; /etc/init.d/autofs stop\n                logger -s \"adjust-nfs-dp-ha.sh - umount ericsson/data\";umount /ericsson/tor/data\n                logger -s \"adjust-nfs-dp-ha.sh - create the locally folder\"; mkdir -p /ericsson/tor/data\n                logger -s \"adjust-nfs-dp-ha.sh - restore the backup on the locally folder\" ; cp -arf /tmp/domainProxy /ericsson/tor/data/; cp -arf /tmp/global.properties /ericsson/tor/data/\n                logger -s \"adjust-nfs-dp-ha.sh - start the autofs service\" ; /etc/init.d/autofs start\n\n            - path: /run/cloud-init/disable-ha-crontab.sh\n              owner: root:root\n              permissions: 0777\n              content : |\n                #!/bin/bash\n                logger -s \"disable-ha-crontab.sh - Creating disable_ha file on crontab\" ; touch /etc/cron.d/disable_ha\n                logger -s \"disable-ha-crontab.sh - Adding the task in disable_ha file\"\n                echo \"* * * * * root curl -X PUT -d \"0\" http://127.0.0.1:8500/v1/kv/enm/applications/lifecycle_management/services/sam_agents/\"$HOSTNAME\"_override_healthcheck; logger -s \"crontab - Disabling HA key on Consul Agent\"\" > /etc/cron.d/disable_ha\n          runcmd:\n            - /run/cloud-init/adjust-nfs-dp-ha.sh ; logger -s \"Finished adjust-nfs-dp-ha.sh script\"\n            - /run/cloud-init/disable-ha-crontab.sh ; logger -s \"Finished disable-ha-crontab.sh script\""}1' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE

echo "==== Adjusting the double quotes"
	DP_MED_PERM_LINE=$(grep -n "permissions: 0777" $DP_MED_DEF_FILE | cut -d: -f1 | head -n 1)
	sed -i "$DP_MED_PERM_LINE"d $DP_MED_DEF_FILE
        awk 'NR=='"$DP_MED_PERM_LINE"' {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
	DP_MED_PERM_LINE=$(($DP_MED_PERM_LINE-1))
	sed -i ""$DP_MED_PERM_LINE"a\              permissions: \'0777\'" $DP_MED_DEF_FILE
	DP_MED_PERM_LINE=$(($DP_MED_PERM_LINE+2))
        sed -i "$DP_MED_PERM_LINE"d $DP_MED_DEF_FILE

        DP_MED_PERM_LINE=$(grep -n "permissions: 0777" $DP_MED_DEF_FILE | cut -d: -f1 | head -n 1)
        sed -i "$DP_MED_PERM_LINE"d $DP_MED_DEF_FILE
        awk 'NR=='"$DP_MED_PERM_LINE"' {print " "} {print $0}' $DP_MED_DEF_FILE > $DP_MED_DEF_TMP_FILE && mv $DP_MED_DEF_TMP_FILE $DP_MED_DEF_FILE
        DP_MED_PERM_LINE=$(($DP_MED_PERM_LINE-1))
        sed -i ""$DP_MED_PERM_LINE"a\              permissions: \'0777\'" $DP_MED_DEF_FILE       
	DP_MED_PERM_LINE=$(($DP_MED_PERM_LINE+2))
	sed -i "$DP_MED_PERM_LINE"d $DP_MED_DEF_FILE
 
        DP_MED_QUOTE_LINE=$(grep -n "merge_how: list(append)+dict(recurse_array,no_replace)+str()" $DP_MED_DEF_FILE | head -n1 | cut -d: -f1)
        sed -i "$DP_MED_QUOTE_LINE"d $DP_MED_DEF_FILE
	DP_MED_QUOTE_LINE=$(($DP_MED_QUOTE_LINE-1))
        sed -i ""$DP_MED_QUOTE_LINE"a\          merge_how: \'list(append)+dict(recurse_array,no_replace)+str()\'" $DP_MED_DEF_FILE
	
}

Adjust_DP_MED_DEF
