mkdir /ogg/oggbd
cp /ogg/OGG_BigData_Linux_x64_12.3.2.1.1.zip /ogg/oggbd
cd /ogg/oggbd
unzip OGG_BigData_Linux_x64_12.3.2.1.1.zip
tar -xf OGG_BigData_Linux_x64_12.3.2.1.1.tar

ggsci <<EOF
CREATE SUBDIRS
Exit
EOF

echo "PORT 7801" > ./dirprm/mgr.prm

ggsci <<EOF
START MGR
INFO MGR
Exit
EOF
