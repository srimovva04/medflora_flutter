class Config {

  static const String apiUrl = 'http://127.0.0.1:5001';
  static String getHistoryImageUrl(String imageId) => "$apiUrl/history/image/$imageId";

}
