#!/bin/bash

#!/bin/bash

/usr/local/bin/tanzu plugin list > /dev/null 2>&1; ret=$?
stt=$(/usr/local/bin/tanzu plugin list -o json | jq -r '.[] | select(.name == "management-cluster").status')
if [ $ret -ne 0 -o "$stt" == "not installed" ]; then
  cd /tanzu && tanzu plugin clean
  cd /tanzu && tanzu plugin install --local cli all
fi

exit 0
