from deployer.FileClients.Base import BaseFileClient


class DummyFileClient(BaseFileClient):
    def __init__(self, hostname, username, password):
        super().__init__(hostname, username, password)

    def __enter__(self):
        print(f'File Client: Connected to: {self.hostname}')
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        print(f'File Client: Disconnected from: {self.hostname}')
    
    def create_path(self, path):
        print(f'File Client: Created path: {path}')
    
    def delete_path(self, path, relative_whitelist=[]):
        print(f'File Client: Deleted path: {path}\n'
              f'    Relative Whitelist: [{", ".join(relative_whitelist)}]')

    def transfer_file(self, remote_path, blob):
        print(f'File Client: Transfered file to: {remote_path}')