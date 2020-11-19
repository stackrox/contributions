# Google Function CI Scan Sample
 

This sample uses a Google Function to scan an image and return results.  This is useful for scanning builds in hosted CI solutions when Central is not accessible from the Internet -- the function can be used as a proxy.
 
The `roxctl_image_check` directory has the sample Python function.  This script takes an HTTP POST with a JSON body containing the parameters and returns a pass/fail and the policy check output.

    Args:
        JSON array with 
            `rox_central_endpoint` -- the hostname/IP and port for Central (`central.stackrox.com:443`)
            `rox_api_token` -- an API token from Central with at least CI privileges
            `rox_image` -- the image to scan (`registry.stackrox.local/frontend:1.5.1`)
    Returns:
        JSON array with
            `build` -- either `pass` or `fail` to indicate if any policies are enforced
            `output` -- the output of `roxctl image check`

The `CI Integration sample` directory contains a sample CI integration for consuming this function in a CircleCI build pipeline.
  
OWNER:  neilcar

LATEST TESTED: 3.0.52.0