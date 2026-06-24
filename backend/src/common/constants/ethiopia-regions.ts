// Ethiopia administrative regions and major cities
// Sourced from publicly available census data
export const ETHIOPIA_REGIONS_AND_CITIES: Record<string, string[]> = {
  'Addis Ababa': [
    'Addis Ababa',
    'Akaki',
    'Bole',
    'Gulele',
    'Kirkos',
    'Kolfe Keranio',
    'Lideta',
    'Nifas Silk-Lafto',
    'Yeka',
  ],
  'Afar': ['Asayita', 'Awash', 'Dubti', 'Logia', 'Samara'],
  'Amhara': [
    'Bahir Dar',
    'Debre Berhan',
    'Debre Markos',
    'Dessie',
    'Gondar',
    'Kombolcha',
    'Lalibela',
    'Woldia',
  ],
  'Benishangul-Gumuz': ['Assosa', 'Kamashi', 'Menge'],
  'Dire Dawa': ['Dire Dawa'],
  'Gambela': ['Gambela', 'Itang'],
  'Harari': ['Harar', 'Dire Te'],
  'Oromia': [
    'Adama (Nazret)',
    'Ambo',
    'Asella',
    'Bishoftu (Debre Zeit)',
    'Bale Robe',
    'Dodola',
    'Jimma',
    'Meki',
    'Mojo',
    'Negele Borena',
    'Nekemte',
    'Robe',
    'Sebeta',
    'Shashamene',
    'Waliso',
    'Ziway',
  ],
  'Sidama': ['Hawassa', 'Yirgachefe'],
  'SNNPR': [
    'Arba Minch',
    'Dilla',
    'Hosaena',
    'Sodo',
    'Turmi',
    'Wolaita Sodo',
    'Yirgalem',
  ],
  'Somali': ['Degehabur', 'Gode', 'Jijiga', 'Kebri Dehar', 'Warder'],
  'Tigray': [
    'Adwa',
    'Axum',
    'Humera',
    'Korem',
    'Mekelle',
    'Shire (Inda Selassie)',
    'Wukro',
  ],
};

// Ordered list for consistent UI
export const ETHIOPIA_REGIONS = Object.keys(ETHIOPIA_REGIONS_AND_CITIES);

export function getCitiesForRegion(region: string): string[] {
  return ETHIOPIA_REGIONS_AND_CITIES[region] ?? [];
}