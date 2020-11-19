import requests
import json
import os
import stat
import subprocess

def image_check(request):
    """Checks an image with roxctl
    Args:
        JSON array with 
            `rox_central_endpoint` -- the hostname/IP and port for Central (`central.stackrox.com:443`)
            `rox_api_token` -- an API token from Central with at least CI privileges
            `rox_image` -- the image to scan (`registry.stackrox.local/frontend:1.5.1`)
    Returns:
        JSON array with
            `build` -- either `pass` or `fail` to indicate if any policies are enforced
            `output` -- the output of `roxctl image check`
    """
    request_json = request.get_json()
    
    rox_central_endpoint = request_json['rox_central_endpoint']
    rox_api_token = request_json['rox_api_token']
    rox_image = request_json['rox_image']

    print("Using roxctl to scan image: " + rox_image)

    download_roxctl(rox_central_endpoint, rox_api_token)

    out,err = roxctl_image_check(rox_central_endpoint, rox_api_token, rox_image)

    if err == 0:
        err_text = "pass"
    else:
        err_text = "fail"

    json_return = {"build": err_text, "output": out.decode("utf-8")}

    return json.dumps(json_return)

def download_roxctl(rox_central_endpoint, rox_api_token):
    url = "https://" + rox_central_endpoint + "/api/cli/download/roxctl-linux"
    token = "Bearer " + rox_api_token 
    print("token: " + token)
    headers = {'Authorization': token}
    r = requests.get(url, headers=headers)
    open('/tmp/roxctl', 'wb').write(r.content)
    st = os.stat('/tmp/roxctl')
    os.chmod('/tmp/roxctl', st.st_mode | stat.S_IEXEC)


def roxctl_image_check(rox_central_endpoint, rox_api_token, rox_image):
    os.environ["ROX_API_TOKEN"] = rox_api_token
    roxctl = subprocess.Popen(['/tmp/roxctl', 'image', 'check', '-e', rox_central_endpoint, '--image', rox_image], 
           stdout=subprocess.PIPE, 
           stderr=subprocess.STDOUT)
    out, err = roxctl.communicate()
    return out, roxctl.returncode