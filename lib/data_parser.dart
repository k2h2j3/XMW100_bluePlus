List<int> parseData(String jsonData) {
  String cleanData = jsonData.replaceAll(RegExp(r'[\[\] ]'), '');
  List<int> dataList = cleanData.split(',').map(int.parse).toList();
  return dataList;
}