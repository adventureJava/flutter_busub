import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'DatabaseHelper.dart';
import 'dart:convert'; // JSON 처리를 위한 임포트
import 'package:http/http.dart' as http; // HTTP 요청을 위한 임포트 주안북부역
import 'main_page.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(37.5665, 126.978); // 기본 서울 위치
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _allStations = []; // 모든 스테이션 데이터 저장
  TextEditingController _searchController = TextEditingController(); // 검색 컨트롤러
  List<Map<String, dynamic>> _searchResults = []; // 검색 결과 저장

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final Database db = await DatabaseHelper().database;
    _allStations = await db.query('station');
    _loadVisibleMarkers();
  }

  void _loadVisibleMarkers() {
    mapController.getVisibleRegion().then((bounds) {
      Set<Marker> visibleMarkers = {};
      for (var station in _allStations) {
        double? latitude = double.tryParse(station['latitude'].toString());
        double? longitude = double.tryParse(station['longitude'].toString());

        if (latitude != null && longitude != null) {
          LatLng position = LatLng(latitude, longitude);
          if (bounds.contains(position)) {
            visibleMarkers.add(
              Marker(
                markerId: MarkerId(station['station_no'].toString()),
                position: position,
                infoWindow: InfoWindow(title: station['station_name']),
                onTap: () => _fetchArrivalInfo(station), // 마커 클릭 시 도착 예정 정보 가져오기
              ),
            );
          }
        }
      }

      setState(() {
        _markers = visibleMarkers;
      });
    });
  }

  // 검색 기능 메서드
  void _searchStations() {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      // 검색어가 비어있으면 모든 마커를 보이도록 설정
      setState(() {
        _searchResults = [];
      });
      return;
    }

    List<Map<String, dynamic>> searchedResults = [];
    for (var station in _allStations) {
      if (station['station_name'].toString().toLowerCase().contains(query.toLowerCase())) {
        searchedResults.add(station);
      }
    }

    setState(() {
      _searchResults = searchedResults; // 검색된 결과로 상태 업데이트
    });
  }

  // 검색 결과 터치 시 지도를 이동하는 메서드
  void _onResultTapped(Map<String, dynamic> station) {
    double? latitude = double.tryParse(station['latitude'].toString());
    double? longitude = double.tryParse(station['longitude'].toString());

    if (latitude != null && longitude != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    }
  }

  // 검색 결과 닫기 메서드
  void _closeSearchResults() {
    setState(() {
      _searchResults = []; // 검색 결과 초기화
    });
    _searchController.clear(); // 검색창 초기화
  }

  Future<void> _fetchArrivalInfo(Map<String, dynamic> station) async {
    String cityCode = station['city_code'];
    String stationNo = station['station_no'];
    String serviceKey = 'qa4QRi0MmBCIBfPxyzq5SC%2FKVh2OlJAhW%2F9u4mzHNTWaLQOMB1w2sOQ4GkW8vb79qw9KroDUnPJDoE11pyOK0Q%3D%3D'; // 실제 서비스 키로 대체하세요.

    var url = 'http://apis.data.go.kr/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList';
    var queryParams = '?serviceKey=$serviceKey&pageNo=1&numOfRows=10&_type=json&cityCode=$cityCode&nodeId=$stationNo';

    // API 요청
    var response = await http.get(Uri.parse(url + queryParams));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      // 응답 데이터 로그 출력
      print('API Response: $data');

      var items = data['response']['body']['items'];

      // 'item'이 배열인지 체크하고, 비어있지 않은지 확인
      List<dynamic> arrivalList = [];
      if (items != null && items is Map && items['item'] != null) {
        if (items['item'] is List) {
          arrivalList = items['item'];
        } else {
          // 단일 객체일 경우 배열로 변환
          arrivalList = [items['item']];
        }
      }

      _showArrivalInfoDialog(station, arrivalList);
    } else {
      // 오류 처리
      print('Error fetching data: ${response.statusCode}');
    }
  }

  void _showArrivalInfoDialog(Map<String, dynamic> station, List<dynamic> arrivalList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${station['station_name']}'),
              Text('도착 예정 정보'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: arrivalList.map<Widget>((arrival) {
                // 도착 예정 버스 정보 출력
                String routeno = arrival['routeno']?.toString() ?? '정보 없음';
                int arrPrevStationCount = arrival['arrprevstationcnt'] ?? 0;
                int arrTime = arrival['arrtime'] ?? 0;
                String routeid = arrival['routeid']?.toString() ?? '정보 없음';

                String formattedTime = _formatTime(arrTime); // 초를 분:초 형식으로 변환

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$routeno: $arrPrevStationCount번째 전, $formattedTime 후 도착',
                    ),
                    IconButton(
                      icon: Icon(Icons.star_border), // 별모양 아이콘
                      onPressed: () async {
                        // 즐겨찾기에 추가
                        await DatabaseHelper().insertFavorite(
                          station['station_no'],
                          int.parse(station['city_code']),
                          routeno,
                          routeid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$routeno 즐겨찾기에 추가됨')),
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );
  }


  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}분 ${remainingSeconds}초';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Map"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainPage()), // MainPage로 이동
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search Station",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchStations,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _loadVisibleMarkers();
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16.0,
              ),
              markers: _markers,
              onCameraIdle: _loadVisibleMarkers,
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('검색 결과 (${_searchResults.length})'),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: _closeSearchResults,
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var station = _searchResults[index];
                      return ListTile(
                        title: Text(station['station_name']),
                        onTap: () => _onResultTapped(station),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
