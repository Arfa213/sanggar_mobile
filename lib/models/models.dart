// lib/models/models.dart
export 'rapor.dart';
class SanggarProfile {
  final String namaSanggar, tagline, sejarah, visi;
  final List<String> misi;
  final String? tahunBerdiri, alamat, noHp, email, instagram, fotoProfil;
  final int jumlahAnggota, jumlahPenghargaan, jumlahEvent;

  SanggarProfile({required this.namaSanggar, required this.tagline,
    required this.sejarah, required this.visi, required this.misi,
    this.tahunBerdiri, this.alamat, this.noHp, this.email,
    this.instagram, this.fotoProfil,
    required this.jumlahAnggota, required this.jumlahPenghargaan,
    required this.jumlahEvent});

  factory SanggarProfile.fromJson(Map<String, dynamic> j) => SanggarProfile(
    namaSanggar:       j['nama_sanggar']        ?? 'Sanggar Mulya Bhakti',
    tagline:           j['tagline']              ?? '',
    sejarah:           j['sejarah']              ?? '',
    visi:              j['visi']                 ?? '',
    misi:              List<String>.from(j['misi'] ?? []),
    tahunBerdiri:      j['tahun_berdiri'],
    alamat:            j['alamat'],
    noHp:              j['no_hp'],
    email:             j['email'],
    instagram:         j['instagram'],
    fotoProfil:        j['foto_profil'],
    jumlahAnggota:     (j['jumlah_anggota']      ?? 0) as int,
    jumlahPenghargaan: (j['jumlah_penghargaan']  ?? 0) as int,
    jumlahEvent:       (j['jumlah_event']        ?? 0) as int,
  );
}

class Pelatih {
  final int id;
  final String nama, jabatan;
  final String? spesialisasi, pengalaman, bio, foto;
  Pelatih({required this.id, required this.nama, required this.jabatan,
    this.spesialisasi, this.pengalaman, this.bio, this.foto});
  factory Pelatih.fromJson(Map<String, dynamic> j) => Pelatih(
    id: j['id'] as int, nama: j['nama'] ?? '', jabatan: j['jabatan'] ?? '',
    spesialisasi: j['spesialisasi'], pengalaman: j['pengalaman'],
    bio: j['bio'], foto: j['foto']);
}

class Event {
  final int id;
  final String nama, lokasi, tanggal, kategori, level, status;
  final String? hasil, deskripsi, foto;
  final List<String> penghargaan;
  final int? jumlahPenonton;
  final bool unggulan;
  
  // Kolaborasi (Midhang Sore)
  final String? namaPengaju, fotoPengaju, sinopsisLink;

  Event({required this.id, required this.nama, required this.lokasi,
    required this.tanggal, required this.kategori, required this.level,
    required this.status, this.hasil, this.deskripsi, this.foto,
    required this.penghargaan, this.jumlahPenonton, required this.unggulan,
    this.namaPengaju, this.fotoPengaju, this.sinopsisLink});

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    id: j['id'] as int, nama: j['nama'] ?? '', lokasi: j['lokasi'] ?? '',
    tanggal: j['tanggal'] ?? '', kategori: j['kategori'] ?? 'umum',
    level: j['level'] ?? 'Lokal', status: j['status'] ?? 'selesai',
    hasil: j['hasil'], deskripsi: j['deskripsi'], foto: j['foto'],
    penghargaan: List<String>.from(j['penghargaan'] ?? []),
    jumlahPenonton: j['jumlah_penonton'],
    unggulan: j['unggulan'] == true || j['unggulan'] == 1,
    namaPengaju: j['nama_pengaju'],
    fotoPengaju: j['foto_pengaju'],
    sinopsisLink: j['sinopsis_link']);

  String get tahun => tanggal.length >= 4 ? tanggal.substring(0, 4) : '';
  String get tgl   => tanggal.length >= 10 ? tanggal.substring(8, 10) : '';
  String get bulanSingkat {
    const m = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    if (tanggal.length < 7) return '';
    final idx = int.tryParse(tanggal.substring(5, 7)) ?? 0;
    return m[idx];
  }
}

class Tarian {
  final int id;
  final String nama, asal, kategori, deskripsi;
  final String? fungsi, kostum, durasi, foto, videoUrl;
  final bool unggulan;

  Tarian({required this.id, required this.nama, required this.asal,
    required this.kategori, required this.deskripsi, this.fungsi,
    this.kostum, this.durasi, this.foto, this.videoUrl, required this.unggulan});

  factory Tarian.fromJson(Map<String, dynamic> j) => Tarian(
    id: j['id'] as int, nama: j['nama'] ?? '', asal: j['asal'] ?? '',
    kategori: j['kategori'] ?? 'hiburan', deskripsi: j['deskripsi'] ?? '',
    fungsi: j['fungsi'], kostum: j['kostum'], durasi: j['durasi'],
    foto: j['foto'], videoUrl: j['video_url'],
    unggulan: j['unggulan'] == true || j['unggulan'] == 1);
}

class Galeri {
  final int id;
  final String? judul;
  final String file, tipe, seksi, url;
  Galeri({required this.id, this.judul, required this.file,
    required this.tipe, required this.seksi, required this.url});
  factory Galeri.fromJson(Map<String, dynamic> j) => Galeri(
    id: j['id'] as int, judul: j['judul'], file: j['file'] ?? '',
    tipe: j['tipe'] ?? 'foto', seksi: j['seksi'] ?? '', url: j['url'] ?? '');
}

class UserModel {
  final int id;
  final String name, email, role, status;
  final String? alamat, noHp, foto, tipeAnggota, tglKadaluarsa, nomorInduk;
  String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.alamat,
    this.noHp,
    this.foto,
    this.tipeAnggota,
    this.tglKadaluarsa,
    this.nomorInduk,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:            j['id'] as int,
    name:          j['name'] ?? '',
    email:         j['email'] ?? '',
    role:          j['role'] ?? 'anggota',
    status:        j['status'] ?? 'aktif',
    alamat:        j['alamat'],
    noHp:          j['no_hp'],
    foto:          j['foto_profil'] ?? j['foto'],
    tipeAnggota:   j['tipe_anggota'] ?? 'anggota_tetap',
    tglKadaluarsa: j['tgl_kadaluarsa'],
    nomorInduk:    j['nomor_induk'],
    token:         j['token'],
  );

  bool get isAdmin      => role == 'admin' || role == 'administrator';
  bool get isPengunjung => tipeAnggota == 'pengunjung';
  String get firstName  => name.split(' ').first;
  String get initial    => name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

// ── KEHADIRAN ─────────────────────────────────────────────────
class JadwalSingkat {
  final String hari, jamMulai, jamSelesai, tempat;
  JadwalSingkat({required this.hari, required this.jamMulai,
    required this.jamSelesai, required this.tempat});
  factory JadwalSingkat.fromJson(Map<String, dynamic> j) => JadwalSingkat(
    hari:       j['hari'] ?? '',
    jamMulai:   j['jam_mulai'] ?? '',
    jamSelesai: j['jam_selesai'] ?? '',
    tempat:     j['tempat'] ?? '',
  );
}

class Kehadiran {
  final int id;
  final String tanggal, status;
  final String? keterangan;
  final String tarianNama;
  final JadwalSingkat? jadwal;

  Kehadiran({required this.id, required this.tanggal, required this.status,
    this.keterangan, required this.tarianNama, this.jadwal});

  factory Kehadiran.fromJson(Map<String, dynamic> j) => Kehadiran(
    id:         j['id'] as int,
    tanggal:    j['tanggal'] ?? '',
    status:     j['status'] ?? 'alpa',
    keterangan: j['keterangan'],
    tarianNama: (j['tarian'] as Map<String, dynamic>?)?['nama'] ?? '',
    jadwal:     j['jadwal'] != null
        ? JadwalSingkat.fromJson(j['jadwal'] as Map<String, dynamic>)
        : null,
  );

  String get tanggalFormatted {
    if (tanggal.length < 10) return tanggal;
    const bulan = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    final parts = tanggal.substring(0, 10).split('-');
    if (parts.length < 3) return tanggal;
    final bln = int.tryParse(parts[1]) ?? 0;
    return '${parts[2]} ${bulan[bln]} ${parts[0]}';
  }
}

class StatistikKehadiran {
  final String bulan;
  final int hadir, izin, alpa, total;
  final int persenHadir;

  StatistikKehadiran({required this.bulan, required this.hadir,
    required this.izin, required this.alpa, required this.total,
    required this.persenHadir});

  factory StatistikKehadiran.fromJson(Map<String, dynamic> j) {
    final d = j['data'] as Map<String, dynamic>? ?? j;
    return StatistikKehadiran(
      bulan:       d['bulan'] ?? '',
      hadir:       (d['hadir'] ?? 0) as int,
      izin:        (d['izin']  ?? 0) as int,
      alpa:        (d['alpa']  ?? 0) as int,
      total:       (d['total'] ?? 0) as int,
      persenHadir: (d['persen_hadir'] ?? 0) as int,
    );
  }
}

// ── PENDAFTARAN MEMBER ────────────────────────────────────────
class PendaftaranMember {
  final int id;
  final String tarianNama, tarianKategori;
  final String? tarianFoto;
  final JadwalSingkat jadwal;
  final String status, tanggalDaftar;

  PendaftaranMember({required this.id, required this.tarianNama,
    required this.tarianKategori, this.tarianFoto,
    required this.jadwal, required this.status, required this.tanggalDaftar});

  factory PendaftaranMember.fromJson(Map<String, dynamic> j) {
    final t = j['tarian'] as Map<String, dynamic>? ?? {};
    var jd = j['jadwal'] as Map<String, dynamic>? ?? {};
    
    if (j['jadwal_id'] == null) {
      jd = {
        'hari': j['tanggal_latihan'] ?? '',
        'jam_mulai': j['jam_latihan'] ?? '',
        'jam_selesai': '',
        'tempat': 'Aula Sanggar',
      };
    }
    
    return PendaftaranMember(
      id:             j['id'] as int,
      tarianNama:     t['nama'] ?? j['catatan'] ?? 'Latihan Mandiri',
      tarianKategori: t['kategori'] ?? 'Tradisional',
      tarianFoto:     t['foto'],
      jadwal:         JadwalSingkat.fromJson(jd),
      status:         j['status'] ?? 'aktif',
      tanggalDaftar:  j['tanggal_daftar'] ?? '',
    );
  }

  String get hariSingkat =>
      jadwal.hari.length >= 3 ? jadwal.hari.substring(0, 3).toUpperCase() : jadwal.hari.toUpperCase();
}