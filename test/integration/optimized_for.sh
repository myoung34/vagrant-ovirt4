#!/bin/bash
bios_serial=$(vagrant ssh -c 'sudo dmidecode -s system-serial-number' 2>/dev/null | tail  -n 1 | sed 's/[\r\n]//g')
vm_id=$(curl --silent -k -L --user "${OVIRT_USERNAME}:${OVIRT_PASSWORD}" --header 'Content-Type: application/xml' --header 'Accept: application/xml' ${OVIRT_URL}/vms | xmllint --xpath 'string(./vms/vm[./serial_number/value/text() = "'$bios_serial'"]/@id)' -)
curl --silent -k -L --user "${OVIRT_USERNAME}:${OVIRT_PASSWORD}" --header 'Content-Type: application/xml' --header 'Accept: application/xml' ${OVIRT_URL}/vms/${vm_id}  | xmllint --xpath './vm/type/text()' - | grep server
