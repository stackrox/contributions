@filesToScanList = split("\n", `ls *.scan-result`);
$numberFilesToScan = @filesToScanList;
$cleanFiles = 0;
$totalPolicyFailures = 0;

foreach $file (@filesToScanList) {
  open scanFileHandle, $file;
  $fileData = "";
  while (eof(scanFileHandle) == 0) {
    read scanFileHandle, $fileBuffer, 100;
    $fileData = join('', $fileData, $fileBuffer);
  }
  close scanFileHandle;
  $scannedFileName = substr($file, 0, index($file, ".scan-result"));
  $policiesFailed = "";
  $policyFailures = 0;
  if ($fileData eq "The scanned resources passed all policies\n") {
    print $scannedFileName." passes app policies.\n";
    $cleanFiles++;
  } else {
    @splitResultLines = split("\n", $fileData);

    foreach $_ (@splitResultLines) {
      if (m/failed policy/) {
        $policyFailed = substr($_, index($_, "\'"));
        $policyFailed =~ s/\'//g;
        $policiesFailed .= "\t".$policyFailed."\n";
        $policyFailures++;

        $UniquePolicyFailures{$policyFailed} = $UniquePolicyFailures{$policyFailed} + 1;

      }
    }
    $totalPolicyFailures += $policyFailures;
  }
  if ($policyFailures > 0) {
    print $scannedFileName." has ".$policyFailures." policy failures :: \n";
    print $policiesFailed;
  }
  print "-------------------------------------------------------------------------------\n";
}
  print "Files passing all policies : ".$cleanFiles." of ".$numberFilesToScan."\n";
  print "Total failures : ".$totalPolicyFailures."\n";
  print "Unique policy violations : ".keys(%UniquePolicyFailures)."\n";

  exit($totalPolicyFailures);
