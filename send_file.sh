#!/bin/bash

return=0
for file in $2/*; do 
    if [ ! -d $file ]
    then
        #echo $file
        sshpass -f /projects/config_file/sshpass scp $file root@$1:$3
        if [ $? -eq 0 ]; then
            return=1
            rm $file
        fi
    fi
done
echo $return
