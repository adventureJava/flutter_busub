<h1>버스 실시간 운행 정보 앱 BUSUB </h1>

<h2>1.소개</h2>
버스 실시간 운행정보를 알려주는 앱입니다.<br>

<h2>2.제작 기간 </h2> 
10/12,14,15 총 3일 <br>
            10/16 배포<br>
<h2>3.인원</h2>
1인<br><br>


<h2>4.개발환경 </h2>
Flutter, SQLite <br>
사용 라이브러리 : 구글맵 API, 공공데이터 API(정류장csv파일, 정류장별 실시간 도착정보, 정류장+노선별 실시간 도착정보)<br><br>

<h2>5.구현 화면</h2><br>

![image](https://github.com/user-attachments/assets/83af54a6-1315-4b18-ad81-27c8f9f62823)
<br>
처음 앱을 실행하면 20만여개의 공공데이터 csv파일을 station테이블에 저장합니다. 데이터를 삽입하는 동안 로딩 화면이 나옵니다.
<br>
<br>

![image](https://github.com/user-attachments/assets/0c9a6b5d-d621-4736-b23d-4483f219dedb)
<br>
메인 화면 입니다. 
즐겨찾기한 버스 목록이 표시됩니다. 
상단에는 지도 버튼, 
하단에는 새로고침 버튼이 있습니다.
<br>
<br>

![image](https://github.com/user-attachments/assets/9fb16b47-6428-4863-a760-b56627aebe28)
<br>
지도버튼을 터치하면 나오는 지도 화면 입니다. 
붉은 마커는 정류장을 표시합니다.
<br><br>
![image](https://github.com/user-attachments/assets/33910c69-53ea-4a9a-9e5a-2ba80510c44e)
<br>
검색 결과 터치시 해당 장소로 이동합니다.
<br>
<br>
![image](https://github.com/user-attachments/assets/d3889a55-0206-4b7b-b0a5-c82414e9e541)
![image](https://github.com/user-attachments/assets/81d60de9-8170-4738-83a4-5877702a6998)
<br>
마커를 터치하면 도착정보가 나오고 즐겨찾기 버튼을 누르면 해당 노선이 저장됩니다.
<br>
<br>

![image](https://github.com/user-attachments/assets/bb0acd20-8056-495d-8b4c-de0e6d4d44b0)
![image](https://github.com/user-attachments/assets/4e976995-8d96-451d-8df1-d6fa3fe74f2f)
<br>
안드로이드용으로 apk제작까지 완료되었습니다. 아이콘 이미지는 자체제작이 아닌 무단 사용하였기 때문에 상용화할 계획은 없습니다.










