"""Upload photos to Google Photos in batches using the Google Photos Library API.

Go to https://console.cloud.google.com/welcome/ and create a project if you don't have one.
Enable the Google Photos Library API for the project.
Navigation Menu (Hamburger Icon) -> APIs & Services -> Library ->
Google Photos Library API -> Enable

Create OAuth 2.0 credentials for the project.
Navigation Menu (Hamburger Icon) -> APIs & Services -> Credentials -> Create Credentials ->
OAuth client ID
Choose 'Desktop app' as the application type.
Download the client secrets file and save it as 'client_secret.json' in the same directory
as this script and the photos to upload. Run the script to authenticate the user and 
upload photos to Google Photos (will use profile last used in chrome).
"""
import json
import os
import time
import requests

from PIL import Image, UnidentifiedImageError
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from tqdm import tqdm

# Supported image formats
VALID_IMAGE_FORMATS = ['AVIF', 'BMP', 'GIF', 'HEIC', 'ICO', 'JPEG', 'PNG', 'TIFF', 'WEBP']
_VALID_IMAGE_SUFFIXES = ('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.tiff', '.ico', '.avif', '.heic')
VALID_IMAGE_SUFFIXES = tuple(f.upper() for f in _VALID_IMAGE_SUFFIXES) + _VALID_IMAGE_SUFFIXES

# Replace with the path to your client secrets file
CLIENT_SECRETS_FILE = 'client_secret.json'

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/photoslibrary.appendonly']

# Set the batch size
BATCH_SIZE = 10

# File to store the names of uploaded files
UPLOADED_FILES_FILE = 'uploaded_files.txt'

# File to record invalid image files
INVALID_IMAGE_FILES_FILE = 'invalid_image_files.txt'

# Request timeout in seconds. Large files may take longer to upload.
# With a 50Mb/s connection you can (theoretically) upload 200MB in 32 seconds.
# 180s timeout allows a 200MB file to be uploaded at a bandwidth of 1.1Mb/s
# which should be sufficient for most users.
REQUEST_TIMEOUT = 180


def get_access_token():
    """
    Authenticates the user using OAuth 2.0 client secrets and returns an access token.
    """
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    assert creds is not None, "No valid credentials found."
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        flow = InstalledAppFlow.from_client_secrets_file(
            CLIENT_SECRETS_FILE, SCOPES)
        creds = flow.run_local_server(port=0)
        with open('token.json', 'w', encoding='utf-8') as token:
            token.write(creds.to_json())
    return creds.token


def is_valid_image(filename) -> bool:
    """
    Checks if a file is a valid image of one of the specified formats and less than 200MB in size.

    Args:
        filename: The path to the file.

    Returns:
        True if the file is a valid image, False otherwise.
    """
    # Check file size
    file_size = os.path.getsize(filename)
    if file_size > 200 * 1024 * 1024:  # 200MB is max filesize supported by Google Photos
        with open(INVALID_IMAGE_FILES_FILE, 'a', encoding='utf-8') as f:
            f.write(filename + ' is > 200 MB\n')
        return False

    # Check image format using Pillow
    try:
        with Image.open(filename) as img:
            img_format = img.format
            return img_format in VALID_IMAGE_FORMATS
    except UnidentifiedImageError:
        print(f"Unidentified image type: {filename}")
        with open(INVALID_IMAGE_FILES_FILE, 'a', encoding='utf-8') as f:
            f.write(filename + ' is an invalid format\n')
        return False


def upload_photos(access_token, photos):
    """
    Uploads a batch of photos to Google Photos using REST requests.
    """
    try:
        upload_tokens = []
        headers = {'Authorization': f'Bearer {access_token}'}

        for photo in tqdm(photos, desc='Uploading batch'):
            with open(photo, 'rb') as f:
                file_content = f.read()
            # Upload the media file and get the upload token
            response = requests.post(
                'https://photoslibrary.googleapis.com/v1/uploads',
                headers=headers,
                data=file_content,
                timeout=REQUEST_TIMEOUT
            )
            response.raise_for_status()  # Raise an exception for error responses
            upload_token = response.content.decode('utf-8')
            upload_tokens.append(upload_token)

        # Create the media items in Google Photos
        request_body = {
            'newMediaItems': [
                {'simpleMediaItem': {'uploadToken': token}} for token in upload_tokens
            ]
        }
        response = requests.post(
            'https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate',
            headers=headers,
            data=json.dumps(request_body),
            timeout=REQUEST_TIMEOUT
        )
        response.raise_for_status()
        response_json = response.json()

        # Print the URLs of the uploaded photos
        for item in response_json['newMediaItemResults']:
            if 'mediaItem' in item:
                print(f"Photo URL: {item['mediaItem']['productUrl']}")
            else:
                print("An error occurred: mediaItem not found in response.")
                return False
        return True

    except requests.exceptions.RequestException as e:
        if e.response is not None and e.response.status_code == 401:  # Check for Unauthorized error
            print("Access token expired. Refreshing...")
            access_token = get_access_token()  # Get a new access token
            return upload_photos(access_token, photos)  # Retry the upload
        else:
            print(f"An error occurred: {e}")
            print(f"Uploading batch failed for images:\n{'\n'.join(photos)}")
            return False


def main() -> int:
    """
    Main function to upload photos in batches.
    If files were uploaded successfully, their names are stored in a file to avoid re-uploading.
    Any invalid image files are recorded in a separate file.

    Returns
    -------
    True if at least one file was uploaded successfully, False otherwise.
    """
    access_token = get_access_token()
    num_uploaded = 0

    # Get a list of all photos in the current directory
    all_photos = [
        f for f in os.listdir('.')
        if os.path.isfile(f) and f.lower().endswith(VALID_IMAGE_SUFFIXES)
    ]

    # Keep track of uploaded files
    uploaded_files = set()
    if os.path.exists(UPLOADED_FILES_FILE):
        with open(UPLOADED_FILES_FILE, 'r', encoding='utf-8') as f:
            uploaded_files = set(f.read().splitlines())

    # Upload photos in batches
    for i in range(0, len(all_photos), BATCH_SIZE):
        batch = all_photos[i:i + BATCH_SIZE]
        batch = [photo for photo in batch if photo not in uploaded_files and is_valid_image(photo)]
        if not batch:
            continue

        print(
            f"Uploading batch {i // BATCH_SIZE + 1} of {len(all_photos) // BATCH_SIZE + 1}"
        )
        if upload_photos(access_token, batch):
            with open(UPLOADED_FILES_FILE, 'a', encoding='utf-8') as f:
                for photo in batch:
                    f.write(photo + '\n')
                    uploaded_files.add(photo)
            num_uploaded += len(batch)
        else:
            print("Error uploading batch. Retrying in 60 seconds...")
            time.sleep(60)

    return num_uploaded


if __name__ == '__main__':
    while (num := main()) > 0:
        print("{num} files uploaded successfully.\nRescanning for new files.")
    print("No new files found. Done.")
