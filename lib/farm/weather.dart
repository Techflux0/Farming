import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final String apiKey = '62ac58651a0ac978b2e76ed5e3f81921';
  Position? _currentPosition;
  Map<String, dynamic>? _currentWeather;
  List<dynamic>? _forecast;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _currentPosition = position;
      });

      await _fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    try {
      // Fetch current weather
      final currentWeatherResponse = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
        ),
      );

      // Fetch 5-day forecast (3-hour intervals)
      final forecastResponse = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
        ),
      );

      if (currentWeatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          _currentWeather = json.decode(currentWeatherResponse.body);
          _forecast = json.decode(forecastResponse.body)['list'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(int dt) {
    return DateFormat(
      'EEEE, MMM d',
    ).format(DateTime.fromMillisecondsSinceEpoch(dt * 1000));
  }

  String _formatTime(int dt) {
    return DateFormat(
      'h:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(dt * 1000));
  }

  Widget _weatherIcon(String iconCode) {
    return Image.network(
      'https://openweathermap.org/img/wn/$iconCode@2x.png',
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.wb_sunny, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.blue.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _errorMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _getCurrentLocation(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Weather Card
                    if (_currentWeather != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Current Weather',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _weatherIcon(
                                    _currentWeather!['weather'][0]['icon'],
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${_currentWeather!['main']['temp']?.round()}°C',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentWeather!['weather'][0]['description']
                                    .toString()
                                    .toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _weatherDetail(
                                      Icons.water_drop,
                                      '${_currentWeather!['main']['humidity']}%',
                                      'Humidity',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 20),
                                    _weatherDetail(
                                      Icons.air,
                                      '${_currentWeather!['wind']['speed']?.round()} km/h',
                                      'Wind',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 20),
                                    _weatherDetail(
                                      Icons.compress,
                                      '${_currentWeather!['main']['pressure']} hPa',
                                      'Pressure',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 20),
                                    _weatherDetail(
                                      Icons.visibility,
                                      '${_currentWeather!['visibility'] / 1000} km',
                                      'Visibility',
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Hourly Forecast
                    Text(
                      'Hourly Forecast',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_forecast != null)
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _forecast!.length > 8
                              ? 8
                              : _forecast!.length,
                          itemBuilder: (context, index) {
                            final forecast = _forecast![index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _formatTime(forecast['dt']),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _weatherIcon(
                                        forecast['weather'][0]['icon'],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${forecast['main']['temp']?.round()}°C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Daily Forecast
                    Text(
                      'Daily Forecast',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_forecast != null)
                      Column(
                        children: _getDailyForecast().map((daily) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatDate(daily['dt']),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade800,
                                            ),
                                      ),
                                    ),
                                    _weatherIcon(daily['weather'][0]['icon']),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${daily['temp']['max']?.round()}° / ${daily['temp']['min']?.round()}°',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  List<dynamic> _getDailyForecast() {
    if (_forecast == null || _forecast!.isEmpty) return [];

    // Group forecasts by day and get daily min/max temps
    Map<String, dynamic> dailyForecasts = {};

    for (var forecast in _forecast!) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000));

      if (!dailyForecasts.containsKey(date)) {
        dailyForecasts[date] = {
          'dt': forecast['dt'],
          'weather': forecast['weather'],
          'temp': {
            'max': forecast['main']['temp_max'],
            'min': forecast['main']['temp_min'],
          },
        };
      } else {
        if (forecast['main']['temp_max'] >
            dailyForecasts[date]['temp']['max']) {
          dailyForecasts[date]['temp']['max'] = forecast['main']['temp_max'];
        }
        if (forecast['main']['temp_min'] <
            dailyForecasts[date]['temp']['min']) {
          dailyForecasts[date]['temp']['min'] = forecast['main']['temp_min'];
        }
      }
    }

    // Convert to list and skip today (index 0)
    var dailyList = dailyForecasts.values.toList();

    // Return up to 6 days, but don't exceed the available data
    return dailyList.length > 1
        ? dailyList.sublist(1, dailyList.length > 6 ? 7 : dailyList.length)
        : [];
  }

  Widget _weatherDetail(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }
}
