import 'package:flutter/material.dart';

/// Bang mau thuong hieu "MEGA SPORTS" — xanh royal + vang tien thuong,
/// dung chung cho moi man hinh de dong bo (khong hardcode le te).
const Color kGold = Color(0xFFFBBF24);
const Color kGoldDark = Color(0xFFB45309);

/// Gradient chinh: xanh royal -> navy dem (header, nut chon, wallet).
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1D4ED8), Color(0xFF0B1026)],
);

/// Gradient hero cho man chi tiet tran: xanh -> tim dem.
const LinearGradient kHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF2563EB), Color(0xFF1E1B4B)],
);
