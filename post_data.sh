#!/bin/bash

script_dir=/projects/amr/scripts
project_dir=/projects/amr
config_file_dir=/projects/config_file
server=$config_file_dir/server_ip.txt
location_file=$config_file_dir/location.cfg
lp_dir="/var/txtalert/lp"
remote_lp_dir="/var/www/html/lp/upload/lp"
lp_block0_dir="/var/txtalert/lp/block0"
hist_dir="/var/txtalert/hist"
log_dir="/projects/amr/meter/buffer"
amr_url=$(cat $server)
files=$log_dir
touch /tmp/post_data

defaults_dir=$config_file_dir/defaults.cfg
while IFS= read -r line;
do
	param=$(echo $line |awk -F= '{print $1}' |tr -d " \"\t\r\n")
	value=$(echo $line |awk -F= '{print $2}' |tr -d " \"\t\r\n")
	#echo -e "*"$param"*"$value"*"
	if [ "$param" == "lp_dir" ]
	then	
		if [ ! -d $value ];then
			echo $value does not exist... creating dir.
			mkdir $value
		fi
		lp_dir=$value"/lp"
		lp_block0_dir=$value"/lp/block0"
		hist_dir=$value"/hist"	
		
		#echo $lp_dir
		#echo $lp_block0_dir
		#echo $hist_dir
	fi
	
	if [ "$param" == "log_dir" ];
	then
		if [ ! -d $value ];then
			echo $value does not exist... creating dir.
			mkdir $value
		fi
		log_dir=$value
		#echo $log_dir
	fi
	
	if [ "$param" == "location" ];
	then
		location=$value
	fi

	if [ "$param" == "remote_lp_dir" ];
	then
		remote_lp_dir=$value
	fi
	
done <$defaults_dir

while IFS= read -r line;
do
	param=$(echo $line |awk -F= '{print $1}' |tr -d " \"\t\r\n")
	value=$(echo $line |awk -F= '{print $2}' |tr -d " \"\t\r\n")
	if [ "$param" == "location" ]
	then	
		location=$value
		
	fi
done < $location_file

while [ : ]
do
	if [ -f $server ]; then
		file_cnt=$(ls -A $files |wc -l)
		#echo $file_cnt
		if [ $file_cnt -gt 3 ]; then
			url=`cat $server`
			if [ -z "$url" ];then
				url="0"
			fi
			echo "Server   	:" $url
			echo "Meter Log Dir	:" $log_dir
			echo "LP Log Dir	:" $location
			php -f $project_dir/meter/http_postClient.php $url $log_dir 0
		fi

		running=0
		pidof amr_gateway
		instance=$?
		if [ $instance -eq 0 ]; then
			running=1
		else
			sleep 2
			pidof amr_gateway
			instance=$?
			if [ $instance -eq 0 ]; then
				running=1
			fi
		fi

		if [ $running -eq 0 ]; then #execute only if amr_gateway is not running
			#echo "amr_gateway not running"
			if [ -d $lp_dir ]; then
				if [ "$(find $lp_dir -type f)" ]; then
					#  php -f $project_dir/meter/send_file.php $amr_url $lp_block0_dir 'lp/'$location 1
					#  php -f $project_dir/meter/send_file.php $amr_url $lp_dir 'lp/'$location 1
					#  php -f $project_dir/meter/send_file.php $amr_url $hist_dir 'history/'$location 1
					# #$script_dir/upload_lp.sh $amr_url '/var/www/html/lp/upload/lp/'$location $lp_dir 
					return=$(/projects/amr/meter/send_file.sh $amr_url $lp_dir $remote_lp_dir/$location)					
					if [ $return == '1' ]; then
						echo 'Success...'
						if [ -f /tmp/lp_read ]; then
							rm /tmp/lp_read
						fi
					else
						echo 'no transfer...'
					fi
				fi
			fi
		fi
	fi
	sleep 60
done
