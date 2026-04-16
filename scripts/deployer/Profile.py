# Load the Profile file and verify contents
import json
from pathlib import Path
from Exceptions.UserError import UserError

PROFILES_DIR = Path("profiles/")
PROFILE_EXTENSION = ".json"

def load_profile(profile_basename):
    filename = profile_basename + PROFILE_EXTENSION
    profile_path = PROFILES_DIR / filename
    profile_exists = bool(profile_path.is_file())

    if not profile_exists:
        available_profiles = [p.stem for p in PROFILES_DIR.iterdir() if p.is_file()]
        raise UserError(f'Profile does not exist: \'{profile_path}\'.\n'
                        f'Choose from: [{", ".join(available_profiles)}]')
    
    with open(profile_path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            raise UserError(f'Profile is not a valid JSON: \'{profile_path}\'')
            
    if not isinstance(data, dict):
        raise UserError("Profile JSON must contain a dict")
    
    missing_fields = [field for field in ["host", "deployment"] if not data.get(field, "")]
    if missing_fields:
        raise UserError(f'Profile fields are missing or empty:\n'
                        f'[{", ".join(missing_fields)}]')

    return data["host"], data["deployment"]