import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        title: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpace),
        child: Container(
          padding: const EdgeInsets.all(kSpace),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder2),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password Lama', style: AppText.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _oldPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Masukkan password saat ini',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
                  ),
                  validator: (v) => v!.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: kSpace),
                Text('Password Baru', style: AppText.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Masukkan password baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
                  ),
                  validator: (v) => v!.length < 6 ? 'Password baru minimal 6 karakter' : null,
                ),
                const SizedBox(height: kSpace),
                Text('Konfirmasi Password Baru', style: AppText.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Ulangi password baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
                  ),
                  validator: (v) => v != _newPassCtrl.text ? 'Konfirmasi password tidak cocok' : null,
                ),
                const SizedBox(height: kSpaceLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Integrasi proses update password ke API
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password berhasil diperbarui!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}