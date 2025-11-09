class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  int _apiCallCount = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};

  // Méthodes pour la gestion du cache
  void setCache(String key, dynamic value, {Duration expiry = const Duration(hours: 1)}) {
    _cache[key] = value;
    _cacheExpiry[key] = DateTime.now().add(expiry);
    _cacheHitCount++;
  }

  dynamic getCache(String key) {
    if (_cache.containsKey(key)) {
      final expiry = _cacheExpiry[key];
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        return _cache[key];
      } else {
        // Nettoyer le cache expiré
        _cache.remove(key);
        _cacheExpiry.remove(key);
        _cacheMissCount++;
        return null;
      }
    } else {
      _cacheMissCount++;
      return null;
    }
  }

  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheExpiry.remove(key);
    } else {
      _cache.clear();
      _cacheExpiry.clear();
    }
  }

  // Méthodes pour le suivi des performances
  void incrementApiCallCount() {
    _apiCallCount++;
  }

  int getApiCallCount() => _apiCallCount;

  Map<String, dynamic> getPerformanceStats() {
    return {
      'apiCallCount': _apiCallCount,
      'cacheHitCount': _cacheHitCount,
      'cacheMissCount': _cacheMissCount,
      'cacheHitRate': _apiCallCount > 0 ? (_cacheHitCount / (_cacheHitCount + _cacheMissCount)) * 100 : 0,
      'totalCachedItems': _cache.length,
    };
  }

  // Méthodes pour l'optimisation
  bool shouldRefreshData(String key, Duration refreshInterval) {
    final expiry = _cacheExpiry[key];
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(refreshInterval));
  }

  // Méthode pour le préchargement des données
  Future<void> preloadData(List<String> keys, Future<dynamic> Function(String key) loader) async {
    for (final key in keys) {
      try {
        final data = await loader(key);
        setCache(key, data);
      } catch (e) {
        print('Erreur lors du préchargement des données pour $key: $e');
      }
    }
  }
}