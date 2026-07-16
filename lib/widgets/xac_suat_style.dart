import 'package:flutter/material.dart';

import '../logic/xac_suat_math.dart';

/// Nhan + mau hien thi cho game "Keo Chop 30s" — gom mot cho de dong bo
/// giua bet pad, bang ket qua va dai lich su (DRY).

// Mau tung loai keo (khac mau thuong hieu app — day la mau luat choi).
const Color kXsTai = Color(0xFFF59E0B); // vang cam — nhieu ban
const Color kXsXiu = Color(0xFF38BDF8); // xanh bang — it ban
const Color kXsLe = Color(0xFF22C55E); // xanh la — tong le
const Color kXsChan = Color(0xFFEF4444); // do — tong chan
const Color kXsSpecial = Color(0xFFA855F7); // tim — 0 & 5

Color xsKindColor(XsBetKind kind) {
  switch (kind) {
    case XsBetKind.tai:
      return kXsTai;
    case XsBetKind.xiu:
      return kXsXiu;
    case XsBetKind.le:
      return kXsLe;
    case XsBetKind.chan:
      return kXsChan;
    case XsBetKind.dacBiet:
      return kXsSpecial;
    case XsBetKind.dungTong:
      return const Color(0xFFFBBF24);
  }
}

String xsKindLabel(XsBetKind kind) {
  switch (kind) {
    case XsBetKind.tai:
      return 'TÀI';
    case XsBetKind.xiu:
      return 'XỈU';
    case XsBetKind.le:
      return 'LẺ';
    case XsBetKind.chan:
      return 'CHẴN';
    case XsBetKind.dacBiet:
      return 'ĐẶC BIỆT';
    case XsBetKind.dungTong:
      return 'ĐÚNG TỔNG';
  }
}

/// Goi y ngan hien duoi ten keo.
String xsKindHint(XsBetKind kind) {
  switch (kind) {
    case XsBetKind.tai:
      return '≥ 5 bàn · ×2';
    case XsBetKind.xiu:
      return '≤ 4 bàn · ×2';
    case XsBetKind.le:
      return 'tổng lẻ · ×2';
    case XsBetKind.chan:
      return 'tổng chẵn · ×2';
    case XsBetKind.dacBiet:
      return '0 hoặc 5 · ×4.5';
    case XsBetKind.dungTong:
      return 'trúng số · ×9';
  }
}

/// Mau cho o so 0–9 theo bang mau spec: le -> xanh, chan -> do.
Color xsNumberColor(int n) => n.isOdd ? kXsLe : kXsChan;

/// 0 va 5 la so "dac biet" (co vien tim).
bool xsNumberIsSpecial(int n) => n == 0 || n == 5;
