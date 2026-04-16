from ftplib import FTP, error_perm
from socket import gaierror
from Exceptions.UserError import UserError
from deployer.FileClients.Base import BaseFileClient

class FTPFileClient(BaseFileClient):
    def __init__(self, hostname, username, password):
        super().__init__(hostname, username, password)
        self.ftp = None

    def __enter__(self):
        print(f'\nConnecting to: {self.hostname}')
        try:
            self.ftp = FTP(self.hostname)
            self.ftp.login(self.username, self.password)
        except gaierror as e:
            raise UserError(f'Cannot connect to host: \"{self.hostname}\"')
        except error_perm as e:
            raise UserError(f'Invalid username or password for host: \"{self.hostname}\"')
        self.ftp.set_pasv(True)
        print(f'Connected!')
        return self
    
    def __exit__(self, exc_type, exc_value, traceback):
        if self.ftp:
            self.ftp.quit()
            self.ftp = None
    
    def delete_path(self, path, relative_whitelist = []):
        self.ftp.cwd(path) 
        
        # Delete all files in folder
        items = [n for n in self.ftp.nlst() if n not in (".", "..")] 
        
        # Iterate through each item in folder
        for item in items: 
            remote_path = f'{path}/{item.split('/')[-1]}'

            whitelist_hits = [white_path for white_path in relative_whitelist if (white_path in remote_path)]
            if any(whitelist_hits):
                print(f'Skipping remote path: [{", ".join(whitelist_hits)}] in {remote_path}')
                continue

            # Recurse to delete all items
            if (self.is_path_folder(remote_path)):
                self.delete_path(remote_path)
                self.ftp.rmd(remote_path)
            else:
                self.ftp.delete(remote_path)

        self.ftp.cwd("..") 

    def create_path(self, path):
        self.ftp.cwd("/")
        # Build directory from ground up /, /path, /path/a, /path/a/b
        current_path = ""
        for part in path.strip("/").split("/"):
            current_path = f'{current_path}/{part}'

            # If folder does not already exist, create it
            if not self.is_path_folder(current_path):
                self.ftp.mkd(current_path)

    def transfer_file(self, remote_path, blob):
        self.ftp.storbinary(f'STOR {remote_path}', blob)

    def is_path_folder(self, test_path):
        current_path = self.ftp.pwd()

        is_folder = True
        try:
            self.ftp.cwd(test_path)
        except Exception:
            is_folder = False
        
        self.ftp.cwd(current_path)
        return is_folder
