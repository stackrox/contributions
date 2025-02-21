from httpx import AsyncClient,HTTPError,NetworkError,RequestError,TimeoutException,ConnectTimeout,InvalidURL,ProtocolError,ConnectError
import os
#from httpx._config import SSLConfig
from logging import getLogger, config
import typing as t
import asyncio


import logging
try:
    logger = getLogger("logger_root")
except:
    logger = logging.getLogger(__name__)

class PaginationCounter:
  
    def __init__(self, total_count, limit):
        
        self.limit = limit
        if not total_count:
            raise ValueError("total_count value should be specified")
        if not self.limit:
            raise ValueError("limit value should be specified")
        self.end = total_count
        self.start = 0 - self.limit

    def __iter__(self):
        return self

    def __next__(self):
        if self.start < self.end:
            if self.start + self.limit > self.end:
                self.start=self.end
            else:
                self.start += self.limit
            return self.start
        else:
            raise StopIteration
      
async def make_request(
    client,
    full_url_path,
    insecure: bool = False,
    headers: dict = None,
    params: dict = None,
    offset = None
) -> dict:
    """Make a request to the API"""
    error=None
    response=None
    local_client=False
    
    #TODO: Clean offset and params
    if offset is not None:
        params["pagination.offset"] = offset
        
    if client is None:
        logger.debug(f"make_request - client is None,will create a new client")
        client = AsyncClient(verify=insecure)
        local_client=True
  
    try:
        response = await client.get(
            f"{full_url_path}",headers=headers,params=params           
        )
        logger.debug(f"request_processing - attempted request")
        response.raise_for_status()       
    except ConnectTimeout as timeout_err:
        logger.error(f" Connect Timeout error occurred: {timeout_err}")
        error=f"Connect Timeout error occurred: {timeout_err}"
    except NetworkError as network_err:
        logger.error(f"Network error occurred: {network_err}")
        error=f"Network error occurred: {network_err}"
    except TimeoutException as timeout_err:
        logger.error(f"Timeout error occurred: {timeout_err}")
        error=f"Timeout error occurred: {timeout_err}"
    except RequestError as req_err:
        logger.error(f"Error occurred while processing request: {req_err}")
        error=f"Error occurred while processing request: {req_err}"
    except InvalidURL as url_err:
        logger.error(f"Invalid URL error occurred: {url_err}")
        error=f"Invalid URL error occurred: {url_err}"
    except HTTPError as http_err:
        logger.error(f"HTTP error occurred: {http_err}")
        error=f"HTTP error occurred: {http_err}"
    except IOError as e:
        logger.error("I/O error({0}): {1}".format(e.errno, e.strerror)) 
    except BaseException as e:
        print("Something serious has occurred")
        error=f"Something Seriously unexpected has occurred"  
    finally:
        if local_client:
            await client.aclose()     
                
    return {"response_object":response,"error_object":error} 

async def request_processing_pagination(client,full_url_path,insecure:bool=False,headers:dict=None,params:dict=None):
    """
    Args:
        client (AsyncClient): httpx AsyncClient object for making requests
        full_url_path (_type_): ACS URL with path for the request
        insecure (bool, optional): Make an insecure Request, Should be set from verify_endpoint_ssl on endpoint object
        headers (dict, optional): Headers for Request to ACS. Defaults to None.
        params (dict, optional): Parameters for Request to ACS. Defaults to None.

    """

    try:
        total_expected_count = params["pagination.total_expected_count"]
        del params["pagination.total_expected_count"]
    except KeyError as error:
        logger.error(f"pagination.total_expected_count not found in params,Method is only for paginated requests")
        return 
    
    if total_expected_count == 0:
        logger.error(f"pagination.total_expected_count is 0,Method is only for paginated requests")
        return
    
    if "pagination.limit" not in params:
        logger.error(f"pagination.limit not found in params,Method is only for paginated requests")
        return 
        
    if "pagination.offset" not in params:
        params["pagination.offset"] = 0
    
    if total_expected_count is None:
        logger.error(f"pagination.total_expected_count not found in params,Method is only for paginated requests")
        return
        
    #TODO: Requires streamline for offset and params
    response_dict={"response_object":[],"error_object":None}
    for offset in PaginationCounter(total_expected_count,params["pagination.limit"]):
        params.update({"pagination.offset":offset})
        temp_dict = await make_request(client,full_url_path,insecure,headers,params)
        
        if temp_dict["error_object"] is not None:
            return temp_dict["error_object"]
        else:
            response_dict["response_object"].append(temp_dict["response_object"])
    return response_dict
        
async def request_processing(client,full_url_path,insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """Send the Request and process the response"""
    logger.debug(f"request_processing -start: url:{full_url_path} verify_ssl:{insecure}")
    error=None
    response_dict={"response_object":[],"error_object":None}
    
    if params is None:
        response_dict = await make_request(client,full_url_path,insecure,headers,params)
    else:
        if "pagination.limit" in params and "total_expected_count" in params:
            response_dict = await request_processing_pagination(client,full_url_path,insecure,headers,params)
        else:
            response_dict = await make_request(client,full_url_path,insecure,headers,params)
    
    return response_dict

async def get_acs_alert(client,url,alert_id: str,insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """Get ACS alert from the API"""
    if alert_id is not None:
        logger.debug(f"get_acs_alert -start: url:{url} id:{alert_id} verify_ssl:{insecure}")
        rhacs_alert_url_path=f"{url}/v1/alerts/{alert_id}"
    else:
        logger.debug(f"get_acs_alert -start: url:{url} verify_ssl:{insecure}")
        rhacs_alert_url_path=f"{url}/v1/alerts"
    response_dict = await request_processing(client,rhacs_alert_url_path,insecure,headers,params)
    logger.debug(f"get_acs_alert - complete")
    return response_dict

async def get_policy(client,url,insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """Get Policy from the API"""
    logger.debug(f"get_policy -start: url:{url} verify_ssl:{insecure}")
    rhacs_policy_url_path=f"{url}/v1/policies"
    response_dict = await request_processing(client,rhacs_policy_url_path,insecure,headers,params)
    logger.debug(f"get_policy - complete")
    return response_dict

async def get_alert_count(client,url,insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """Get Alert Count"""
    logger.debug(f"get_policy -start: url:{url} verify_ssl:{insecure}")
    rhacs_policy_url_path=f"{url}/v1/alertscount"
    response_dict = await request_processing(client,rhacs_policy_url_path,insecure,headers,params)
    logger.debug(f"get_policy - complete")
    return response_dict    
    
async def get_acs_deployment(client,url,deployment_id:str, insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """Get Deployment from the API"""
    if deployment_id is not None:
        logger.debug(f"get_acs_alert -start: url:{url} id:{deployment_id} verify_ssl:{insecure}")
        rhacs_deployment_url_path=f"{url}/v1/deployments/{deployment_id}"
    else:
        logger.debug(f"get_acs_alert -start: url:{url} verify_ssl:{insecure}")
        rhacs_deployment_url_path=f"{url}/v1/deployments"
        
    logger.debug(f"get_deployment -start: url:{url}")
    response_dict = await request_processing(client,rhacs_deployment_url_path,insecure,headers,params)
    logger.debug(f"get_deployment - complete")
    return response_dict

async def get_rhacs_health(client,url,insecure:bool=False,headers:dict=None,params:dict=None) -> dict:
    """
    Asynchronously retrieves the health status of RHACS (Red Hat Advanced Cluster Security).
    Args:
        client: The HTTP client to use for making the request.
        url (str): The base URL for the RHACS instance.
        insecure (bool, optional): Whether to ignore SSL certificate verification. Defaults to False.
        headers (dict, optional): Additional headers to include in the request. Defaults to None.
        params (dict, optional): Additional parameters to include in the request. Defaults to None.
    Returns:
        dict: The response dictionary containing the health status of RHACS.
    Logs:
        Debug logs indicating the start and completion of the health check request.
    """
    
    
    logger.debug(f"get_rhacs_health -start: url:{url}")
    rhacs_health_url_path=f"{url}/v1/ping"
    response_dict = await request_processing(client,rhacs_health_url_path,insecure,headers,params)
    logger.debug(f"get_rhacs_health - complete")
    return response_dict