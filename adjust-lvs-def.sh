#!/bin/bash
 
source ./variables.global
DATE_NOW=$(date +%F_%H%M%S)
DEPLOY_ID=$(cat $SED_FILE | grep deployment_id | cut -d: -f 2 | cut -d\" -f 2)
 
Adjust_LVS_DEF(){
 
echo "== Preparing safe copy from files"
        cp -arf $LVS_DEF_FILE "$LVS_DEF_FILE"_"$DATE_NOW"
 
echo "== Adjusting LVS_DEF YAML"
 
echo "==== Adjusting the description"
        sed -i s/'description: lvs'/'description: DP_HA-lvs'/g $LVS_DEF_FILE
 
echo "==== Adjusting the allowed_address_pairs param"
        LVS_DEF_ADDR_LINE=$(grep -n 'allowed_address_pairs' $LVS_DEF_FILE | head -n1 | cut -d: -f1)
        LVS_DEF_ADDR_LINE=$(($LVS_DEF_ADDR_LINE+3))
        awk 'NR=="$LVS_DEF_ADDR_LINE" {print " "} {print $0}' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE
        LVS_DEF_ADDR_LINE=$(($LVS_DEF_ADDR_LINE-1))
        sed -i ""$LVS_DEF_ADDR_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $LVS_DEF_FILE
 
echo "==== Adjusting the lvs_allowed_address_pairs param"
        LVS_DEF_ADDR1_LINE=$(grep -n 'lvs_allowed_address_pairs' $LVS_DEF_FILE | head -n1 | cut -d: -f1)
        LVS_DEF_ADDR1_LINE=$(($LVS_DEF_ADDR1_LINE+3))
        awk 'NR=="$LVS_ADDR1_LINE" {print " "} {print $0}' $LVS_DEF_FILE > $LVS_TMP_FILE && mv $LVS_TMP_FILE $LVS_DEF_FILE
        LVS_DEF_ADDR1_LINE=$(($LVS_DEF_ADDR1_LINE-1))
        sed -i ""$LVS_DEF_ADDR1_LINE"a\    default: \""0.0.0.0/0,::/0"\"" $LVS_DEF_FILE

echo "==== Adjusting the nat_combined_security_groups param"
        LVS_DEF_NAT_LINE=$(grep -n 'nat_combined_security_groups' $LVS_DEF_FILE | head -n1 | cut -d: -f1)
        LVS_DEF_NAT_LINE=$(($LVS_DEF_NAT_LINE+3))
        awk 'NR=="$LVS_DEF_NAT_LINE" {print " "} {print $0}' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE
        EXT_SECURITY_GRP=$(cat $SED_FILE | grep enm_external_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
        INT_SECURITY_GRP=$(cat $SED_FILE | grep enm_internal_security_group_name | cut -d: -f2 | sed s/\"//g | sed s/\,//g)
        LVS_DEF_NAT_LINE=$(($LVS_DEF_NAT_LINE-1))
        sed -i ""$LVS_DEF_NAT_LINE"a\    default: \""$INT_SECURITY_GRP,$EXT_SECURITY_GRP"\"" $LVS_DEF_FILE

echo "==== Disabling the keepalived"
echo "==== Add the DISABLE HA conf on the launching"
echo "==== Removing consul stop function on CONHAR script"
echo "==== Enable crontab for Disable HA key"
echo "==== Backuping the files from NFS mount point"
        LVS_NFS_LINE=$(grep -n '\- /run/cloud-init/config.sh' $LVS_DEF_FILE | head -n1 | cut -d: -f1)
        LVS_NFS_LINE=$(($LVS_NFS_LINE+1))
	awk 'NR=='"$LVS_NFS_LINE"' {print " "} {print $0}' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE
	LVS_NFS_LINE=$(($LVS_NFS_LINE+1))
        awk 'NR=='"$LVS_NFS_LINE"' {print "      - config: |\n          #cloud-config\n          merge_how: list(append)+dict(recurse_array,no_replace)+str()\n          write_files:\n            - path: /run/cloud-init/adjust-nfs-dp-ha.sh\n              owner: root:root\n              permissions: 0777\n              content : |\n                #!/bin/bash\n                logger -s \"adjust-nfs-dp-ha.sh - stop the autofs service\" ; systemctl stop autofs\n                logger -s \"adjust-nfs-dp-ha.sh - create the locally folder\" ; mkdir -p /ericsson/tor/data/lvsrouter_healthcheck/ ; mkdir -p /ericsson/tor/data/lvsrouter\n                logger -s \"adjust-nfs-dp-ha.sh - start the autofs service\" ; systemctl start autofs\n                logger -s \"adjust-nfs-dp-ha.sh - stop and disable ddc\" ; systemctl stop ddc ; systemctl disable ddc\n\n            - path: /run/cloud-init/disable-ha-crontab.sh\n              owner: root:root\n          permissions: 0777\n              content : |\n                #!/bin/bash\n                logger -s \"disable-ha-crontab.sh - Creating disable_ha file on crontab\" ; touch /etc/cron.d/disable_ha\n                logger -s \"disable-ha-crontab.sh - Adding the task in disable_ha file\" ; echo \"* * * * * root curl -X PUT -d \"0\" http://127.0.0.1:8500/v1/kv/enm/applications/lifecycle_management/services/sam_agents/\"$HOSTNAME\"_override_healthcheck; logger -s \"crontab - Disabling HA key on Consul Agent\"\" > /etc/cron.d/disable_ha\n\n          runcmd:\n            - sleep 120\n            - logger -s \"Stopping KeepAlived\" ; systemctl stop keepalived\n            - logger -s \"Disabling KeepAlived\"; systemctl disable keepalived\n            - logger -s \"Disabling HA on launch\" ; curl -X PUT -d \"0\" http://127.0.0.1:8500/v1/kv/enm/applications/lifecycle_management/services/sam_agents/'$DEPLOY_ID'-lvsrouter-0_override_healthcheck\n            - logger -s \"Removing stop_consul function on conhar\" ; sed -i 233,248d /ericsson/simple_availability_manager_agents/bin/conhar.py\n            - /run/cloud-init/adjust-nfs-dp-ha.sh ; logger -s \"Finished adjust-nfs-dp-ha.sh script\"\n            - /run/cloud-init/disable-ha-crontab.sh ; logger -s \"Finished disable-ha-crontab.sh script\"\n\n"}1' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE  && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE

echo "==== Adjusting the double quotes"
        LVS_PERM_LINE=$(grep -n "permissions: 0777" $LVS_DEF_FILE | cut -d: -f1 | head -n 1)
        sed -i "$LVS_PERM_LINE"d $LVS_DEF_FILE
        awk 'NR=='"$LVS_PERM_LINE"' {print " "} {print $0}' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE
        LVS_PERM_LINE=$(($LVS_PERM_LINE-1))
        sed -i ""$LVS_PERM_LINE"a\              permissions: \'0777\'" $LVS_DEF_FILE
	LVS_PERM_LINE=$(($LVS_PERM_LINE+2))
 	sed -i "$LVS_PERM_LINE"d $LVS_DEF_FILE

        LVS_PERM_LINE=$(grep -n "permissions: 0777" $LVS_DEF_FILE | cut -d: -f1 | head -n 1)
        sed -i "$LVS_PERM_LINE"d $LVS_DEF_FILE
        awk 'NR=='"$LVS_PERM_LINE"' {print " "} {print $0}' $LVS_DEF_FILE > $LVS_DEF_TMP_FILE && mv $LVS_DEF_TMP_FILE $LVS_DEF_FILE
        LVS_PERM_LINE=$(($LVS_PERM_LINE-1))
        sed -i ""$LVS_PERM_LINE"a\              permissions: \'0777\'" $LVS_DEF_FILE
        LVS_PERM_LINE=$(($LVS_PERM_LINE+2))
        sed -i "$LVS_PERM_LINE"d $LVS_DEF_FILE


        LVS_QUOTE_LINE=$(grep -n "merge_how: list(append)+dict(recurse_array,no_replace)+str()" $LVS_DEF_FILE | head -n1 | cut -d: -f1)
        sed -i "$LVS_QUOTE_LINE"d $LVS_DEF_FILE
	LVS_QUOTE_LINE=$(($LVS_QUOTE_LINE-1))
        sed -i ""$LVS_QUOTE_LINE"a\          merge_how: \'list(append)+dict(recurse_array,no_replace)+str()\'" $LVS_DEF_FILE


}
Adjust_LVS_DEF
