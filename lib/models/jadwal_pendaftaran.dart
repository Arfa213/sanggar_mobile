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
  final int    tarianId, jadwalId;
  final String tarianNama;
  final String hari, hariSingkat, jamMulai, jamSelesai, tempat;
  final String status;
  final String tanggalDaftar;

  Pendaftaran({
    required this.id, required this.tarianId, required this.jadwalId,
    required this.tarianNama, required this.hari, required this.hariSingkat,
    required this.jamMulai, required this.jamSelesai, required this.tempat,
    required this.status, required this.tanggalDaftar,
  });

  factory Pendaftaran.fromJson(Map<String, dynamic> j) {
    final tarian = j['tarian'] as Map<String, dynamic>? ?? {};
    final jadwal = j['jadwal'] as Map<String, dynamic>? ?? {};
    final hari   = jadwal['hari'] as String? ?? '';
    return Pendaftaran(
      id:           j['id'] as int,
      tarianId:     j['tarian_id'] as int,
      jadwalId:     j['jadwal_id'] as int,
      tarianNama:   tarian['nama'] ?? '',
      hari:         hari,
      hariSingkat:  hari.isNotEmpty ? hari.substring(0, 3).toUpperCase() : '',
      jamMulai:     jadwal['jam_mulai']   ?? '',
      jamSelesai:   jadwal['jam_selesai'] ?? '',
      tempat:       jadwal['tempat']      ?? '',
      status:       j['status']           ?? 'aktif',
      tanggalDaftar: j['tanggal_daftar']  ?? '',
    );
  }
}