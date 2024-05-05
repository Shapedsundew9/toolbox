"""
This module contains functions to clone all public repositories of a GitHub user.
"""

import os
import subprocess
import requests

def get_repos(username):
    """
    Fetches a list of all public repositories for the given GitHub username.
    """
    repos = []
    page = 1
    while True:
        url = f"https://api.github.com/users/{username}/repos?page={page}&per_page=100"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        current_page_repos = response.json()
        if not current_page_repos:
            break
        repos.extend(current_page_repos)
        page += 1
    return repos

def clone_repo(repo_url, repo_name, destination_folder="."):
    """
    Clones the given repository URL into the specified destination folder if it does not already exist.
    """
    repo_path = os.path.join(destination_folder, repo_name)
    if os.path.exists(repo_path):
        print(f"Repository already exists: {repo_name}, skipping...")
    else:
        try:
            with subprocess.Popen(["git", "clone", repo_url, repo_name], cwd=destination_folder) as proc:
                proc.wait()
            print(f"Successfully cloned {repo_name}")
        except subprocess.CalledProcessError:
            print(f"Failed to clone {repo_name}")

def main():
    """
    Main function to clone all public repositories of a GitHub user.
    """
    username = "shapedsundew9"
    destination_folder = os.path.expanduser("~/Projects")  # Expand to the user's home directory
    os.makedirs(destination_folder, exist_ok=True)

    repos = get_repos(username)
    for repo in repos:
        clone_repo(repo['clone_url'], repo['name'], destination_folder)

if __name__ == "__main__":
    main()
