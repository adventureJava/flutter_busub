import 'package:flutter/material.dart';
import 'main_page.dart'; // MainPage가 정의된 파일
import 'databaseHelper.dart'; // DatabaseHelper가 정의된 파일

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoadingPage(), // 로딩 페이지로 시작
    );
  }
}

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    // 데이터를 초기화하는 Future를 저장
    _initializationFuture = _initializeData();
  }

  // 비동기 작업을 처리하는 메서드
  Future<void> _initializeData() async {
    await DatabaseHelper().createStationTableAndInsertData(); // 데이터 삽입 작업
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture, // Future를 한번만 호출
      builder: (context, snapshot) {
        // 데이터 로딩 중일 때 로딩 화면 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('초기 데이터를 입력중입니다...'),
                ],
              ),
            ),
          );
        }
        // 데이터 로딩이 완료되면 MainPage로 이동 북인천우체국
        else if (snapshot.connectionState == ConnectionState.done) {
          return MainPage(); // 데이터 삽입이 완료되면 MainPage로 이동
        }
        // 오류 발생 시 오류 메시지 표시
        else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('오류 발생: ${snapshot.error}'),
            ),
          );
        } else {
          return Container(); // 예외 상황 처리
        }
      },
    );
  }
}
