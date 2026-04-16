from abc import ABC, abstractmethod

class BaseFileClient(ABC):
    def __init__(self, hostname, username, password):
        self.hostname = hostname
        self.username = username
        self.password = password

    @abstractmethod
    def __enter__(self):
        return self.connect()

    @abstractmethod
    def __exit__(self, exc_type, exc_value, traceback):
        return self.disconnect()
    
    @abstractmethod
    def create_path(self, path):
        pass
    
    @abstractmethod
    def delete_path(self, path, relative_whitelist=[]):
        pass

    @abstractmethod
    def transfer_file(self, remote_path, blob):
        pass