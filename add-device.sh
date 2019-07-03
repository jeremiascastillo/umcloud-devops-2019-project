#!/bin/bash

devices=("SJS5NQT-GRDZOFR-6YKWREJ-KPSUR45-4BAE3WY-CMAWB6U-XBEAXAL-S4OUDAK" "2C3REAL-R5PM3HN-PHAQ2WB-YL247U2-NQR2G7R-LV5PKIF-QOLHKZH-4CTCSAO" "XDDESZ7-VFXC6NJ-42W2EVK-LSV5QUG-PXMWQ2M-FKPLUV5-EXBQNTV-YHPIFA2" )
for i in ${devices[@]}
do
	cp config.xml config-tmp.xml
	if grep "<device id=\"$i\" name" config.xml;
	then
    	echo "$i"
	else
		c="<device id=\"$i\" name=\"\" compression=\"metadata\" introducer=\"false\" skipIntroductionRemovals=\"false\" introducedBy=\"\"><address>dynamic<\/address><paused>false<\/paused><autoAcceptFolders>true<\/autoAcceptFolders><maxSendKbps>0<\/maxSendKbps><maxRecvKbps>0<\/maxRecvKbps><maxRequestKiB>0<\/maxRequestKiB><\/device>"
		sed -i".back" -e"/<\/configuration>/ s/.*/$c\n&/" config.xml
	fi
done