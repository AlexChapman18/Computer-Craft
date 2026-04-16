from dirhash import dirhash # type: ignore
import shutil

class CacheManager():
    def __init__(self, cache_dir, content_dir, clean, dry_run=False):
        self.cache_dir = cache_dir
        self.dist_dir = content_dir
        self.dry_run = dry_run
        self.create_cache_dir(clean)

    # Create a directory to store current cache
    def create_cache_dir(self, clean):
        if clean:
            print(f'Cache Manager: Cleaning cache directory: \"{self.cache_dir}\"')
            shutil.rmtree(self.cache_dir, ignore_errors=True) # Dont fail if cache doesnt exist yet
        self.cache_dir.mkdir(exist_ok=True, parents=True)

    def calc_cache_path(self, cache_name):
        return self.cache_dir / cache_name

    def get_hash_cache(self, cache_name):
        return self.calc_cache_path(cache_name).read_text()

    def set_hash_cache(self, cache_name, hash):
        if not self.dry_run:
            self.calc_cache_path(cache_name).write_text(hash)
        print(f'Cache Manager: Cache updated: {cache_name}')

    def calc_dir_hash(self, cache_name):
        dist_path = self.dist_dir / cache_name
        return dirhash(dist_path, "sha256")
    
    def does_cache_exist(self, cache_name):
        return self.calc_cache_path(cache_name).is_file()

    def update_hash_cache(self, cache_name):
        hash = self.calc_dir_hash(cache_name)
        self.set_hash_cache(cache_name, hash)

    def is_cache_valid(self, cache_name):
        if not self.does_cache_exist(cache_name):
            return True
        has_cache_updated = self.calc_dir_hash(cache_name) != self.get_hash_cache(cache_name)
        return has_cache_updated
