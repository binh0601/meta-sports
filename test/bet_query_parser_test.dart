import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/bet_query_parser.dart';
import 'package:house_edge_demo/logic/football_market.dart';

void main() {
  const teams = ['Việt Nam', 'Thái Lan', 'Đức', 'Pháp'];

  test('cau rong -> filter rong', () {
    final f = BetQueryParser.parse('', teams);
    expect(f.isEmpty, true);
  });

  test('nhan dien cua nha + odds duoi', () {
    final f = BetQueryParser.parse('kèo cửa nhà dưới 2.0', teams);
    expect(f.sideHome, true);
    expect(f.maxOdds, 2.0);
  });

  test('nhan dien cua khach + odds tren', () {
    final f = BetQueryParser.parse('kèo đội khách trên 1.85', teams);
    expect(f.sideHome, false);
    expect(f.minOdds, 1.85);
  });

  test('nhan dien giai world cup', () {
    final f = BetQueryParser.parse('trận world cup tối nay', teams);
    expect(f.league, League.worldCup);
  });

  test('nhan dien giai chau a', () {
    final f = BetQueryParser.parse('kèo châu Á đêm nay', teams);
    expect(f.league, League.asianCup);
  });

  test('nhan dien ten doi trong danh sach', () {
    final f = BetQueryParser.parse('cửa Việt Nam thắng', teams);
    expect(f.teamKeywords, contains('Việt Nam'));
  });

  test('cau vo nghia khong khop gi -> filter rong', () {
    final f = BetQueryParser.parse('asdkjaslkdj random text', teams);
    expect(f.isEmpty, true);
  });

  // Regression tests: word boundary matching to prevent false positives
  // for short team names after diacritic normalization
  test('short team name "Ý" should NOT match as substring in common word', () {
    // 'Ý' normalizes to 'y', but should not match inside 'nay' (today)
    const shortTeams = ['Ý', 'Úc', 'Đức'];
    final f = BetQueryParser.parse('kèo tối nay', shortTeams);
    expect(f.teamKeywords, isNot(contains('Ý')),
        reason:
            'Team "Ý" should not match in "kèo tối nay" (contains "y" as part of "nay")');
  });

  test('short team name "Úc" should NOT match as substring in common word',
      () {
    // 'Úc' normalizes to 'uc', but should not match inside 'thực' -> 'thuc'
    const shortTeams = ['Úc'];
    final f = BetQueryParser.parse('kèo thực tế nào', shortTeams);
    expect(f.teamKeywords, isNot(contains('Úc')),
        reason:
            'Team "Úc" should not match in "kèo thực tế nào" (contains "uc" as part of "thuc")');
  });

  test('short team name "Ý" SHOULD match when explicitly mentioned as word',
      () {
    // When 'Ý' is mentioned as a standalone word, it should match
    const shortTeams = ['Ý'];
    final f = BetQueryParser.parse('kèo Ý thắng', shortTeams);
    expect(f.teamKeywords, contains('Ý'),
        reason: 'Team "Ý" should match when mentioned as standalone word');
  });

  test('short team name "Úc" SHOULD match when explicitly mentioned as word',
      () {
    // When 'Úc' is mentioned as a standalone word, it should match
    const shortTeams = ['Úc'];
    final f = BetQueryParser.parse('cửa Úc dưới 2.0', shortTeams);
    expect(f.teamKeywords, contains('Úc'),
        reason: 'Team "Úc" should match when mentioned as standalone word');
  });

  test('multi-word team name regression: "Việt Nam" still matches correctly',
      () {
    // Ensure multi-word team names still work after word boundary fix
    final f = BetQueryParser.parse('cửa Việt Nam thắng', teams);
    expect(f.teamKeywords, contains('Việt Nam'),
        reason: 'Multi-word team "Việt Nam" should still match correctly');
  });

  test('multi-word team name should NOT match if only partial phrase in query',
      () {
    // 'Việt Nam' should not match if only 'Việt' appears (as partial phrase)
    final f = BetQueryParser.parse('cửa Việt thắng', teams);
    expect(f.teamKeywords, isNot(contains('Việt Nam')),
        reason:
            'Multi-word team "Việt Nam" should not match if only first word appears');
  });
}
