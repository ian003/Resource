#!/bin/sh
#
#install a new swift storage
#
#all right reserved by ludaquan (ludaquan@cn.ibm.com)
#


#====================================================================
#usage
#	./xxx.sh
#====================================================================


#====================================================================
# function	install swift
#====================================================================
function install_swift(){
echo "yum install openstack-swift"
sleep 1
yum install openstack-swift -y

touch /etc/swift/swift.conf
cat ${BASE_DIR}/etc.conf/swift.conf > /etc/swift/swift.conf
sleep 1
}


#====================================================================
#function	set local ENV
#====================================================================i

function set_local_env(){
echo "set local env"
sleep 1
export BASE_DIR=$( pwd )
STORAGE_LOCAL_NET_IP=$( ifconfig |grep "inet addr" |grep -v "127.0.0.1"  |cut -d: -f2|awk '{print $1}' )
export STORAGE_LOCAL_NET_IP

export cmd=" ${cmd} ${zone}  ${STORAGE_LOCAL_NET_IP}"
echo "finish !"
sleep 1

}

#====================================================================
#function	configure and update local Repos
#====================================================================

function configure_update_Repos(){
echo "configure a local yum Repos"
sleep 1

touch "/etc/yum.repos.d/rhel-epel.repo"

echo "[rhel-epel]" > /etc/yum.repos.d/rhel-epel.repo
echo "name=rhel eple" >> /etc/yum.repos.d/rhel-epel.repo
echo "baseurl=http://192.168.0.20/cobbler/others/epel6/x86_64/" >> /etc/yum.repos.d/rhel-epel.repo
echo "enable=1" >> /etc/yum.repos.d/rhel-epel.repo
echo "gpgcheck=0">> /etc/yum.repos.d/rhel-epel.repo
echo "priority=1" >> /etc/yum.repos.d/rhel-epel.repo

yum update 

sleep 1

}


#====================================================================
# function:	install and configure openstack-swift-account
#====================================================================

function install_swift_account(){
echo "install and configure openstack-swift-account"
sleep 1

yum install openstack-swift-account -y
sleep 1

echo "configure openstack-swift-account ....."
sleep 1


touch /etc/swift/account-server.conf
sed "s#<IP_ADDRESS>#${STORAGE_LOCAL_NET_IP}#g" ${BASE_DIR}/etc.conf/account-server.conf > /etc/swift/account-server.conf


echo "complete !"
sleep 1
}

#====================================================================
# function	install and configure openstack-swift-container
#====================================================================

function install_swift_container(){
echo "install and configure openstack-swift-container"
sleep 1

yum install openstack-swift-container -y


echo "configure openstack-swift-container...."
sleep 1

touch /etc/swift/container-server.conf
sed "s#<IP_ADDRESS>#${STORAGE_LOCAL_NET_IP}#g" ${BASE_DIR}/etc.conf/container-server.conf > /etc/swift/container-server.conf
echo "finished!"
sleep 1

}


#====================================================================
# function	install and configure openstack-swift-object
#====================================================================

function install_swift_object(){
echo "install and configure openstack-swift-object"
sleep 1

yum install openstack-swift-object -y

echo "configure openstack-swift-object...."
sleep 1

touch  /etc/swift/object-server.conf
sed "s#<IP_ADDRESS>#${STORAGE_LOCAL_NET_IP}#g" ${BASE_DIR}/etc.conf/object-server.conf > /etc/swift/object-server.conf
echo "finished!"
sleep 1


}



#====================================================================
#function	install and configure  xfsprogs
#====================================================================

function install_xfsprogs(){
echo "install  xfsprogs"
sleep 1

yum install xfsprogs -y

echo "finished!"
sleep 1
}



#====================================================================
#function	format and mount disk
#====================================================================

function format_mount_disk(){
echo "format and mount disk"
sleep 1


#get disk list 
strArray=$( fdisk -l | grep "/dev/sd" |grep -v "sda" )
disks[0]=""
diskCount=0

for disk in ${strArray}
        do
                i=${#disk}
                if [ $i -eq 9 ]
                then
                        disks[${diskCount}]=${disk:5:3}
                        let "diskCount=${diskCount} + 1"
                fi

        done

#start to format and mount
for disk in ${disks[@]}
        do
                mkfs.xfs -f  -i size=1024 /dev/${disk}
                echo "/dev/${disk} /srv/node/${disk} xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
                mkdir -p /srv/node/${disk}
                mount /srv/node/${disk}
        done

chown -R swift:swift /srv/node

echo "finished !"
sleep 1


}


#====================================================================
#function	configure rsyncd
#====================================================================
function configure_rsyncd(){
echo "configure rsyncd"

touch /etc/rsyncd.conf
sed "s#<IP_ADDRESS>#${STORAGE_LOCAL_NET_IP}#g" ${BASE_DIR}/etc.conf/rsyncd.conf > /etc/rsyncd.conf
echo "finished !"
sleep 1
}






#====================================================================
#function	start all swift  service
#====================================================================

function start_swift_all_server(){
echo "start all swift serivce"
sleep 1
chown -R swift:swift /etc/swift
swift-init all start 

echo "finished!"
sleep 1
}


#====================================================================
#function	configure swift storage log
#====================================================================

function swift_storage_log(){
echo "configure swift storage log" 
sleep 1

touch /etc/rsyslog.d/swift.conf

echo "local1,local2,local3.*   /var/log/swift/all.log" > /etc/rsyslog.d/swift.conf
echo "local1.*   /var/log/swift/object.log" >> /etc/rsyslog.d/swift.conf
echo "local2.*   /var/log/swift/container.log" >> /etc/rsyslog.d/swift.conf
echo "local3.*   /var/log/swift/account.log" >> /etc/rsyslog.d/swift.conf

mkdir -p /var/log/swift
service rsyslog restart

echo "finished!"
sleep 1

}


#====================================================================
#function mkdir swift recon cache 
#====================================================================
function swift_recon(){
echo "create /var/cache/swift!"
sleep 1

mkdir /var/cache/swift

chown swift:swift /var/cache/swift

echo "finished !"
sleep 1

}

#====================================================================
#function       rmdir .ssh if exist 
#====================================================================
function rmdir_ssh(){
echo "rmdir /root/.ssh"
sleep 1

if [ -d /root/.ssh ]
then
        rm -rf /root/.ssh
fi

}


	set_local_env
#	configure_update_Repos
	install_swift
	install_swift_account
	install_swift_container
	install_swift_object
	install_xfsprogs
	configure_rsyncd
	format_mount_disk
	swift_storage_log
	swift_recon
	rmdir_ssh

