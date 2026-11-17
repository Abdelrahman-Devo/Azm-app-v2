/// Arabic motivational messages. The message is chosen from the user's real
/// progress for the day, and rotates deterministically by date (no randomness).
String motivationFor({
  required int todayTotal,
  required int todayDone,
  required int streak,
  required DateTime today,
}) {
  final List<String> pool;
  if (todayTotal == 0) {
    pool = const [
      'ابدأ بعادة صغيرة اليوم؛ البدايات الصغيرة تصنع تغييرًا كبيرًا.',
      'أضف عادتك الأولى وابنِ يومك حول ما يهمك.',
    ];
  } else if (todayDone == todayTotal) {
    pool = const [
      'أتممت كل عادات اليوم، هذا هو الانضباط الحقيقي.',
      'يوم مكتمل! استمر على هذا النسق وستذهل نفسك.',
      'ما فعلته اليوم يبني شخصية الغد. أحسنت.',
    ];
  } else if (todayDone == 0) {
    pool = const [
      'خطوة واحدة الآن تكفي لكسر الجمود. ابدأ بأسهل عادة.',
      'لا تنتظر الحافز، ابدأ وسيأتي الحافز بعد البدء.',
      'الانضباط هو أن تفعل ما يجب عليك فعله حين لا ترغب.',
    ];
  } else {
    pool = const [
      'أنت في منتصف الطريق، أكمل ما تبقى.',
      'تقدم رائع! عادة أخرى وتقترب من يوم مكتمل.',
      'الاستمرار أهم من الكمال. واصل.',
    ];
  }
  final index = (today.year * 366 + today.month * 31 + today.day) % pool.length;
  final base = pool[index];
  if (streak >= 3 && todayDone < todayTotal) {
    return 'سلسلتك $streak أيام، حافظ عليها اليوم. $base';
  }
  return base;
}
