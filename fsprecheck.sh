#!/usr/bin/bash

pre_check_config=/tmp/fsinfo
SHOWMOUNT="/sbin/showmount -e "

# To verify the availability of config file.
if [ -f $pre_check_config ];
then
    echo "The pre-check info file $pre_check_config is available."
    sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $pre_check_config > /tmp/tempfile
    mv /tmp/tempfile $pre_check_config
    echo
else
    echo "The pre-check info file is missing, aborting....."
    exit 0
fi



# To verify if the vfiler is pingable
ping_vfiler()
{
    IP=$1
    unset pingresult
    ping6 -c2 $IP 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]
    then
      pingresult=0
    else
      pingresult=1
    fi
}


# To verify if the destination qtree been exported to this server, and verify the permission.
chk_dest_export()
{
    $SHOWMOUNT $1 | grep $2 | egrep "$securitycluster|everyone" >/dev/null 2>&1
    if [ $? -eq 0 ];
    then
        echo "FMO $2 is exported from the filer $1"
        tempmntdir=`echo $2 | awk -F"/" '{print $NF}'`
        echo "Creating temp direcotry in /mnt/$tempmntdir."
        [ ! -d /mnt/$tempmntdir ] && mkdir /mnt/$tempmntdir
        echo "Mounting FMO qtree ....."
        mount [$1]:$2 /mnt/$tempmntdir
        df -hPT /mnt/$tempmntdir
        destqtreesize=`df -hPT | grep /mnt/$tempmntdir | awk '{print $3}'`
        echo "FMO qtree size is $destqtreesize"
	echo
        echo "Unmount and remove the temporary mount."
        umount /mnt/$tempmntdir
        rmdir /mnt/$tempmntdir
    else
        echo "!!!!!!!!!! $destqtree NOT FOUND from FMO filer $destfilerip. !!!!!!!!!!"
        echo
    fi
}


# To verify if the CMO is mounted OR exported but not currently mounted.
chk_src_qtree()
{
    mountcnt=`df -hPT | grep $2 | wc -l`
    if [[ $mountcnt -eq 1 ]];
    then
        echo "CMO Qtree $2 is currently mounted."
        df -hPT | grep $2
        srcqtreesize=`df -hPT | grep $2 | awk '{print $3}'`
        echo "CMO qtree size is $srcqtreesize"
        echo
    elif [[ $mountcnt -eq 0 ]];
    then
        nomount_cnt=`$SHOWMOUNT $1 | grep $2 | egrep "$securitycluster|everyone" | wc -l`
        if [ $nomount_cnt -eq 0 ];
        then
            echo "!!!!!!!!!!!!!!!!!!!!! CMO Qtree $2 is not exported from vfiler !!!!!!!!!!!!!!!!!!"
        else
            echo "!!!!!!!!!!!!!!!! CMO Qtree $2 exported from vfiler but currently not mounted !!!!!!!!!!!!!"
	    echo "!!!!!!!!!!!!!!!!!!!!! proceeding with temp mount !!!!!!!!!!!!!!!!!!!!! "
	    tempmntdir=`echo $2 | awk -F"/" '{print $NF}'`
            echo "Creating temp direcotry in /mnt/$tempmntdir."
            [ ! -d /mnt/$tempmntdir ] && mkdir /mnt/$tempmntdir
            echo "Mounting the CMO qtree ....."
            mount [$1]:$2 /mnt/$tempmntdir
            df -hPT /mnt/$tempmntdir
            destqtreesize=`df -hPT | grep /mnt/$tempmntdir | awk '{print $3}'`
            echo "CMO qtree size is $destqtreesize"
            echo "Unmount and remove the temporary mount."
	    echo
            umount /mnt/$tempmntdir
            rmdir /mnt/$tempmntdir
        fi
    else
        echo "CMO Qtree $2 mounted up to direcotry level, additioanl care needed for actual migration."
        df -hPT | grep $2
	srcqtreesize=`df -hPT | grep $2 | tail -1 | awk '{print $3}'`
	echo "CMO qtree size is $srcqtreesize" 
        echo
    fi
}


########   MAIN  ##########
cat $pre_check_config | while read i
do
    servername=`echo $i | awk '{print $1}' | tr '[:upper:]' '[:lower:]'`
    srcqtree=`echo $i | awk '{print $2}' | tr '[:upper:]' '[:lower:]'`
    srcfullpath=`echo $i | awk '{print $3}' | tr '[:upper:]' '[:lower:]'`
    srcfilerip=`echo $i | awk '{print $4}' | tr '[:upper:]' '[:lower:]'`
    destqtree=`echo $i | awk '{print $5}' | tr '[:upper:]' '[:lower:]'`
    destfilerip=`echo $i | awk '{print $6}' | tr '[:upper:]' '[:lower:]'`
    securitycluster=`cat /var/AppCom/etc/frame.AppCom.config | grep SEC-CLUSTER | awk -F": " '{print $2}'`
    tstamp=`date +"%Y-%m-%d"`
	
    echo
    echo " ================================================================================================"
    echo " Working on CMO qtree : $srcqtree   VS   FMO qtree : $destqtree "
    echo " ================================================================================================"

    if [[ $servername == `hostname` ]];
    then
        [ ! -d /tmp/$servername/pre_migration ] && mkdir -p /tmp/$servername/pre_migration
        [ ! -f /tmp/$servername/pre_migration/pre_df_${tstamp} ] && df -hPT > /tmp/$servername/pre_migration/pre_df_${tstamp}
        [ ! -f /tmp/$servername/pre_migration/pre_mount_$tstamp ] && mount > /tmp/$servername/pre_migration/pre_mount_${tstamp}

        ping_vfiler $srcfilerip
        if [[ $pingresult -eq 0 ]];
        then
            echo "CMO vfiler is pingable. /tmp/$servername/pre_migration/pre_CMOshowmount_${srcfilerip}_${tstamp}"
            [ ! -f /tmp/$servername/pre_migration/pre_CMOshowmount_${srcfilerip}_${tstamp} ] && $SHOWMOUNT $srcfilerip > /tmp/$servername/pre_migration/pre_CMOshowmount_${srcfilerip}_${tstamp}
            chk_src_qtree $srcfilerip $srcfullpath
        else
            echo "!!!!!!!!! CMO vfiler is not reachable !!!!!!!!"
            echo
        fi

        ping_vfiler $destfilerip
        if [[ $pingresult -eq 0 ]];
        then
            echo "FMO vfiler is pingable."
            [ ! -f /tmp/$servername/pre_migration/pre_FMOshowmount_${destfilerip}_${tstamp} ] && $SHOWMOUNT $destfilerip > /tmp/$servername/pre_migration/pre_FMOshowmount_${destfilerip}_${tstamp}
            chk_dest_export $destfilerip $destqtree
        else
            echo "!!!!!!!!! FMO vfiler is not reachable !!!!!!!!"
            echo
        fi
    else
        echo "The fsinfo file is checking on $servername, but you're in `hostname`, skipping...."
        echo
        continue
    fi
done

