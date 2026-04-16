import json
from pathlib import Path
from Exceptions.UserError import UserError

DEPLOYMENTS_DIR = Path("deployments/")
DEPLOYMENT_EXTENSION = ".json"

def load_deployment(deployment_basename):
    filename = deployment_basename + DEPLOYMENT_EXTENSION
    deployment_path = DEPLOYMENTS_DIR / filename
    deployment_exists = bool(deployment_path.is_file())

    if not deployment_exists:
        available_deployments = [p.stem for p in DEPLOYMENTS_DIR.iterdir() if p.is_file()]
        raise UserError(f'Deployment does not exist: \'{deployment_path}\'.\n'
                        f'Choose from: [{", ".join(available_deployments)}]')
    
    data = json.load(open(deployment_path, encoding="utf-8"))
    return __deployment_from_json(data)


def __deployment_from_json(data):
    computers = []
    for computer in data:
        computers.append(Computer(computer["name"], computer["computer_id"]))
    return computers


class Computer:
    def __init__(self, name, id):
        self.name = name
        self.id = id
