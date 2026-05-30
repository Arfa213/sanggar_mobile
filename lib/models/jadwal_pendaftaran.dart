// lib/models/jadwal_pendaftaran.dart
// Tambahkan file ini di lib/models/

class JadwalLatihan {
  final int id;
  final String hari, jamMulai, jamSelesai, kelas, tempat;
  final bool aktif;

  JadwalLatihan({
    required this.id, required this.hari,
    required this.jamMulai, required this.jamSelesai,
    required this.kelas, required this.tempat,
    required this.aktif,
  });

  factory JadwalLatihan.fromJson(Map<String, dynamic> j) => JadwalLatihan(
    id:         j['id'] as int,
    hari:       j['hari']        ?? '',
    jamMulai:   j['jam_mulai']   ?? '',
    jamSelesai: j['jam_selesai'] ?? '',
    kelas:      j['kelas']       ?? '',
    tempat:     j['tempat']      ?? '',
    aktif:      j['aktif'] == true || j['aktif'] == 1,
  );
}

class Pendaftaran {
  final int    id;
  final int?   tarianId, jadwalId;
  final String tarianNama;
  final String hari, hariSingkat, jamMulai, jamSelesai, tempat;
  final String status;
  final String tanggalDaftar;

  Pendaftaran({
    required this.id, this.tarianId, this.jadwalId,
    required this.tarianNama, required this.hari, required this.hariSingkat,
    required this.jamMulai, required this.jamSelesai, required this.tempat,
    required this.status, required this.tanggalDaftar,
  });

  factory Pendaftaran.fromJson(Map<String, dynamic> j) {
    final tarian = j['tarian'] as Map<String, dynamic>? ?? {};
    final jadwal = j['jadwal'] as Map<String, dynamic>? ?? {};
    
    // Fallback jika jadwal kosong (untuk private khusus / anggota sementara)
    String hari = jadwal['hari'] as String? ?? '';
    String jamMulai = jadwal['jam_mulai'] as String? ?? '';
    String jamSelesai = jadwal['jam_selesai'] as String? ?? '';
    String tempat = jadwal['tempat'] as String? ?? '';

    String hariSingkat = '';
    if (j['jadwal_id'] == null) {
      final tgl = j['tanggal_latihan'] as String? ?? '';
      hari = tgl;
      jamMulai = j['jam_latihan'] ?? '';
      jamSelesai = '';
      tempat = 'Aula Sanggar';
      
      if (tgl.contains('-')) {
        final parts = tgl.split('-');
        if (parts.length >= 3) {
          final day = parts[2];
          final monthInt = int.tryParse(parts[1]) ?? 0;
          final months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGS', 'SEP', 'OKT', 'NOV', 'DES'];
          final monthStr = monthInt > 0 && monthInt <= 12 ? months[monthInt] : 'TGL';
          hariSingkat = '$day\n$monthStr';
        }
      }
    }

    if (hariSingkat.isEmpty) {
      hariSingkat = hari.length >= 3 ? hari.substring(0, 3).toUpperCase() : hari.toUpperCase();
    }

    return Pendaftaran(
      id:           j['id'] as int,
      tarianId:     j['tarian_id'] as int?,
      jadwalId:     j['jadwal_id'] as int?,
      tarianNama:   tarian['nama'] ?? j['catatan'] ?? 'Latihan Mandiri',
      hari:         hari,
      hariSingkat:  hariSingkat,
      jamMulai:     jamMulai,
      jamSelesai:   jamSelesai,
      tempat:       tempat,
      status:       j['status']           ?? 'aktif',
      tanggalDaftar: j['tanggal_daftar']  ?? '',
    );
  }
}