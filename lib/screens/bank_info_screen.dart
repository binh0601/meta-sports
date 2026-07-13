import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../services/player_repository.dart';
import '../theme/brand_colors.dart';

class BankInfoScreen extends StatefulWidget {
  const BankInfoScreen({super.key});

  @override
  State<BankInfoScreen> createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends State<BankInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _accountNameCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final g = gameState;
    _bankNameCtrl = TextEditingController(text: g.bankName);
    _accountNoCtrl = TextEditingController(text: g.bankAccountNo);
    _accountNameCtrl = TextEditingController(text: g.bankAccountName);
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    
    final bName = _bankNameCtrl.text.trim();
    final bNo = _accountNoCtrl.text.trim();
    final bAccName = _accountNameCtrl.text.trim().toUpperCase();

    final success = await PlayerRepository.instance.updateBankInfo(
      user.uid,
      bName,
      bNo,
      bAccName,
    );

    if (mounted) {
      if (success) {
        gameState.setBankInfo(bName, bNo, bAccName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật thông tin ngân hàng thành công!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật thất bại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Thông tin Rút tiền'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kBrandGradient),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vui lòng điền chính xác thông tin ngân hàng của bạn để Admin chuyển khoản khi bạn rút tiền.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _bankNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Ngân hàng (VD: MB, VCB, Momo)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _accountNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Số Tài Khoản',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _accountNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Chủ Tài Khoản',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('LƯU THÔNG TIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
