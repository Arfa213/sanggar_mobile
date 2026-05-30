// lib/models/rapor.dart

class RaporPagelaran {
  final int id;
  final int eventId;
  final String namaPagelaran;
  final String tanggalPagelaran;
  final String tarianNama;
  final String pelatihNama;
  final int nilaiTeknik;
  final int nilaiHafalan;
  final int nilaiEkspresi;
  final int nilaiPenampilan;
  final double nilaiKehadiran;
  final double nilaiAkhir;
  final String predikat;
  final bool lulus;
  final String? catatan;

  RaporPagelaran({
    required this.id,
    required this.eventId,
    required this.namaPagelaran,
    required this.tanggalPagelaran,
    required this.tarianNama,
    required this.pelatihNama,
    required this.nilaiTeknik,
    required this.nilaiHafalan,
    required this.nilaiEkspresi,
    required this.nilaiPenampilan,
    required this.nilaiKehadiran,
    required this.nilaiAkhir,
    required this.predikat,
    required this.lulus,
    this.catatan,
  });

  factory RaporPagelaran.fromJson(Map<String, dynamic> json) {
    return RaporPagelaran(
      id: json['id'],
      eventId: json['event_id'],
      namaPagelaran: json['event']['nama'] ?? '-',
      tanggalPagelaran: json['event']['tanggal'] ?? '-',
      tarianNama: json['tarian']['nama'] ?? '-',
      pelatihNama: json['pelatih']['name'] ?? 'Pelatih',
      nilaiTeknik: json['nilai_teknik'],
      nilaiHafalan: json['nilai_hafalan'],
      nilaiEkspresi: json['nilai_ekspresi'],
      nilaiPenampilan: json['nilai_penampilan'],
      nilaiKehadiran: double.parse(json['nilai_kehadiran'].toString()),
      nilaiAkhir: double.parse(json['nilai_akhir'].toString()),
      predikat: json['predikat'] ?? '-',
      lulus: json['lulus'] == 1 || json['lulus'] == true,
      catatan: json['catatan'],
    );
  }
}

class RaporSummary {
  final int totalPagelaran;
  final double avgTeknik;
  final double avgHafalan;
  final double avgEkspresi;
  final double avgPenampilan;
  final double avgKehadiran;
  final double avgAkhir;
  final String predikatUmum;

  RaporSummary({
    required this.totalPagelaran,
    required this.avgTeknik,
    required this.avgHafalan,
    required this.avgEkspresi,
    required this.avgPenampilan,
    required this.avgKehadiran,
    required this.avgAkhir,
    required this.predikatUmum,
  });

  factory RaporSummary.fromJson(Map<String, dynamic> json) {
    return RaporSummary(
      totalPagelaran: json['total_pagelaran'] ?? 0,
      avgTeknik: double.parse((json['avg_teknik'] ?? 0).toString()),
      avgHafalan: double.parse((json['avg_hafalan'] ?? 0).toString()),
      avgEkspresi: double.parse((json['avg_ekspresi'] ?? 0).toString()),
      avgPenampilan: double.parse((json['avg_penampilan'] ?? 0).toString()),
      avgKehadiran: double.parse((json['avg_kehadiran'] ?? 0).toString()),
      avgAkhir: double.parse((json['avg_akhir'] ?? 0).toString()),
      predikatUmum: json['predikat_umum'] ?? '-',
    );
  }
}
