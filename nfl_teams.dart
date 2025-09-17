// lib/nfl_teams.dart

class NflTeam {
  final String name;
  final String logoUrl;

  NflTeam({required this.name, required this.logoUrl});
}

// A map where the key is the full team name and the value is the NflTeam object
final Map<String, NflTeam> nflTeamsMap = {
  'Arizona Cardinals': NflTeam(name: 'Arizona Cardinals', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/u9fltoslqdsyao8cpm0k'),
  'Atlanta Falcons': NflTeam(name: 'Atlanta Falcons', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/d8m7hzpsbrl6e5ggr7oc'),
  'Baltimore Ravens': NflTeam(name: 'Baltimore Ravens', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ucsdijmddsqcj1i9tddd'),
  'Buffalo Bills': NflTeam(name: 'Buffalo Bills', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/giphcy6xhlcxrdcfwavg'),
  'Carolina Panthers': NflTeam(name: 'Carolina Panthers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ervfzgrqdpqaqvci8hev'),
  'Chicago Bears': NflTeam(name: 'Chicago Bears', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ra0po5oivfrh6spsbab7'),
  'Cincinnati Bengals': NflTeam(name: 'Cincinnati Bengals', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/okxpmohlwtb4wdjcqrwe'),
  'Cleveland Browns': NflTeam(name: 'Cleveland Browns', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/l5u0fqgi5p8b2k0a2e8g'),
  'Dallas Cowboys': NflTeam(name: 'Dallas Cowboys', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/vewovc3qg26d1ffn1m2s'),
  'Denver Broncos': NflTeam(name: 'Denver Broncos', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/tdegs6zdoq2pwhqwmnbv'),
  'Detroit Lions': NflTeam(name: 'Detroit Lions', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ocxppumawnnla2ht1s2s'),
  'Green Bay Packers': NflTeam(name: 'Green Bay Packers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/gppfbfvynbuqsewafump'),
  'Houston Texans': NflTeam(name: 'Houston Texans', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/bpxqvklobpfhsha33vpy'),
  'Indianapolis Colts': NflTeam(name: 'Indianapolis Colts', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ketwrov2vr9pluntd76b'),
  'Jacksonville Jaguars': NflTeam(name: 'Jacksonville Jaguars', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/qycbib6oiaw9uaeh2n8m'),
  'Kansas City Chiefs': NflTeam(name: 'Kansas City Chiefs', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/v8omw24wx8my8vbe6k1o'),
  'Las Vegas Raiders': NflTeam(name: 'Las Vegas Raiders', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/p5u6vstffkmaweri09ws'),
  'Los Angeles Chargers': NflTeam(name: 'Los Angeles Chargers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/d5s8ctv9udvskzsqlegq'),
  'Los Angeles Rams': NflTeam(name: 'Los Angeles Rams', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ayvwcwsge0s2qrprluxe'),
  'Miami Dolphins': NflTeam(name: 'Miami Dolphins', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/l4acbtdmkprt2c2qrnh4'),
  'Minnesota Vikings': NflTeam(name: 'Minnesota Vikings', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/teguylm5pwpeplfxvha1'),
  'New England Patriots': NflTeam(name: 'New England Patriots', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/moyfni3mgn4t62mdbaq5'),
  'New Orleans Saints': NflTeam(name: 'New Orleans Saints', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/grhjkahghjkk1mvqdyfv'),
  'New York Giants': NflTeam(name: 'New York Giants', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/pfsd6zga4s80t6csflm2'),
  'New York Jets': NflTeam(name: 'New York Jets', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/wzxlscyolrsv9h4yitfy'),
  'Philadelphia Eagles': NflTeam(name: 'Philadelphia Eagles', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/puhrqgj71sgselm2vpef'),
  'Pittsburgh Steelers': NflTeam(name: 'Pittsburgh Steelers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/zb3bf035fvnqtc1wepeq'),
  'San Francisco 49ers': NflTeam(name: 'San Francisco 49ers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/sfpt1zskx3eaf1urse7y'),
  'Seattle Seahawks': NflTeam(name: 'Seattle Seahawks', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/wz5k4nwfyh2d9a3fabeu'),
  'Tampa Bay Buccaneers': NflTeam(name: 'Tampa Bay Buccaneers', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/fqgtfqsjeo1oex5w7dma'),
  'Tennessee Titans': NflTeam(name: 'Tennessee Titans', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ex2yofbujvdtqayredds'),
  'Washington Commanders': NflTeam(name: 'Washington Commanders', logoUrl: 'https://static.www.nfl.com/image/private/f_auto/league/ypylnbonyrepgeovjfj4'),
};