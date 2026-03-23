#!/usr/bin/env python
import re
import os
import sys
import json
import argparse
from ftplib import FTP
from pathlib import Path
from dotenv import load_dotenv

# Constants:
HOSTS_DIR = Path("hosts/")
DEPLOYMENTS_DIR = Path("deployments/")
DIST_DIR = Path("dist/")
FTP_TIMEOUT = 30 # 30 Seconds


class FTPClient:
    def __init__(self, host, username, password, passive=True):
        self.host = host
        self.username = username
        self.password = password
        self.passive = passive
        self.ftp = None

    def connect(self):
        print(f"Connecting to: {self.host}")
        self.ftp = FTP(self.host)
        self.ftp.login(self.username, self.password)
        self.ftp.set_pasv(self.passive)
        print(f"Connected!")
        return self

    def close(self):
        if self.ftp:
            self.ftp.quit()
            self.ftp = None

    def is_path_folder(self, test_path):
        current_path = self.ftp.pwd()

        is_folder = True
        try:
            self.ftp.cwd(test_path)
        except Exception:
            is_folder = False
        
        self.ftp.cwd(current_path)
        return is_folder
    
    def delete_folder_contents(self, path):
        self.ftp.cwd(path) 
        
        # Delete all files in folder
        names = [n for n in self.ftp.nlst() if n not in (".", "..")] 
        
        # Iterate through each item in folder
        for name in names: 
            remote_path = f"{path}/{name.split('/')[-1]}"

            # Recurse to delete all items
            if (self.is_path_folder(remote_path)):
                self.delete_folder_contents(remote_path)
                self.ftp.rmd(remote_path)
            else:
                self.ftp.delete(remote_path)

        self.ftp.cwd("..") 

    def make_path(self, path):
        self.ftp.cwd("/")
        # Build directory from ground up /, /path, /path/a, /path/a/b
        current_path = ""
        for part in path.strip("/").split("/"):
            current_path = f"{current_path}/{part}"

            # If folder does not already exist, create it
            if not self.is_path_folder(current_path):
                self.ftp.mkd(current_path)

    def store_binary(self, path, contents):
        self.ftp.storbinary(f"STOR {path}", contents)


def load_host_environment(host):
    env_file = f".env.{host}"
    load_dotenv(HOSTS_DIR / env_file)
    

def load_deployment(deployment):
    filename = deployment + ".json"
    return json.load(open(DEPLOYMENTS_DIR / filename, encoding="utf-8"))


def deploy_computers(ftp_client: FTPClient, deployment):
    print(f"Deploying computers...")
    for computer in deployment:
        print(f"Deploying {computer["computer_id"]}: {computer["name"]}")
        local_computer_path = DIST_DIR / computer["name"]
        computer_id = computer["computer_id"]

        remote_cc_root = os.getenv("FTP_REMOTE_CC_ROOT")   
        remote_computer_path = f"{remote_cc_root}/{computer_id}"

        # Delete remote computer
        ftp_client.delete_folder_contents(remote_computer_path)

        for current_local_path in local_computer_path.rglob("*"):

            # Calculate respective remote path
            current_remote_path = f"{remote_computer_path}/{current_local_path.relative_to(local_computer_path).as_posix()}"

            # If folder, mnake folder
            # Folders always come before their respective files
            if not current_local_path.is_file():
                ftp_client.make_path(current_remote_path)
                continue
            
            # Copy file to remote
            with open(current_local_path, "rb") as file_contents:
                ftp_client.store_binary(current_remote_path, file_contents)
    print(f"All computers deployed!")
    

def load_config(path):
    config_file = Path(path)
    if not config_file.is_file():
        raise FileNotFoundError(f"Config file {path} not found")
    
    with open(config_file) as f:
        data = json.load(f)

    if "host" not in data or "deployment" not in data:
        raise ValueError(f"Config file {path} must contain 'host' and 'deployment'")
    
    return data["host"], data["deployment"]

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host', type=str)
    parser.add_argument('-D', '--deployment', type=str)
    parser.add_argument("-C", "--config_file", type=str)
    args = parser.parse_args()

    # Display arguments to user
    if (args.config_file):
        print(f"Using config file: {args.config_file}")
        host, deployment = load_config(args.config_file)
    else:
        print("Using arguments -H and -D")
        host = args.host
        deployment = args.deployment
    print(f"Host: {host}")
    print(f"Deployment: {deployment}")

    # Load Host arguments into environment variables
    load_host_environment(host)
    deployment = load_deployment(deployment)

    ftp_client = FTPClient(os.getenv("FTP_HOST"), os.getenv("FTP_USER"), os.getenv("FTP_PASSWORD")).connect()

    deploy_computers(ftp_client, deployment)

if __name__ == "__main__":
    main()