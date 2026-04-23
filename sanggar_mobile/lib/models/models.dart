// lib/models/models.dart

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

  Event({required this.id, required this.nama, required this.lokasi,
    required this.tanggal, required this.kategori, required this.level,
    required this.status, this.hasil, this.deskripsi, this.foto,
    required this.penghargaan, this.jumlahPenonton, required this.unggulan});

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    id: j['id'] as int, nama: j['nama'] ?? '', lokasi: j['lokasi'] ?? '',
    tanggal: j['tanggal'] ?? '', kategori: j['kategori'] ?? 'pentas',
    level: j['level'] ?? 'Lokal', status: j['status'] ?? 'selesai',
    hasil: j['hasil'], deskripsi: j['deskripsi'], foto: j['foto'],
    penghargaan: List<String>.from(j['penghargaan'] ?? []),
    jumlahPenonton: j['jumlah_penonton'],
    unggulan: j['unggulan'] == true || j['unggulan'] == 1);

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
  final String? alamat, noHp;
  String? token;
  UserModel({required this.id, required this.name, required this.email,
    required this.role, required this.status, this.alamat, this.noHp, this.token});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as int, name: j['name'] ?? '', email: j['email'] ?? '',
    role: j['role'] ?? 'anggota', status: j['status'] ?? 'aktif',
    alamat: j['alamat'], noHp: j['no_hp'], token: j['token']);
  bool get isAdmin => role == 'admin';
}