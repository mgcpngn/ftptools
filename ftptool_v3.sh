#!/bin/bash
export PATH
LANG=en_US.UTF-8

if [ $(whoami) != "root" ];then
	echo "请使用root权限执行vsftp安装命令！"
	exit 1;
fi
Setup_vsftpd_soft(){
	soft=$(rpm -q vsftpd)
	if [[ $soft =~ "not" ]];then
      echo "正在安装vsftpd服务器软件。。。。。"
	if [ -f /etc/redhat-release ]; then
		OSInfo='RedHat'
		sudo yum install vsftpd -y
		sudo systemctl enable vsftpd
		sudo systemctl start vsftpd
		sudo systemctl status vsftpd
	elif [ -f /etc/SuSE-release ]; then
		OSInfo='SuSe'
		sudo apt-get install vsftpd
	elif [ -f /etc/debian_version ]; then
		OSInfo='Debian'
		sudo apt-get update
		sudo apt-get install vsftpd
	else
		echo "False"
	fi
    fi
}
Setup_Firewall(){
	echo "starting setup firewall..."
	firewall-cmd --zone=public --permanent --add-port=21/tcp
	firewall-cmd --zone=public --permanent --add-service=ftp
	firewall-cmd --zone=public --permanent --add-port=6000-6010/tcp
	firewall-cmd --reload
}
Setup_vsftpd_conf_pasv(){
	echo "starting setup vsftpd"
	tee /etc/vsftpd/vsftpd.conf <<-'EOF'
		anonymous_enable=NO
		local_enable=YES
		write_enable=YES
		local_umask=022
		dirmessage_enable=YES
		xferlog_enable=YES
		xferlog_std_format=YES
		xferlog_file=/var/log/vsftp
		dual_log_enable=YES
		vsftpd_log_file=/var/log/vsftpd.log
		connect_from_port_20=NO
		xferlog_file=/var/log/xferlog
		xferlog_std_format=YES
		chroot_local_user=YES
		allow_writeable_chroot=YES
		listen=NO
		listen_ipv6=YES
		
		pasv_enable=yes
		pasv_max_port=6010
		pasv_min_port=6000
		pam_service_name=vsftpd
		userlist_enable=YES
		userlist_file=/etc/vsftpd/user_list
		userlist_deny=NO
		tcp_wrappers=YES
	EOF
}
echo "#####################################"
echo "#      FTP 安装配置工具  v1.0   #"
echo "#####################################"
echo "襄阳电信政企客户支撑中心云网出品脚本"
echo "     作者：王理             "
echo "     联系：18162812207         "
echo "------------------------------------"
echo "*   Enter 'i' to 安装FTP服务"
echo "*   Enter 'u' to 删除FTP服务"
echo "------------------------------------"
echo -e "*   Enter your option: " | tr -d '\n'
read option

if [ $option == i ]; then
	read -p "请输入ftp登录用户名: " fname
	read -p "请输入ftp登录密码:" fpass
  Setup_vsftpd_soft
  Setup_Firewall
  Setup_vsftpd_conf_pasv
	echo "starting setup ftp user...."
	useradd $fname -d /home/$fname -s /bin/bash
	chown $fname:$fname /home/$fname -R
	echo $fpass | passwd $fname --stdin
	echo $fname | tee -a /etc/vsftpd/user_list
	echo "starting setup ftp directory...."
	mkdir -p /home/$fname/ftp/upload
	chmod 750 /home/$fname/ftp/upload
	chgrp $fname /home/$fname/ftp/upload
	echo "restart ftp service..."
	systemctl restart vsftpd
	echo "祝贺你，ftp被动模式设置成功"
	echo "如果在云上部署，请不要忘记在安全组中放通以下TCP端口：21,20,6000-6010"
	echo "Your FTP username is: "$fname
	echo "Your FTP password is: "$fpass
	echo "现在可以通过ftp访问了！！！！"
elif [ $option == u ]; then
	if [ -f /etc/redhat-release ]; then
		OSInfo='RedHat'
		read -p "请输入ftp登录用户名: " fname
		firewall-cmd --zone=public --permanent --remove-port=21/tcp
		firewall-cmd --zone=public --permanent --remove-service=ftp
		firewall-cmd --zone=public --permanent --remove-port=6000-6010/tcp
		firewall-cmd --reload
		sudo systemctl stop vsftpd
		sudo systemctl disable vsftpd
		sudo yum remove vsftpd -y
		userdel $fname
		rm -rf /etc/vsftpd/*
	elif [ -f /etc/SuSE-release ]; then
		OSInfo='SuSe'
		sudo apt-get remove vsftpd
	elif [ -f /etc/debian_version ]; then
		OSInfo='Debian'
		sudo apt-get remove vsftpd
	else
		echo "False"
	fi
	echo -e "你已经成功卸载安装vsftp服务器！"
fi
