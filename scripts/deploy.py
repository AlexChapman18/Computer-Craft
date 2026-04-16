#!/usr/bin/env python
from abc import ABC, abstractmethod
import json
import argparse
from pathlib import Path

from Exceptions.UserError import UserError
from deployer.CacheManager import CacheManager
from deployer.Host import Host, load_host
from deployer.FileClients.Base import BaseFileClient
from deployer.FileClients.Dummy import DummyFileClient
from deployer.FileClients.FTP import FTPFileClient
from deployer.Deployment import load_deployment
from deployer.Profile import load_profile

# Constants
DIST_DIR = Path("dist/")
CACHE_ROOT = Path(".cache/")

# Compare current build hash to last deployed hash
def get_updated_computers(cache_manager: CacheManager, deployment):
    computers_to_deploy = []
    print("\nChecking cached deployments...")
    for computer in deployment:
        cache_name = computer.name

        if not cache_manager.is_cache_valid(cache_name):
            print(f'Skipping (up-to-date) {computer.id}: {cache_name}')
            continue

        print(f'Added {computer.id}: {cache_name}')
        computers_to_deploy.append(computer)
    print("Cache check complete!")
    return computers_to_deploy

# ---------- DEPLOYMENT ----------

# Use FTP connection to deploy
def deploy_computers(file_client: BaseFileClient, cache_manager: CacheManager, computers_to_deploy, host_values: Host, dist_dir, cache_dir):
    print("\nDeploying computers...")
    for computer in computers_to_deploy:
        computer_name = computer.name
        local_computer_path = dist_dir / computer_name
        computer_id = computer.id

        print(f'Deploying {computer.id}: {computer_name}')

        remote_computer_path = f'{host_values.remote_cc_root}/{computer_id}'

        # Delete remote computer
        file_client.delete_path(remote_computer_path)

        for current_local_path in local_computer_path.rglob("*"):

            # Calculate respective remote path
            current_remote_path = f'{remote_computer_path}/{current_local_path.relative_to(local_computer_path).as_posix()}'

            # If folder, mnake folder
            # Folders always come before their respective files
            if not current_local_path.is_file():
                file_client.create_path(current_remote_path)
                continue
            
            # Copy file to remote
            with open(current_local_path, "rb") as file_contents:
                file_client.transfer_file(current_remote_path, file_contents)
        
        cache_manager.update_hash_cache(computer_name)
    print(f'All computers deployed!')
    

# ---------- VERIFY ARGS ----------

# Verify main args
def validate_args(args, parser):
    has_profile = bool(args.profile_file)
    has_host_and_deployment = bool(args.host_file) and bool(args.deployment_file)

    if (not (has_profile or has_host_and_deployment)):
        parser.error(f'No profile-file OR host/deployment specified')


# ---------- MAIN ----------

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host_file', type=str)
    parser.add_argument('-D', '--deployment_file', type=str)
    parser.add_argument("-P", "--profile-file", type=str)
    parser.add_argument("-C", "--clean", action="store_true")
    parser.add_argument("-DR", "--dry_run", action="store_true")
    args = parser.parse_args()
    validate_args(args, parser)

    # Display arguments to user
    if (args.profile_file):
        print(f'Using Profile: {args.profile_file}')
        host_basename, deployment_basename = load_profile(args.profile_file)
    else:
        print("Using arguments -H and -D")
        host_basename = args.host_file
        deployment_basename = args.deployment_file
    print(f'Host: {host_basename} / Deployment: {deployment_basename}')

    # Load Host and Deployment contents
    host = load_host(host_basename)
    deployment = load_deployment(deployment_basename)
    cache_dir = CACHE_ROOT / Path(host_basename) / Path(deployment_basename)
    cache_manager = CacheManager(cache_dir, DIST_DIR, args.clean, args.dry_run)

    # Get computers to deploy based on cache
    computers_to_deploy = get_updated_computers(cache_manager, deployment)
    if not computers_to_deploy:
        print("\nNothing to deploy!")
        return
    
    file_client = DummyFileClient if args.dry_run else FTPFileClient

    # Connect and deploy computers
    with file_client(host.hostname, host.username, host.password) as connection:
        deploy_computers(connection, cache_manager, computers_to_deploy, host, DIST_DIR, cache_dir)

if __name__ == "__main__":
    try:
        main()
    except UserError as e:
        print(f'\033[31m{e}\033[0m') # Print in RED
