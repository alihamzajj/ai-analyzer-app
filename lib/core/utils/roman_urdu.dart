/// Helpers for Roman Urdu (Urdu written in Latin letters), the way most
/// Pakistani WhatsApp chats are typed: "acha theek hai", "kya kar rahe ho?".
///
/// Spelling is not standardised, so every list includes the common variants
/// (e.g. nahi / nai / nahin, kyun / kyu / q).
class RomanUrdu {
  /// Output-language code used for Roman Urdu reports.
  static const String languageCode = 'ur-Latn';

  /// High-frequency Roman Urdu words. Used both to detect Roman Urdu chats
  /// and as stopwords so they don't flood the "top words" list.
  static const Set<String> commonWords = {
    // verbs / auxiliaries
    'hai', 'hain', 'hy', 'he', 'ho', 'hon', 'hun', 'hoon', 'tha', 'thi', 'thay',
    'the', 'hoga', 'hogi', 'hoge', 'hogay', 'raha', 'rahi', 'rahe', 'rhe', 'rha',
    'rhi', 'kar', 'kr', 'karo', 'kro', 'karna', 'krna', 'karta', 'krta', 'karti',
    'krti', 'karte', 'krte', 'kiya', 'kia', 'gaya', 'gya', 'gayi', 'gai', 'gye',
    'diya', 'dia', 'lena', 'dena', 'jana', 'ana', 'aana', 'chal', 'chalo', 'ga',
    'gi', 'ge', 'sakta', 'sakti', 'sakte', 'skta', 'skti', 'skte', 'wala', 'wali',
    'wale', 'hua', 'hui', 'hue', 'huwa', 'krdo', 'kardo', 'krdia', 'kardia',
    // pronouns
    'main', 'mein', 'mai', 'me', 'mujhe', 'mjhe', 'muje', 'mera', 'meri', 'mere',
    'tum', 'tm', 'tu', 'tujhe', 'tera', 'teri', 'tere', 'tumhara', 'tumhari',
    'tumhare', 'ap', 'aap', 'apka', 'apki', 'apke', 'aapka', 'aapki', 'hum', 'hm',
    'hamara', 'hamari', 'humara', 'humari', 'woh', 'wo', 'vo', 'yeh', 'ye', 'is',
    'us', 'isko', 'usko', 'inko', 'unko', 'iska', 'uska', 'unka', 'apna', 'apni',
    'apne', 'sab', 'koi', 'kuch', 'kch',
    // postpositions / connectors
    'ka', 'ki', 'ke', 'ko', 'se', 'sy', 'pe', 'par', 'pr', 'tak', 'liye', 'lie',
    'lye', 'sath', 'saath', 'aur', 'or', 'bhi', 'bi', 'to', 'toh', 'tou', 'lekin',
    'magar', 'agar', 'phir', 'fir', 'ab', 'abhi', 'bhai', 'jab', 'tab', 'bas',
    'ya', 'na', 'nhi', 'nahi', 'nai', 'nahin', 'mat', 'han', 'haan', 'hn', 'ji',
    'jee', 'acha', 'achha', 'accha', 'theek', 'thik', 'thk', 'yaar', 'yar',
    'hmm', 'hmmm', 'kyun', 'kyu', 'kyon', 'kya', 'kab', 'kahan', 'kaha', 'kaise',
    'kese', 'kesy', 'kaisi', 'kesi', 'kon', 'kaun', 'konsa', 'kitna', 'kitni',
    'kidhar', 'idhar', 'udhar', 'yahan', 'wahan', 'bohat', 'bohot', 'bht', 'bahut',
    'zyada', 'ziada', 'thora', 'thoda', 'thori', 'sahi', 'wese', 'waise', 'aise',
    'aese', 'matlab', 'mtlb', 'pata', 'pta',
  };

  /// Question words. Roman Urdu questions are often sent without a "?".
  static final RegExp questionPattern = RegExp(
    r'\b(kya|kia|kyun|kyu|kyon|kab|kahan|kaha|kidhar|kaise|kese|kesy|kaisi|kesi|kon|kaun|konsa|kitna|kitni|kitne)\b',
  );

  /// Laughter as typed in Pakistani chats, on top of the English markers.
  static const List<String> laughMarkers = ['hahah', 'hhhh', 'hehe', 'hihi', 'ahah'];

  /// Roman Urdu / Urdu synonyms for the tracked keyword buckets. Keys match
  /// the existing keyword names so saved reports stay compatible.
  static const Map<String, List<String>> keywordSynonyms = {
    'sorry': ['maaf', 'maafi', 'mafi', 'sory', 'sorry yaar'],
    'thanks': ['shukriya', 'shukria', 'thank you', 'thanku', 'thnx', 'thx', 'jazakallah', 'jzk'],
    'miss you': ['miss u', 'yaad aa', 'yad aa', 'yaad aya', 'yaad ati'],
    'love': ['pyar', 'pyaar', 'mohabbat', 'muhabbat', 'luv', 'jaan'],
    'goodnight': ['good night', 'gn', 'shab bakhair', 'so jao', 'so ja'],
    'good morning': ['gm', 'subah bakhair', 'subha bakhair', 'morning'],
  };

  static final RegExp _token = RegExp(r"[a-z']+");

  /// Share (0–1) of text messages that contain at least two common Roman
  /// Urdu words. English chats score near 0, Roman Urdu chats well above 0.3.
  static double score(Iterable<String> messages) {
    var checked = 0;
    var hits = 0;
    for (final m in messages) {
      final words = _token.allMatches(m.toLowerCase()).map((x) => x.group(0)!).toList();
      if (words.length < 2) continue;
      checked++;
      var found = 0;
      for (final w in words) {
        if (commonWords.contains(w) && !_englishOverlap.contains(w)) {
          found++;
          if (found >= 2) break;
        }
      }
      if (found >= 2) hits++;
      if (checked >= 600) break;
    }
    return checked == 0 ? 0 : hits / checked;
  }

  /// True when the chat is mostly Roman Urdu.
  static bool isMostlyRomanUrdu(Iterable<String> messages) => score(messages) >= 0.25;

  // Words that are also everyday English; ignored for detection only.
  static const Set<String> _englishOverlap = {
    'he', 'me', 'the', 'is', 'us', 'to', 'or', 'na', 'ya', 'main', 'tab', 'bas', 'par', 'mat', 'pe', 'sab', 'hum',
  };
}
