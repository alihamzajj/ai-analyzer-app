import 'roman_urdu.dart';

/// Multilingual stopword lists to filter out common conversational filler words
/// when extracting top meaningful words from conversations.
class Stopwords {
  static const Set<String> english = {
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', "you're",
    "you've", "you'll", "you'd", 'your', 'yours', 'yourself', 'yourselves', 'he',
    'him', 'his', 'himself', 'she', "she's", 'her', 'hers', 'herself', 'it',
    "it's", 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
    'what', 'which', 'who', 'whom', 'this', 'that', "that'll", 'these', 'those',
    'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
    'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if',
    'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with',
    'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after',
    'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over',
    'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other',
    'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 's', 't', 'can', 'will', 'just', 'don', "don't", 'should',
    "should've", 'now', 'd', 'll', 'm', 'o', 're', 've', 'y', 'ain', 'aren',
    'ok', 'okay', 'yeah', 'yes', 'gonna', 'gotta', 'wanna', 'k', 'ur', 'u',
  };

  static const Set<String> spanish = {
    'de', 'la', 'que', 'el', 'en', 'y', 'a', 'los', 'del', 'se', 'las', 'por',
    'un', 'para', 'con', 'no', 'una', 'su', 'al', 'lo', 'como', 'más', 'pero',
    'sus', 'le', 'ya', 'o', 'este', 'sí', 'porque', 'esta', 'son', 'entre', 'está',
    'cuando', 'muy', 'sin', 'sobre', 'ser', 'tiene', 'también', 'me', 'hasta', 'hay',
    'donde', 'quien', 'desde', 'todo', 'nos', 'durante', 'todos', 'uno', 'les',
    'ni', 'contra', 'otros', 'ese', 'eso', 'ante', 'ellos', 'e', 'esto', 'mí',
    'antes', 'algunos', 'qué', 'unos', 'yo', 'otro', 'otras', 'otra', 'él', 'tanto',
    'esa', 'estos', 'mucho', 'quienes', 'nada', 'muchos', 'cual', 'poco', 'ella',
  };

  static const Set<String> french = {
    'de', 'la', 'le', 'et', 'les', 'des', 'en', 'un', 'du', 'une', 'que', 'est',
    'pour', 'qui', 'dans', 'a', 'par', 'sur', 'au', 'pas', 'plus', 'ce', 'ne',
    'avec', 'se', 'qu', 'son', 'il', 'sont', 'ont', 'ses', 'sa', 'ou', 'mais',
    'nous', 'vous', 'ils', 'je', 'tu', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes',
  };

  static const Set<String> german = {
    'der', 'die', 'und', 'in', 'den', 'von', 'zu', 'das', 'mit', 'sich', 'des',
    'auf', 'für', 'ist', 'im', 'dem', 'nicht', 'ein', 'eine', 'als', 'auch',
    'es', 'an', 'werden', 'aus', 'er', 'hat', 'dass', 'sie', 'nach', 'wird',
    'bei', 'einer', 'um', 'am', 'sind', 'noch', 'wie', 'einem', 'über', 'einen',
  };

  /// Combined lookup set for filtering
  static final Set<String> allStopwords = {
    ...english,
    ...spanish,
    ...french,
    ...german,
    ...RomanUrdu.commonWords,
  };

  /// Returns true if the lowercase word is considered a stopword.
  static bool isStopword(String word) {
    return allStopwords.contains(word.toLowerCase().trim());
  }
}
