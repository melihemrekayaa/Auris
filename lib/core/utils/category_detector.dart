/// Makalenin ham meta bilgilerinden (başlık, kategori, URL) anlamlı bir
/// üst-kategori ve alt-kategori çifti üretir.
/// Örn: "Man City" → "Sports · Football"
class CategoryDetector {
  static String detect({
    required String title,
    String? rawCategory,
    String? url,
  }) {
    final text = '${title.toLowerCase()} ${(rawCategory ?? '').toLowerCase()} ${(url ?? '').toLowerCase()}';

    // --- SPORTS ---
    const footballKeywords = [
      'football', 'soccer', 'premier league', 'champions league', 'la liga',
      'bundesliga', 'serie a', 'transfer', 'midfielder', 'striker', 'goalkeeper',
      'man city', 'manchester', 'arsenal', 'chelsea', 'liverpool', 'barcelona',
      'real madrid', 'bayern', 'psg', 'juventus', 'tottenham', 'foden', 'mbappe',
      'haaland', 'messi', 'ronaldo', 'neymar', 'epl', 'uefa', 'fifa', 'world cup',
    ];
    const basketballKeywords = ['basketball', 'nba', 'lebron', 'lakers', 'celtics', 'warriors'];
    const f1Keywords = ['formula 1', 'f1', 'grand prix', 'verstappen', 'hamilton'];
    const tennisKeywords = ['tennis', 'wimbledon', 'roland garros', 'nadal', 'djokovic'];
    const generalSportsKeywords = ['sport', 'athlete', 'olympics', 'medal', 'championship', 'coach', 'match'];

    for (var kw in footballKeywords) {
      if (text.contains(kw)) return 'Sports · Football';
    }
    for (var kw in basketballKeywords) {
      if (text.contains(kw)) return 'Sports · Basketball';
    }
    for (var kw in f1Keywords) {
      if (text.contains(kw)) return 'Sports · Formula 1';
    }
    for (var kw in tennisKeywords) {
      if (text.contains(kw)) return 'Sports · Tennis';
    }
    for (var kw in generalSportsKeywords) {
      if (text.contains(kw)) return 'Sports';
    }

    // --- TECHNOLOGY ---
    const techKeywords = ['tech', 'technology', 'ai', 'artificial intelligence', 'startup', 'software', 'apple', 'google', 'microsoft', 'openai', 'robot', 'algorithm', 'coding', 'developer', 'silicon valley', 'chip', 'semiconductor'];
    for (var kw in techKeywords) {
      if (text.contains(kw)) return 'Technology';
    }

    // --- POLITICS ---
    const politicsKeywords = ['politic', 'election', 'president', 'parliament', 'senate', 'congress', 'democrat', 'republican', 'vote', 'diplomacy', 'sanction', 'treaty', 'minister', 'government', 'policy'];
    for (var kw in politicsKeywords) {
      if (text.contains(kw)) return 'Politics';
    }

    // --- WORLD / WAR ---
    const worldKeywords = ['war', 'conflict', 'military', 'invasion', 'troops', 'nato', 'ukraine', 'russia', 'china', 'gaza', 'israel', 'iran', 'nuclear'];
    for (var kw in worldKeywords) {
      if (text.contains(kw)) return 'World';
    }

    // --- BUSINESS / ECONOMY ---
    const bizKeywords = ['business', 'economy', 'stock', 'market', 'finance', 'investment', 'inflation', 'gdp', 'trade', 'wall street', 'crypto', 'bitcoin', 'bank'];
    for (var kw in bizKeywords) {
      if (text.contains(kw)) return 'Business';
    }

    // --- SCIENCE ---
    const sciKeywords = ['science', 'research', 'study', 'nasa', 'space', 'climate', 'environment', 'biology', 'physics', 'discovery'];
    for (var kw in sciKeywords) {
      if (text.contains(kw)) return 'Science';
    }

    // --- HEALTH ---
    const healthKeywords = ['health', 'medical', 'doctor', 'hospital', 'disease', 'virus', 'vaccine', 'mental health', 'cancer', 'who'];
    for (var kw in healthKeywords) {
      if (text.contains(kw)) return 'Health';
    }

    // --- ENTERTAINMENT ---
    const entKeywords = ['entertainment', 'movie', 'film', 'music', 'celebrity', 'hollywood', 'netflix', 'disney', 'album', 'concert', 'tv show', 'series'];
    for (var kw in entKeywords) {
      if (text.contains(kw)) return 'Entertainment';
    }

    // Fallback: ham kategoriyi düzenle veya 'News'
    if (rawCategory != null && rawCategory.isNotEmpty) {
      return rawCategory;
    }
    return 'News';
  }
}
