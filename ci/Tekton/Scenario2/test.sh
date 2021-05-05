#!/usr/bin/env bash

cat output3.json | wc -c > output3.json.wc

read charCount < output3.json.wc

echo $charCount

if test $charCount -gt 10

then

    jq '.alerts[].policy.enforcementActions[] | select (. | contains("FAIL_BUILD_ENFORCEMENT"))' output3.json 2>/dev/null | wc -c > temp-wc

    read charCount < temp-wc

    echo $charCount

    if test $charCount -gt 2
        
    then

    ## Issue found is enough to stop the CI process

        failTask="true"

        echo "-- Build will be halted --"

    else

      echo "-- Policy violations will not stop the build process --"

    fi

    numberAlerts=`jq '.alerts' output2.json | jq length` 

    echo "Number of alerts $numberAlerts"

    counter=0

    # $numberAlerts

    while [ $counter -lt $numberAlerts ]
    do
  
      jqCommand="jq --argjson index "$counter" '.alerts[\$index].policy.name' output2.json"

      alertPolicyName=`eval $jqCommand` > /dev/null

      alertPolicyName=`echo $alertPolicyName | sed 's/\"//g'`

      echo "Policy Name : $alertPolicyName" 

      numberViolationsCmd="jq --argjson index \"$counter\" '.alerts[\$index].violations' output2.json | jq length"
     
      numberViolations=`eval $numberViolationsCmd` >> /dev/null

      violationCounter=0

      while [ "$violationCounter" -lt "$numberViolations" ]
      do

        jqCommand="jq --argjson index "$counter" --argjson violationIndex "$violationCounter" '.alerts[\$index].violations[\$violationIndex].message' output2.json"

        violation=`eval $jqCommand` >> /dev/null

        echo "violation : -- $violation"

        echo "---------------------------------------------------"

        violationCounter=`expr $violationCounter + 1`

      done

      counter=`expr $counter + 1`

    done

    echo $failTask
fi