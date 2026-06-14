part of 'index.dart';

final class StorageService {
  final GetStorage _storage = GetStorage();

  Future<StorageService> init() async {
    await GetStorage.init();
    await Hive.initFlutter();
    return this;
  }

  T? read<T>(String key) => _storage.read<T>(key);

  Future<void> write(String key, Object? value) => _storage.write(key, value);

  Future<void> remove(String key) => _storage.remove(key);

  Future<void> clear() => _storage.erase();
}
