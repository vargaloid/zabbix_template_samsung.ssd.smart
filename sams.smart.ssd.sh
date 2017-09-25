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
