import os
import json
import shutil
from pathlib import Path
from shutil import ignore_patterns


# Paths
PACKAGES_ROOT = Path("packages")
COMPUTERS_PATH = Path("computers")
DISTS_PATH = Path("dist")
MANIFEST_FILENAME = "manifest.json"
PACKAGES_LAYOUT_PATH = PACKAGES_ROOT / "packages.json"


def build_packages(manifest_path, dist):
    # Open packages layout
    with open(PACKAGES_LAYOUT_PATH) as f:
        packages_layout = json.load(f)

    include_packages(packages_layout, manifest_path, dist)


def include_packages(packages_layout, manifest_path, dist):
    # Open manifest
    with open(manifest_path) as f:
        manifest = json.load(f)

    # Include Package dependencies
    for pkg_name in manifest["dependencies"]:

        # Verify package name is valid
        if pkg_name not in packages_layout:
            raise Exception(f"Package not in packages.json: \"{pkg_name}\"") 

        package_relative_path = packages_layout[pkg_name]

        # Verify package contents exist
        local_package_path = PACKAGES_ROOT / package_relative_path
        if not os.path.exists(local_package_path):
            # Cleanup partial build
            shutil.rmtree(dist, ignore_errors=True)
            raise Exception(f"Package does not exist: \"{pkg_name}\"") 

        # Check if package has dependencies
        package_manifest_path = local_package_path / MANIFEST_FILENAME
        if os.path.exists(package_manifest_path):
            include_packages(packages_layout, package_manifest_path, dist)
        
        # Copy package contents
        remote_package_path = dist / pkg_name
        shutil.copytree(local_package_path, remote_package_path, dirs_exist_ok=True, ignore=ignore_patterns(MANIFEST_FILENAME))


def main():
    print("Building computers...")
    # Get the names of all folders the computers directory
    all_computers = [path.name for path in COMPUTERS_PATH.iterdir() if path.is_dir()]

    # Build each computer
    for computer in all_computers:
        print(f"Building: {computer}")

        dist = DISTS_PATH / computer
        computer_folder = COMPUTERS_PATH / computer

        # Remove dist folder if present
        shutil.rmtree(dist, ignore_errors=True)

        # Make dist folder
        dist.mkdir(parents=True, exist_ok=True)

        # Load manifest
        manifest_path = computer_folder / MANIFEST_FILENAME
        build_packages(manifest_path, dist)

        # Copy turtle-specific code
        for src_path in computer_folder.rglob("*"):
            if (src_path.name == MANIFEST_FILENAME):
                continue
            
            # Copy file or create folder in dist
            src_path_relative_to_computer_folder = src_path.relative_to(computer_folder)
            dst_path = dist / src_path_relative_to_computer_folder
            if src_path.is_file():
                shutil.copy(src_path, dst_path)
            else:
                dst_path.mkdir(parents=True, exist_ok=True)

    print("All computers built!")


if __name__ == "__main__":
    main()