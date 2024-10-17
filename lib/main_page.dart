import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'map_page.dart';
import 'databaseHelper.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> _favoriteList = [];
  List<Map<String, dynamic>> _busArrivalInfo = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final db = await DatabaseHelper().database;
    List<Map<String, dynamic>> favoriteList = await db.query('favorite');
    print('Favorite list loaded: $favoriteList');
    setState(() {
      _favoriteList = favoriteList;
      _busArrivalInfo.clear();
    });

    if (_favoriteList.isNotEmpty) {
      for (var favorite in _favoriteList) {
        await _fetchBusArrivalInfo(
            favorite['id'],favorite['station_no'], favorite['city_code'], favorite['routeid']);
      }
    } else {
      print('Favorite list is empty');
    }
  }

  Future<void> _fetchBusArrivalInfo(int id, String stationNo, int cityCode, String routeId) async {
    final String serviceKey = 'qa4QRi0MmBCIBfPxyzq5SC/KVh2OlJAhW/9u4mzHNTWaLQOMB1w2sOQ4GkW8vb79qw9KroDUnPJDoE11pyOK0Q==';
    final String url =
        'http://apis.data.go.kr/1613000/ArvlInfoInqireService/getSttnAcctoSpcifyRouteBusArvlPrearngeInfoList';
    final Map<String, String> queryParams = {
      'serviceKey': serviceKey,
      'pageNo': '1',
      'numOfRows': '10',
      '_type': 'xml',
      'cityCode': cityCode.toString(),
      'nodeId': stationNo,
      'routeId': routeId,
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(utf8.decode(response.bodyBytes));
      final items = document.findAllElements('item');

      if (items.isNotEmpty) {
        for (var item in items) {
          String stationName = item.findElements('nodenm').single.text;
          String routeNo = item.findElements('routeno').single.text;
          int arrPrevStationCount = int.parse(item.findElements('arrprevstationcnt').single.text);
          int arrTime = int.parse(item.findElements('arrtime').single.text);

          String formattedTime = _formatTime(arrTime);
          _displayArrivalInfo(id,stationName, routeNo, arrPrevStationCount, formattedTime);
        }
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes분 $remainingSeconds초';
  }

  void _displayArrivalInfo(int id,String stationName, String routeNo, int arrPrevStationCount, String formattedTime) {
    setState(() {
      _busArrivalInfo.add({
        'stationName': stationName,
        'routeNo': routeNo,
        'arrPrevStationCount': arrPrevStationCount,
        'formattedTime': formattedTime,
        'id': id,
      });
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _busArrivalInfo.clear();
    });
    await _loadFavorites();
  }

  // 삭제 메서드
  Future<void> _deleteFavorite(int id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('즐겨찾기 삭제'),
          content: Text('즐겨찾기에서 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 삭제 확인
              child: Text('예'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 삭제 취소
              child: Text('아니오'),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      await DatabaseHelper().deleteFavorite(id);
      setState(() {
        _busArrivalInfo.removeWhere((info) => info['id'] == id); // 해당 id 삭제
        _loadFavorites(); // 즐겨찾기 재로드
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DatabaseHelper().createFavoriteTable();
    return Scaffold(
      appBar: AppBar(
        title: Text('버스 실시간 정보'),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Center(
          child: _busArrivalInfo.isEmpty
              ? Text('도착 예정 정보가 없습니다.')
              : ListView.builder(
            itemCount: _busArrivalInfo.length,
            itemBuilder: (context, index) {
              var info = _busArrivalInfo[index];
              return ListTile(
                title: Text('${info['stationName']} / ${info['routeNo']}번'),
                subtitle: Text('${info['arrPrevStationCount']}번째 전 / ${info['formattedTime']} 후 도착'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // 삭제 버튼 클릭 시
                    _deleteFavorite(info['id']); // id를 기반으로 삭제
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
