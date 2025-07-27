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

// Extension to capitalize the first letter of a string
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _WeatherPageState extends State<WeatherPage> {
  final String apiKey = '62ac58651a0ac978b2e76ed5e3f81921';
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

      setState(() {});

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red[700], fontSize: 16),
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
                    // Header with location and refresh button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weather Forecast',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue[800],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.lightBlue[700],
                            ),
                            onPressed: () => _getCurrentLocation(),
                          ),
                        ],
                      ),
                    ),

                    // Current Weather Card
                    if (_currentWeather != null)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.lightBlue, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.lightBlue,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _currentWeather!['name'] ??
                                        'Current Location',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _weatherIcon(
                                    _currentWeather!['weather'][0]['icon'],
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    '${_currentWeather!['main']['temp']?.round()}°C',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightBlue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentWeather!['weather'][0]['description']
                                    .toString()
                                    .capitalize(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Divider(
                                height: 22,
                                color: Colors.lightBlue,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _weatherDetail(
                                          Icons.water_drop,
                                          '${_currentWeather!['main']['humidity']}%',
                                          'Humidity',
                                          Colors.lightBlue,
                                        ),
                                        _weatherDetail(
                                          Icons.air,
                                          '${_currentWeather!['wind']['speed']?.round()} km/h',
                                          'Wind',
                                          Colors.lightBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.grey[300],
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _weatherDetail(
                                          Icons.compress,
                                          '${_currentWeather!['main']['pressure']} hPa',
                                          'Pressure',
                                          Colors.lightBlue,
                                        ),
                                        _weatherDetail(
                                          Icons.visibility,
                                          '${_currentWeather!['visibility'] / 1000} km',
                                          'Visibility',
                                          Colors.lightBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Hourly Forecast
                    Text(
                      'Hourly Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue[800],
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
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.lightBlue,
                                    width: 1,
                                  ),
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
                                          color: Colors.lightBlue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _weatherIcon(
                                        forecast['weather'][0]['icon'],
                                      ),
                                      const SizedBox(height: 4),
                                      const Divider(
                                        height: 10,
                                        color: Colors.lightBlue,
                                      ),
                                      Text(
                                        '${forecast['main']['temp']?.round()}°C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlue[800],
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_forecast != null)
                      Column(
                        children: _getDailyForecast().map((daily) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.lightBlue,
                                  width: 1,
                                ),
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.lightBlue[800],
                                        ),
                                      ),
                                    ),
                                    _weatherIcon(daily['weather'][0]['icon']),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${daily['temp']['max']?.round()}° / ${daily['temp']['min']?.round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightBlue[800],
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

    var dailyList = dailyForecasts.values.toList();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
