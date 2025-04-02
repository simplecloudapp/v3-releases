import yaml
import requests
import os
import zipfile
import shutil
from typing import Dict, List

def download_file(url, output_path, headers):
    """Downloads a file from a URL to a specified path."""
    response = requests.get(url, headers=headers, stream=True)
    response.raise_for_status()
    with open(output_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

def get_component_by_name(components: List[Dict], name: str) -> Dict:
    """Finds and returns a component by its name."""
    for component in components:
        if component['name'] == name:
            return component
    raise Exception(f"Component {name} not found")

def process_component(component: Dict, headers: Dict, base_dir: str = 'bundle'):
    """Processes a single component, downloading its files."""
    repo_url = component['githubRepo']
    version = component['version']
    files = component['files']

    api_url = f"{repo_url.replace('github.com', 'api.github.com/repos')}/releases/tags/{version}"
    response = requests.get(api_url, headers=headers)
    response.raise_for_status()
    release_data = response.json()

    downloaded_files = []
    for file_info in files:
        release_file = file_info['releaseFile']
        output = file_info['output']
        destination = file_info['destination']

        # Find the correct asset in the release
        for asset in release_data['assets']:
            if asset['name'] == release_file:
                download_url = asset['url']
                break
        else:
            raise Exception(f"Release file {release_file} not found in release {version} of {repo_url}")

        # Download to bundle directory
        output_path = os.path.join(base_dir, destination, output)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Download the file
        download_headers = headers.copy()
        download_headers['Accept'] = 'application/octet-stream'
        download_file(download_url, output_path, download_headers)
        downloaded_files.append(output_path)

        # Also copy to release_files
        release_files_dir = 'release_files'
        os.makedirs(release_files_dir, exist_ok=True)
        release_file_path = os.path.join(release_files_dir, output)
        shutil.copy2(output_path, release_file_path)
        print(f"Copied {output} to release_files directory")

    return downloaded_files

def copy_contents_for_bundle(bundle: Dict, bundle_dir: str):
    """Copies specified content folders for a bundle."""
    if 'contents' in bundle:
        print(f"Copying contents for bundle: {bundle['name']}")
        for content in bundle['contents']:
            source = content['source']
            destination = content['destination']

            # Handle root destination
            if destination == '/' or destination == '.':
                final_destination = bundle_dir
            else:
                final_destination = os.path.join(bundle_dir, destination.lstrip('/'))

            print(f"Copying {source} to {final_destination}")

            try:
                # Create destination directory if it doesn't exist
                os.makedirs(os.path.dirname(final_destination), exist_ok=True)

                if os.path.isdir(source):
                    # Directory handling
                    if destination == '/' or destination == '.':
                        # Copy directory contents to root
                        for item in os.listdir(source):
                            s = os.path.join(source, item)
                            d = os.path.join(final_destination, item)
                            if os.path.isdir(s):
                                shutil.copytree(s, d, dirs_exist_ok=True)
                            else:
                                shutil.copy2(s, d)
                    else:
                        # Copy directory itself
                        shutil.copytree(source, final_destination, dirs_exist_ok=True)
                else:
                    # File handling
                    shutil.copy2(source, final_destination)
                print(f"Successfully copied {source} to {final_destination}")
            except FileNotFoundError:
                print(f"Warning: Source '{source}' not found, skipping...")
            except Exception as e:
                print(f"Error copying {source}: {str(e)}")

def create_bundle(bundle: Dict, files: List[str]):
    """Creates a bundle zip file with the specified files."""
    name = bundle['name']
    bundle_dir = f'bundles/{name}'
    
    # Clear the bundle directory if it exists
    if os.path.exists(bundle_dir):
        shutil.rmtree(bundle_dir)
    os.makedirs(bundle_dir)
    
    # Copy all component files to bundle directory maintaining structure
    for file_path in files:
        relative_path = os.path.relpath(file_path, 'bundle')
        dest_path = os.path.join(bundle_dir, relative_path)
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        shutil.copy2(file_path, dest_path)
    
    # Copy contents specified for this bundle
    copy_contents_for_bundle(bundle, bundle_dir)
    
    # Create zip file with the bundle name
    if os.path.exists(f"{name}.zip"):
        os.remove(f"{name}.zip")
    shutil.make_archive(name, 'zip', bundle_dir)
    print(f"Created bundle zip: {name}.zip")

def copy_additional_release_files(data: Dict):
    """Copies additional specified files to the release_files directory."""
    if 'releaseFiles' in data:
        release_files_dir = 'release_files'
        os.makedirs(release_files_dir, exist_ok=True)
        
        for file_info in data['releaseFiles']:
            source_path = file_info['source']
            output_path = os.path.join(release_files_dir, file_info['output'])
            
            if os.path.exists(source_path):
                shutil.copy2(source_path, output_path)
                print(f"Copied additional release file {source_path} to release_files as {file_info['output']}")
            else:
                print(f"Warning: Source file {source_path} not found, skipping...")

def process_components():
    """Main function to process components and create bundles."""
    try:
        # Read the configuration file
        with open('components.yml', 'r') as f:
            data = yaml.safe_load(f)

        components = data['components']
        bundles = data['bundles']

        # Create necessary directories
        os.makedirs('bundle', exist_ok=True)
        os.makedirs('bundles', exist_ok=True)
        os.makedirs('release_files', exist_ok=True)

        # Setup GitHub API headers
        headers = {
            # 'Authorization': f"token {os.environ['GITHUB_TOKEN']}",
            'Accept': 'application/vnd.github.v3+json'
        }

        # Process all components first
        print("Starting component processing...")
        all_downloaded_files = {}
        for component in components:
            print(f"Processing component: {component['name']}")
            try:
                files = process_component(component, headers)
                all_downloaded_files[component['name']] = files
                print(f"Successfully processed component: {component['name']}")
            except Exception as e:
                print(f"Error processing component {component['name']}: {str(e)}")
                raise

        # Process bundles
        print("\nStarting bundle creation...")
        for bundle in bundles:
            print(f"Creating bundle: {bundle['name']}")
            try:
                bundle_files = []
                for component_name in bundle['components']:
                    if component_name not in all_downloaded_files:
                        raise Exception(f"Bundle {bundle['name']} references unknown component: {component_name}")
                    bundle_files.extend(all_downloaded_files[component_name])
                create_bundle(bundle, bundle_files)
                print(f"Successfully created bundle: {bundle['name']}")
            except Exception as e:
                print(f"Error creating bundle {bundle['name']}: {str(e)}")
                raise

        # Copy any additional specified files to release_files
        print("\nProcessing additional release files...")
        copy_additional_release_files(data)

        # Verify release_files directory is not empty
        if not os.listdir('release_files'):
            print("Warning: No files found in release_files directory")
            # Create a dummy file to prevent GitHub Action from failing
            with open('release_files/README.txt', 'w') as f:
                f.write('Release files will be added in future releases.')

        print("\nComponent processing completed successfully.")

    except Exception as e:
        print(f"\nError during processing: {str(e)}")
        raise

if __name__ == '__main__':
    try:
        process_components()
    except Exception as e:
        print(f"Fatal error: {str(e)}")
        exit(1)
