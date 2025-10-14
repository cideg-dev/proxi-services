import 'package:frontend/services/system_service.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:geolocator/geolocator.dart'; // New import
import 'login_screen.dart';
import 'artisan_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArtisanService _artisanService = ArtisanService();
  final TokenManager _tokenManager = TokenManager();
  final SystemService _systemService = SystemService(); // Service for system checks
  static const String _currentVersion = "1.0.0"; // Current app version

  late Future<List<dynamic>> _professionalsFuture;
  String? _userRole;
  Set<int> _favoriteProfessionalIds = {};
  String _sortOption = 'default'; // New state variable for sort option
  Position? _userLocation; // New state variable for user's location

  @override
  void initState() {
    super.initState();
    _professionalsFuture = _artisanService.getArtisans(); // Initial load of all professionals
    _loadUserData();
    _loadFavorites(); // Initial load of favorites
    _determinePosition(); // Get user's location
    _checkForUpdates(); // Check for app updates
    ChatService().onNotification((message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nouveau message de ${message['senderName']}: ${message['message']}')),
      );
    });
  }

  void _checkForUpdates() async {
    // Wait a bit to not be too intrusive at startup
    await Future.delayed(const Duration(seconds: 3));

    final latestVersion = await _systemService.getLatestVersion();
    if (latestVersion != null && latestVersion.compareTo(_currentVersion) > 0) {
      if (mounted) { // Check if the widget is still in the tree
        _showUpdateDialog(latestVersion);
      }
    }
  }

  void _showUpdateDialog(String newVersion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Mise à jour disponible"),
          content: Text("Une nouvelle version ($newVersion) de Proxi-Services est disponible. Veuillez mettre à jour l'application pour continuer à profiter des dernières fonctionnalités."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadUserData() async {
    final role = await _tokenManager.getRole();
    setState(() {
      _userRole = role;
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      print('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        print('Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print('Location permissions are permanently denied, we cannot request permissions.');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _userLocation = await Geolocator.getCurrentPosition();
    print('User location: ${_userLocation?.latitude}, ${_userLocation?.longitude}');
  }

  void _loadFavorites() async {
    try {
      List<dynamic> favorites;
      if (_sortOption == 'distance' && _userLocation != null) {
        favorites = await _artisanService.getFavoriteArtisans(
          sortBy: 'distance',
          latitude: _userLocation!.latitude,
          longitude: _userLocation!.longitude,
        );
      } else {
        favorites = await _artisanService.getFavoriteArtisans();
      }

      setState(() {
        _favoriteProfessionalIds = favorites.map<int>((fav) => fav['id'] as int).toSet();
        // If sorting by distance, we also need to update the _professionalsFuture
        // to reflect the sorted order. This is a bit tricky as _professionalsFuture
        // is for all professionals, not just favorites.
        // For now, we'll just update the favoriteProfessionalIds.
        // A better approach would be to have a separate Future for favorite professionals.
      });
    } catch (e) {
      print('Error loading favorites: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  void _toggleFavorite(int professionalId) async {
    try {
      if (_favoriteProfessionalIds.contains(professionalId)) {
        await _artisanService.removeFavorite(professionalId);
        setState(() {
          _favoriteProfessionalIds.remove(professionalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré des favoris.'), backgroundColor: Colors.red),
        );
      } else {
        await _artisanService.addFavorite(professionalId);
        setState(() {
          _favoriteProfessionalIds.add(professionalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté aux favoris !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onSortOptionChanged(String? newOption) {
    if (newOption == null || newOption == _sortOption) return;
    setState(() {
      _sortOption = newOption;
    });
    if (newOption == 'distance') {
      _determinePosition().then((_) {
        _loadFavorites(); // Reload favorites with distance sorting
      });
    } else {
      _loadFavorites(); // Reload favorites with default sorting
    }
  }

  void _logout() {
    TokenManager().clearToken();
    ChatService().disconnect();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professionnels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
            onPressed: () {
              // TODO: Naviguer vers l'écran de chat/messages
              print('Aller vers l\'écran de chat');
            },
          ),
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Panel Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.work_history_outlined),
            tooltip: 'Mes Demandes',
            onPressed: () {
              if (_userRole == 'client') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientDemandsScreen()),
                );
              } else if (_userRole == 'artisan' || _userRole == 'commercant') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ArtisanDemandsScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mon Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // Sort option dropdown
          DropdownButton<String>(
            value: _sortOption,
            icon: const Icon(Icons.sort, color: Colors.white),
            underline: const SizedBox(),
            onChanged: _onSortOptionChanged,
            items: const [
              DropdownMenuItem(
                value: 'default',
                child: Text('Par défaut', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'distance',
                child: Text('Par distance', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Dèconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _professionalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erreur de chargement des professionnels:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun professionnel trouvé.'));
          }

          final professionals = snapshot.data!;

          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              final bool isArtisan = professional['role'] == 'artisan';
              final bool isFavorited = _favoriteProfessionalIds.contains(professional['id']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(isArtisan ? Icons.construction : Icons.store),
                  ),
                  title: Text(professional['name'] ?? 'Nom non disponible'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(professional['specialty'] ?? 'Information non disponible'),
                      if (_sortOption == 'distance' && professional['distance'] != null)
                        Text('${professional['distance'].toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.red : null,
                    ),
                    onPressed: () => _toggleFavorite(professional['id']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtisanDetailScreen(artisanId: professional['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
