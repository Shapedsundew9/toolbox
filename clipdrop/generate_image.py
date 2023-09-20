"""Get an image from text from the clipdrop API."""
from os.path import exists, basename
from json import load
from requests import Response, post
from sys import exit as sys_exit


IMAGE_TEXT: str = """
    Realistic photo of a bare gnarly tree with no leaves growing from a small rocky, mossy, island in the centre of a lake.
    Beyond its branches the milkway is colorful and bright in the clear night sky illuminating the craggy, grassy shoreline.
    The lake is surrounded by mountains and the sky is filled with stars."""
#     The snow lies thick on the ground.
#     A gentle breeze creates ripple patterns on the surface of the lake.
#    The snow lies thick and the lake is frozen.
#    Colorful flowers grow in the grass.


def next_file_name(name: str) -> str:
    """Return the next available file name."""
    if not exists(name):
        return name
    else:
        i: int = 1
        while True:
            new_name: str = f"{name[:-4]}_{i}.png"
            if not exists(new_name):
                return new_name
            i += 1


with open('../../../Documents/clipdrop.json', 'r', encoding="utf-8") as fileptr:
    pinfo: dict[str, str] = load(fileptr)


def generate_image() -> str:
    """Use stable diffusion to generate an image from text"""
    r: Response = post('https://clipdrop-api.co/text-to-image/v1',
        files = {'prompt': (None, IMAGE_TEXT, 'text/plain')},
        headers = { 'x-api-key': pinfo['api_key']},
        timeout = 60
    )
    if r.ok:
        if r.headers['content-type'] == 'image/png':
            filename: str = next_file_name("image.png")
            with open(filename, "wb") as file:
                file.write(r.content)
            print(f"Generated image saved successfully as {filename}")
            return filename
        else:
            print("The response is not of MIME type 'image/png'")
    else:
        r.raise_for_status()
    sys_exit(1)


def upscale_image(filename: str) -> None:
    """Upscale an image to 4096x4096 pixels."""
    with open(filename, 'rb') as image_file_object:
        r: Response = post('https://clipdrop-api.co/image-upscaling/v1/upscale',
            files = {'image_file': (filename, image_file_object, 'image/png'),},
            data = {'target_width': 4096, 'target_height': 4096 },
            headers = {'x-api-key': pinfo['api_key']},
            timeout = 60
        )
    if r.ok:
        if r.headers['content-type'] == 'image/jpeg':
            newname: str = basename(filename).split('.')[0] + 'u.jpeg'
            with open(newname, "wb") as file:
                file.write(r.content)
            print(f"Upscaled image saved successfully as {newname}")
        else:
            print(f"The response is not of MIME type 'image/jpeg': {r.headers['content-type']}")
    else:
        r.raise_for_status()
    sys_exit(1)


if __name__ == '__main__':
    upscale_image(generate_image())
