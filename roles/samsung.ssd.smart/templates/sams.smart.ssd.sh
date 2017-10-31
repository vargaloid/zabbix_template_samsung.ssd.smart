###Varg
#!/usr/bin/env bash

#Variables
DFILE="/tmp/z.sams.ssd.smart.discovery.txt"
IFILE="/tmp/z.sams.ssd.smart.items.txt"
LBA_SIZE="512"
BYTES_PER_TB="1099511627776"

#Create files
touch ${IFILE}
touch ${DFILE}
cp /dev/null ${IFILE}
chmod 664 ${IFILE}
chmod 664 ${DFILE}

#Make file with items
##Non-RAID values
DISKS=$(lsblk -S | grep "Samsung SSD"| grep "disk" | grep "ATA" | awk '{print $1}')

    for label in $DISKS
    do
    echo "$label Device" >> ${IFILE}
    echo -n "$label v5 " >> ${IFILE} && smartctl -A /dev/$label | grep "Reallocated_Sector_Ct" | awk '{print $10}' >> ${IFILE}
    echo -n "$label v9 " >> ${IFILE} && smartctl -A /dev/$label | grep "Power_On_Hours" | awk '{print $10}' >> ${IFILE}
    echo -n "$label v177 " >> ${IFILE} && smartctl -A /dev/$label | grep "Wear_Leveling_Count" | awk '{print $4}' >> ${IFILE}
    echo -n "$label v179 " >> ${IFILE} && smartctl -A /dev/$label | grep "Used_Rsvd_Blk_Cnt_Tot" | awk '{print $10}' >> ${IFILE}
    echo -n "$label v183 " >> ${IFILE} && smartctl -A /dev/$label | grep "Runtime_Bad_Block" | awk '{print $10}' >> ${IFILE}
    TOTAL_LBA_WRITTEN=$(smartctl -A /dev/$label | grep "Total_LBAs_Written" | awk '{print $10}')
    BYTES_WRITTEN=$(echo "$TOTAL_LBA_WRITTEN * $LBA_SIZE" | bc)
    TB_WRITTEN=$(echo "$BYTES_WRITTEN / $BYTES_PER_TB" | bc)
    echo "$label v241 $TB_WRITTEN" >> ${IFILE}
    done

##RAID values
DISKS_RAID=$(lsblk -S | grep "Samsung SSD" | grep "disk" | grep -v "ATA" | awk '{print $1}')

    if [ -n "$DISKS_RAID" ]
    then
    DISKS_RAID_ID=$(megacli -pdlist -a0| grep 'Device Id' | awk -F ': ' '{print $2}')
    	for raid_label in $DISKS_RAID
    	do
        	for megaraid_id in $DISKS_RAID_ID
        	do
			DISK_SAMS=$(smartctl -i -d sat+megaraid,$megaraid_id /dev/$raid_label | grep "Samsung SSD")
			if [ -n "$DISK_SAMS" ]
			then
				echo "${raid_label}.megaraid.$megaraid_id Device" >> ${IFILE}
    				echo -n "${raid_label}.megaraid.$megaraid_id v5 " >> ${IFILE} && smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Reallocated_Sector_Ct" | awk '{print $10}' >> ${IFILE}
    				echo -n "${raid_label}.megaraid.$megaraid_id v9 " >> ${IFILE} && smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Power_On_Hours" | awk '{print $10}' >> ${IFILE}
    				echo -n "${raid_label}.megaraid.$megaraid_id v177 " >> ${IFILE} && smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Wear_Leveling_Count" | awk '{print $4}' >> ${IFILE}
    				echo -n "${raid_label}.megaraid.$megaraid_id v179 " >> ${IFILE} && smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Used_Rsvd_Blk_Cnt_Tot" | awk '{print $10}' >> ${IFILE}
    				echo -n "${raid_label}.megaraid.$megaraid_id v183 " >> ${IFILE} && smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Runtime_Bad_Block" | awk '{print $10}' >> ${IFILE}
    				RAID_TOTAL_LBA_WRITTEN=$(smartctl -A -d sat+megaraid,$megaraid_id /dev/${raid_label} | grep "Total_LBAs_Written" | awk '{print $10}')
    				RAID_BYTES_WRITTEN=$(echo "$RAID_TOTAL_LBA_WRITTEN * $LBA_SIZE" | bc)
    				RAID_TB_WRITTEN=$(echo "$RAID_BYTES_WRITTEN / $BYTES_PER_TB" | bc)
    				echo "${raid_label}.megaraid.$megaraid_id v241 $RAID_TB_WRITTEN" >> ${IFILE}
        			
			fi
        	done
    	done
    fi

#Make file for discovery
echo '{ "data": [' > ${DFILE}

cat ${IFILE} | grep "Device" | awk '{print $1}' | while read LINE
    do
    echo "{\"{#DISK}\":\"$LINE\"}," >> ${DFILE}
    done

echo ']}' >> ${DFILE}

OMMALINE=$(cat ${DFILE} | wc -l)
OMMA=$(echo "${OMMALINE} - 1" | bc)
NEWDFILE=$(sed "${OMMA}s/,//" ${DFILE})
echo "${NEWDFILE}" > ${DFILE}

exit 0
