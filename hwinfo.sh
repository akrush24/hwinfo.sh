#!/bin/bash

# requirement
# - Linux
# - lshw
# - dmidecode
# - lspci

TAB='   '


# Check and install required packages
## update repo list
if [[ ! -f /etc/redhat-release ]]; then
    apt-get update > /dev/null
fi

for PKG in lshw dmidecode pciutils; do
        if [[ -f /etc/redhat-release ]]; then
            rpm -ql ${PKG} > /dev/null || yum install ${PKG} -y
        else
            dpkg-query -W ${PKG} > /dev/null || apt-get install ${PKG} -y
        fi
done


# Get system informations
SYSTEM_MANUFACTURER=$(dmidecode -s system-manufacturer)
SYSTEM_PRODUCT_NAME=$(dmidecode -s system-product-name)
SYSTEM_VERSION=$(dmidecode -s system-version)
SYSTEM_SERIAL_NUMBER=$(dmidecode -s system-serial-number)
BASEBOARD_PRODUCT_NAME=$(dmidecode -s baseboard-product-name)
BASEBOARD_SERIAL_NUMBER=$(dmidecode -s baseboard-serial-number)
PROCESSOR_NAME=$(
    dmidecode -s processor-version \
    | sort \
    | uniq -c \
    | sed -E 's/([ \t]+?)([0-9]+)([\ ]+)(.+)/\2 x \4/g' \
    | sed -e "s/^/${TAB}${TAB}/"
)
CPU_SOKETS=$(
    dmidecode --type processor \
    | grep -c 'Processor Information'
)
MEMORU_SLOT=$(
    dmidecode -t memory \
    | grep -c "^\sSize:"
)
MEMORY_INSTALLED=$(
    dmidecode -t memory \
    | tr -d '^[\t]' \
    | egrep 'Memory\ Device|Part\ Number|^\Size:|^Type:|^\sSpeed:' \
    | sed -e 's/[\ ]*$//g' \
    | sed -e 's/$/,/g' \
    | sed -e ':a;N;$!ba;s/\n/ /g;s/0d0a/\n/g' -e 's/Memory\ Device,/\n/g' \
    | grep -v ^$ \
    | sed -e 's/^.//g' -e 's/[ \t,]*$//g' \
    | sort \
    | uniq -c \
    | egrep -v 'No\ Module\ Installed|^$' \
    | sed -E 's/([ \t]+?)([0-9]+)([\ ]+)(.+)/\2 x \4/g' \
    | sed "s/^/${TAB}${TAB}/"
)
MEMORY_INSTALLED_COUNT=$(
    dmidecode -t memory \
    | grep "^\sSize:" \
    | grep -vc "No Module Installed"
)
POWER_COUNT=$(
    dmidecode --type 39 \
    | grep -c 'Name:'
)
POWER=$(
    dmidecode --type 39 \
    | egrep 'System\ Power\ Supply|Name:|Model\ Part\ Number|Max\ Power\ Capacity' \
    | sed -e 's/[\ ]*$//g' \
    | sed -e 's/$/,/g' \
    | sed -e ':a;N;$!ba;s/\n/ /g;s/0d0a/\n/g' -e 's/System\ Power\ Supply,/\n/g' \
    | grep -v ^$ \
    | sed -e 's/^.//g' -e 's/[ \t,]*$//g' \
    | sort \
    | uniq -c \
    | sed -E 's/([ \t]+?)([0-9]+)([\ ]+)(.+)/\2 x \4/g' \
    | sed -e 's/\t//g' -e "s/^/${TAB}${TAB}/"
)
NETWORK=$(
    lspci \
    | grep -i 'Ethernet controller'\
    | cut -f1 -d" " --complement \
    | sort \
    | uniq -c \
    | sed -E 's/([ \t]+?)([0-9]+)([\ ]+)(.+)/\2 x \4/g' \
    | sed "s/^/${TAB}/"
)
DISKS_INFO=$(
    lshw -class disk -short \
    | cut -f1 -d" " --complement \
    | sed -e 1,2d \
    |  cut -f1 -d" " --complement \
    | sed -e 's/^[\ ]*//g' \
    | cut -f1 -d" " --complement \
    | sed -e 's/^[\ ]*//g' \
    | cut -f1 -d" " --complement \
    | sed -e 's/^[\ ]*//g' \
    | sort \
    | uniq -c \
    | sed -E 's/([ \t]+?)([0-9]+)([\ ]+)(.+)/\2 x \4/g' \
    | sed "s/^/${TAB}/"
)


# show collected information
echo -e "PLATFORM:
${TAB}System manufacture: ${SYSTEM_MANUFACTURER} 
${TAB}Product name: ${SYSTEM_PRODUCT_NAME} 
${TAB}System version: ${SYSTEM_VERSION}
${TAB}System S/N: ${SYSTEM_SERIAL_NUMBER}
${TAB}Baseboard name: ${BASEBOARD_PRODUCT_NAME}
${TAB}Baseboard S/N: ${BASEBOARD_SERIAL_NUMBER}
CPU:
${TAB}Sockets: ${CPU_SOKETS}
${PROCESSOR_NAME}
MEMORY:
${TAB}Memory slots: ${MEMORU_SLOT}
${TAB}Memory installed: ${MEMORY_INSTALLED_COUNT}
${MEMORY_INSTALLED}
POWER SUPPLY:
${TAB}Power count: ${POWER_COUNT}
${POWER}
NETWORK:
${NETWORK}
DISKS:
${DISKS_INFO}
"