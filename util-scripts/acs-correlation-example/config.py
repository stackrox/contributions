from pydantic_settings import BaseSettings
import os
from dotenv import load_dotenv  # pylint: disable=import-error

basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, '.env'))

class Settings(BaseSettings):
    """Application Settings """
    
    #If multiple versions of this Applications Hostname are running, this will help identify them
    instance_hostname:str = os.environ.get('HOSTNAME') or 'demo_app'
    
    #File Path where we can look for the list of ACS API Endpoints to work with
    endpoint_list_json_path:str = os.environ.get('ENDPOINT_LIST_JSON_PATH') or 'endpoint_list.json'
    
    #Health Check Retry Count
    health_check_retry_count:int = os.environ.get('HEALTH_CHECK_RETRY_COUNT') or 3
    
    #Health Check Retry Delay in Seconds
    health_check_retry_delay:int = os.environ.get('HEALTH_CHECK_RETRY_DELAY') or 10
    
    #Poll Disabled Policy Information
    poll_disabled_policy_info:bool = os.environ.get('POLL_DISABLED_POLICY_INFO') or False
    
    #Output folder for the Policy output
    output_folder:str = os.environ.get('OUTPUT_FOLDER') or 'output'

settings = Settings()


