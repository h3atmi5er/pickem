// lib/nfl_teams.dart

class NflTeam {
  final String name;
  final String logoAssetPath; // Changed from logoUrl

  NflTeam({required this.name, required this.logoAssetPath});
}

// A map where the key is the full team name and the value points to the local asset
final Map<String, NflTeam> nflTeamsMap = {
  'Arizona Cardinals': NflTeam(name: 'Arizona Cardinals', logoAssetPath: 'assets/logos/ARI.png'),
  'Atlanta Falcons': NflTeam(name: 'Atlanta Falcons', logoAssetPath: 'assets/logos/ATL.png'),
  'Baltimore Ravens': NflTeam(name: 'Baltimore Ravens', logoAssetPath: 'assets/logos/BAL.png'),
  'Buffalo Bills': NflTeam(name: 'Buffalo Bills', logoAssetPath: 'assets/logos/BUF.png'),
  'Carolina Panthers': NflTeam(name: 'Carolina Panthers', logoAssetPath: 'assets/logos/CAR.png'),
  'Chicago Bears': NflTeam(name: 'Chicago Bears', logoAssetPath: 'assets/logos/CHI.png'),
  'Cincinnati Bengals': NflTeam(name: 'Cincinnati Bengals', logoAssetPath: 'assets/logos/CIN.png'),
  'Cleveland Browns': NflTeam(name: 'Cleveland Browns', logoAssetPath: 'assets/logos/CLE.png'),
  'Dallas Cowboys': NflTeam(name: 'Dallas Cowboys', logoAssetPath: 'assets/logos/DAL.png'),
  'Denver Broncos': NflTeam(name: 'Denver Broncos', logoAssetPath: 'assets/logos/DEN.png'),
  'Detroit Lions': NflTeam(name: 'Detroit Lions', logoAssetPath: 'assets/logos/DET.png'),
  'Green Bay Packers': NflTeam(name: 'Green Bay Packers', logoAssetPath: 'assets/logos/GB.png'),
  'Houston Texans': NflTeam(name: 'Houston Texans', logoAssetPath: 'assets/logos/HOU.png'),
  'Indianapolis Colts': NflTeam(name: 'Indianapolis Colts', logoAssetPath: 'assets/logos/IND.png'),
  'Jacksonville Jaguars': NflTeam(name: 'Jacksonville Jaguars', logoAssetPath: 'assets/logos/JAX.png'),
  'Kansas City Chiefs': NflTeam(name: 'Kansas City Chiefs', logoAssetPath: 'assets/logos/KC.png'),
  'Las Vegas Raiders': NflTeam(name: 'Las Vegas Raiders', logoAssetPath: 'assets/logos/LV.png'),
  'Los Angeles Chargers': NflTeam(name: 'Los Angeles Chargers', logoAssetPath: 'assets/logos/LAC.png'),
  'Los Angeles Rams': NflTeam(name: 'Los Angeles Rams', logoAssetPath: 'assets/logos/LAR.png'),
  'Miami Dolphins': NflTeam(name: 'Miami Dolphins', logoAssetPath: 'assets/logos/MIA.png'),
  'Minnesota Vikings': NflTeam(name: 'Minnesota Vikings', logoAssetPath: 'assets/logos/MIN.png'),
  'New England Patriots': NflTeam(name: 'New England Patriots', logoAssetPath: 'assets/logos/NE.png'),
  'New Orleans Saints': NflTeam(name: 'New Orleans Saints', logoAssetPath: 'assets/logos/NO.png'),
  'New York Giants': NflTeam(name: 'New York Giants', logoAssetPath: 'assets/logos/NYG.png'),
  'New York Jets': NflTeam(name: 'New York Jets', logoAssetPath: 'assets/logos/NYJ.png'),
  'Philadelphia Eagles': NflTeam(name: 'Philadelphia Eagles', logoAssetPath: 'assets/logos/PHI.png'),
  'Pittsburgh Steelers': NflTeam(name: 'Pittsburgh Steelers', logoAssetPath: 'assets/logos/PIT.png'),
  'San Francisco 49ers': NflTeam(name: 'San Francisco 49ers', logoAssetPath: 'assets/logos/SF.png'),
  'Seattle Seahawks': NflTeam(name: 'Seattle Seahawks', logoAssetPath: 'assets/logos/SEA.png'),
  'Tampa Bay Buccaneers': NflTeam(name: 'Tampa Bay Buccaneers', logoAssetPath: 'assets/logos/TB.png'),
  'Tennessee Titans': NflTeam(name: 'Tennessee Titans', logoAssetPath: 'assets/logos/TEN.png'),
  'Washington Commanders': NflTeam(name: 'Washington Commanders', logoAssetPath: 'assets/logos/WAS.png'),
};