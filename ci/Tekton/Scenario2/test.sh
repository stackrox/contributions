#!/usr/bin/env bash

cat output2.json | wc -c > output2.json.wc

read charCount < output2.json.wc

if test $charCount -gt 10

then

    numberAlerts=`jq '.alerts' output2.json | jq length` 

    counter=0

    while [ $counter -lt $numberAlerts ]
    do

      jqCommandPolicyEnforcementCmd="jq --argjson index "$counter" '.alerts[\$index].policy.enforcementActions[] | select (. | contains(\"FAIL_BUILD_ENFORCEMENT\"))' output2.json 2>/dev/null | wc -c > temp-wc"

      eval $jqCommandPolicyEnforcementCmd > /dev/null

      jqCommandPolicyName="jq --argjson index "$counter" '.alerts[\$index].policy.name' output2.json"

      alertPolicyName=`eval $jqCommandPolicyName` > /dev/null

      alertPolicyName=`echo "$alertPolicyName" | sed s/\"//g`

      echo "Alert policy name : $alertPolicyName"

      read charCount < temp-wc

      if test $charCount -gt 2
          
      then

      ## Issue found is enough to stop the CI process

          failTask="true"

          echo "-- Build will be halted --"

      else

        echo "-- Policy violations will not stop the build process --"

      fi

      echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"

      numberViolationsCmd="jq --argjson index \"$counter\" '.alerts[\$index].violations' output2.json | jq length"
     
      numberViolations=`eval $numberViolationsCmd` >> /dev/null

      violationCounter=0

      while [ "$violationCounter" -lt "$numberViolations" ]
      do

        jqCommand="jq --argjson index "$counter" --argjson violationIndex "$violationCounter" '.alerts[\$index].violations[\$violationIndex].message' output2.json"

        violation=`eval $jqCommand` >> /dev/null

        violation=`echo "$violation" | sed s/\"//g`

        echo "violation : -- $violation"

        violationCounter=`expr $violationCounter + 1`

      done

      echo "---------------------------------------------------"

      echo ""

      counter=`expr $counter + 1`

    done

    echo $failTask
fi