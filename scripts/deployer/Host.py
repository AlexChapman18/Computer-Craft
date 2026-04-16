from pathlib import Path
from dotenv import dotenv_values
from Exceptions.UserError import UserError

HOSTS_DIR = Path("hosts/")
HOST_EXTENSION = ".env"

# Load the host file and verify contents
def load_host(filename):
    filename = filename + HOST_EXTENSION
    host_path = HOSTS_DIR / filename
    host_exists = bool(host_path.is_file())

    if not host_exists:
        available_hosts = [p.stem for p in HOSTS_DIR.iterdir() if p.is_file()]
        raise UserError(f'Host does not exist: \'{host_path}\'.\n'
                        f'Choose from: [{", ".join(available_hosts)}]')

    values = dotenv_values(host_path)

    FIELDS = ["FTP_HOST", "FTP_USER", "FTP_PASSWORD", "FTP_REMOTE_CC_ROOT"]
    missing_fields = [field for field in FIELDS if not values.get(field)]
    if missing_fields:
        raise UserError(f'Host fields are missing or empty:\n'
                        f'[{", ".join(missing_fields)}]')
    
    # Return new host
    return Host(values["FTP_HOST"], values["FTP_USER"], values["FTP_PASSWORD"], values["FTP_REMOTE_CC_ROOT"])


class Host:
    def __init__(self, hostname, username, password, remote_cc_root):
        self.hostname = hostname
        self.username = username
        self.password = password
        self.remote_cc_root = remote_cc_root