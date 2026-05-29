String getMembersCountString(int count) {
  int lastDigit = count % 10;
  switch (lastDigit) {
    case 1:
      return '$count участник';
    case 2:
    case 3:
    case 4:
      return '$count участника';
    default:
      return '$count участников';
  } 
}