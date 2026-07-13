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
}
