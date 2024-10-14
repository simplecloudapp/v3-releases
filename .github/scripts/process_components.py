import yaml
import requests
import os
import zipfile
import shutil

def download_file(url, output_path):
    response = requests.get(url)
    response.raise_for_status()
    with open(output_path, 'wb') as f:
        f.write(response.content)

def process_components():
    with open('components.yml', 'r') as f:
        components = yaml.safe_load(f)

    os.makedirs('bundle', exist_ok=True)
    os.makedirs('release_files', exist_ok=True)

    for component in components:
        repo_url = component['githubRepo']
        version = component['version']
        release_file = component['releaseFile']
        output = component['output']
        destination = component['destination']

        api_url = f"{repo_url.replace('github.com', 'api.github.com/repos')}/releases/tags/v{version}"
        response = requests.get(api_url, headers={'Authorization': f"token {os.environ['GITHUB_TOKEN']}"})
        response.raise_for_status()
        release_data = response.json()

        for asset in release_data['assets']:
            if asset['name'] == release_file:
                download_url = asset['browser_download_url']
                break
        else:
            raise Exception(f"Release file {release_file} not found in release v{version} of {repo_url}")

        output_path = os.path.join('bundle', destination, output)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        download_file(download_url, output_path)

        # Copy the file to release_files directory
        shutil.copy(output_path, os.path.join('release_files', output))

    # Create a zip file of the bundle
    shutil.make_archive('bundle', 'zip', 'bundle')

if __name__ == '__main__':
    process_components()
