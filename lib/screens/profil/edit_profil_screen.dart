// lib/screens/profil/edit_profil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _emailCtrl, _hpCtrl, _alamatCtrl;
  bool _loading = false;
  String? _error, _success;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user!;
    _nameCtrl   = TextEditingController(text: u.name);
    _emailCtrl  = TextEditingController(text: u.email);
    _hpCtrl     = TextEditingController(text: u.noHp ?? '');
    _alamatCtrl = TextEditingController(text: u.alamat ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _hpCtrl, _alamatCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await ApiService.updateProfile({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'no_hp': _hpCtrl.text.trim(),
        'alamat': _alamatCtrl.text.trim(),
      });
      // Refresh user info
      final fresh = await ApiService.getMe();
      if (fresh != null && mounted) {
        context.read<AuthProvider>().updateUser(fresh);
        setState(() { _success = 'Profil berhasil diperbarui!'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        title: Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: kBgCard, foregroundColor: kDark, elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder)),
      ),
      body: Form(key: _form, child: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpace),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_success != null)
            Container(margin: const EdgeInsets.only(bottom: kSpace), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: const Color(0xFF2E7D32))),
              child: Row(children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
                SizedBox(width: 8),
                Text(_success!, style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13)),
              ])),
          if (_error != null)
            Container(margin: const EdgeInsets.only(bottom: kSpace), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: const Color(0xFFDC2626))),
              child: Text(_error!, style: TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
          Container(padding: const EdgeInsets.all(kSpace), decoration: BoxDecoration(
            color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
            child: Column(children: [
              _Field(_nameCtrl, 'Nama Lengkap', Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null),
              SizedBox(height: 14),
              _Field(_emailCtrl, 'Email', Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  validator: (v) { if (v!.isEmpty) return 'Email wajib diisi'; if (!v.contains('@')) return 'Format email tidak valid'; return null; }),
              SizedBox(height: 14),
              _Field(_hpCtrl, 'No. HP / WhatsApp', Icons.phone_outlined, type: TextInputType.phone),
              SizedBox(height: 14),
              _Field(_alamatCtrl, 'Alamat Lengkap', Icons.location_on_outlined, maxLines: 3),
              SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Simpan Perubahan'))),
            ]),
          ),
        ]),
      )),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;
  const _Field(this.ctrl, this.label, this.icon,
      {this.type = TextInputType.text, this.maxLines = 1, this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines, validator: validator,
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: kPrimary, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide(color: kBorder2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide(color: kBorder2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide(color: kPrimary, width: 1.5)),
      filled: true, fillColor: kBgSoft,
      errorStyle: TextStyle(color: Color(0xFFDC2626), fontSize: 11),
    ));
}