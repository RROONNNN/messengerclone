class CommonFunction {
  static String getGroupChatId(String idFrom, String idTo) {
    return idFrom.hashCode <= idTo.hashCode ? '$idFrom-$idTo' : '$idTo-$idFrom';
  }
}
