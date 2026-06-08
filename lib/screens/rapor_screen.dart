import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<RaporPagelaran> _rapors = [];
  RaporSummary? _summary;
  StatistikKehadiran? _statistikBulanIni;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getRaporSaya(),
        ApiService.getRaporSummary(),
        ApiService.getStatistikKehadiran(),
      ]);
      if (!mounted) return;
      setState(() {
        _rapors        = results[0] as List<RaporPagelaran>;
        _summary       = results[1] as RaporSummary?;
        _statistikBulanIni = results[2] as StatistikKehadiran;
        _loading       = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
        title: const Text(
          'Rapor Pagelaran',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: kBorder2),
        ),
      ),
      body: _loading
          ? const AppLoading(message: 'Memuat rapor...')
          : _error != null
              ? AppError(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  color: kPrimary,
                  onRefresh: _loadData,
                  child: _rapors.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          slivers: [
                            if (_summary != null)
                              SliverToBoxAdapter(child: _buildSummaryCard()),
                            if (_statistikBulanIni != null)
                              SliverToBoxAdapter(child: _buildKehadiranBulanIni()),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.description_rounded, color: kPrimary, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'RIWAYAT RAPOR PAGELARAN',
                                      style: TextStyle(
                                        color: kText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: kPrimaryPale,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_rapors.length} Pagelaran',
                                        style: TextStyle(
                                          color: kPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _animCtrl,
                                    curve: Interval(
                                      (index * 0.1).clamp(0.0, 0.8),
                                      ((index * 0.1) + 0.4).clamp(0.0, 1.0),
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: _buildRaporCard(_rapors[index]),
                                ),
                                childCount: _rapors.length,
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 40)),
                          ],
                        ),
                ),
    );
  }

  // ── SUMMARY CARD ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final s = _summary!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDark, kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RATA-RATA NILAI AKHIR',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.avgAkhir.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              fontFamily: 'PlayfairDisplay',
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              s.predikatUmum,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Grid 4 nilai
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Teknik', s.avgTeknik, Icons.architecture_rounded),
              _buildSummaryItem('Hafalan', s.avgHafalan, Icons.psychology_rounded),
              _buildSummaryItem('Ekspresi', s.avgEkspresi, Icons.face_retouching_natural_rounded),
              _buildSummaryItem('Penampilan', s.avgPenampilan, Icons.star_rounded),
            ],
          ),
          const SizedBox(height: 20),
          // Bar kehadiran rata-rata
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📊 Rata-rata Kehadiran',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${s.avgKehadiran.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.avgKehadiran / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      s.avgKehadiran >= 80
                          ? const Color(0xFF4CAF50)
                          : s.avgKehadiran >= 60
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dihitung dari rekap hadir & alpa seluruh latihan',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── KEHADIRAN BULAN INI ──────────────────────────────────────
  Widget _buildKehadiranBulanIni() {
    final s = _statistikBulanIni!;
    final bulanLabel = s.bulan.isNotEmpty
        ? _formatBulanTahun(s.bulan)
        : 'Bulan Ini';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'KEHADIRAN $bulanLabel'.toUpperCase(),
                style: TextStyle(
                  color: kText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(
                icon: Icons.check_circle_rounded,
                label: 'Hadir',
                value: s.hadir,
                color: const Color(0xFF2E7D32),
                bg: const Color(0xFFE8F5E9),
              ),
              const SizedBox(width: 10),
              _buildStatBadge(
                icon: Icons.cancel_rounded,
                label: 'Alpa',
                value: s.alpa,
                color: const Color(0xFFDC2626),
                bg: const Color(0xFFFEF2F2),
              ),
              const SizedBox(width: 10),
              _buildStatBadge(
                icon: Icons.info_rounded,
                label: 'Izin',
                value: s.izin,
                color: const Color(0xFFE65100),
                bg: const Color(0xFFFFF3E0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar kehadiran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tingkat Kehadiran',
                style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '${s.persenHadir}%',
                style: TextStyle(
                  color: s.persenHadir >= 80
                      ? const Color(0xFF2E7D32)
                      : s.persenHadir >= 60
                          ? const Color(0xFFE65100)
                          : const Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (s.persenHadir / 100).clamp(0.0, 1.0),
              backgroundColor: kBgSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                s.persenHadir >= 80
                    ? const Color(0xFF4CAF50)
                    : s.persenHadir >= 60
                        ? Colors.orangeAccent
                        : Colors.redAccent,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: kBgSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: kMuted, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Data alpa dicatat otomatis jika kamu tidak scan QR setelah jadwal selesai',
                    style: TextStyle(color: kMuted, fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RAPOR CARD ───────────────────────────────────────────────
  Widget _buildRaporCard(RaporPagelaran rapor) {
    final gradeColor = rapor.nilaiAkhir >= 80
        ? const Color(0xFF2E7D32)
        : rapor.nilaiAkhir >= 60
            ? const Color(0xFF1565C0)
            : const Color(0xFFDC2626);

    final attendanceColor = rapor.nilaiKehadiran >= 80
        ? const Color(0xFF2E7D32)
        : rapor.nilaiKehadiran >= 60
            ? const Color(0xFFE65100)
            : const Color(0xFFDC2626);

    final attendanceBg = rapor.nilaiKehadiran >= 80
        ? const Color(0xFFE8F5E9)
        : rapor.nilaiKehadiran >= 60
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFFEF2F2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBgSoft, kBgCard],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rapor.namaPagelaran,
                        style: TextStyle(
                          color: kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: kMuted),
                          const SizedBox(width: 4),
                          Text(
                            rapor.tanggalPagelaran,
                            style: TextStyle(fontSize: 11, color: kMuted),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.person_rounded, size: 11, color: kMuted),
                          const SizedBox(width: 4),
                          Text(
                            rapor.pelatihNama,
                            style: TextStyle(fontSize: 11, color: kMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nilai akhir + predikat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rapor.nilaiAkhir.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rapor.predikat,
                        style: TextStyle(
                          fontSize: 10,
                          color: gradeColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rapor.lulus
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rapor.lulus ? '✓ Lulus' : '✗ Tidak Lulus',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: rapor.lulus
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: kBorder2),

          // ── Detail nilai ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note_rounded, size: 14, color: kPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rapor.tarianNama,
                        style: TextStyle(
                          color: kText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Kehadiran dengan progress bar ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: attendanceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: attendanceColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                rapor.nilaiKehadiran >= 80
                                    ? Icons.check_circle_rounded
                                    : rapor.nilaiKehadiran >= 60
                                        ? Icons.warning_rounded
                                        : Icons.cancel_rounded,
                                color: attendanceColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Nilai Kehadiran',
                                style: TextStyle(
                                  color: attendanceColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${rapor.nilaiKehadiran.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: attendanceColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (rapor.nilaiKehadiran / 100).clamp(0.0, 1.0),
                          backgroundColor: attendanceColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(attendanceColor),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rapor.nilaiKehadiran >= 80
                            ? 'Kehadiran sangat baik 👏'
                            : rapor.nilaiKehadiran >= 60
                                ? 'Perlu ditingkatkan ⚠️'
                                : 'Kehadiran kurang — berdampak ke nilai akhir ❗',
                        style: TextStyle(
                          color: attendanceColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Grid nilai teknik, hafalan, ekspresi, penampilan ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.8,
                  children: [
                    _buildNilaiTile('Teknik', rapor.nilaiTeknik, Icons.architecture_rounded),
                    _buildNilaiTile('Hafalan', rapor.nilaiHafalan, Icons.psychology_rounded),
                    _buildNilaiTile('Ekspresi', rapor.nilaiEkspresi, Icons.face_retouching_natural_rounded),
                    _buildNilaiTile('Penampilan', rapor.nilaiPenampilan, Icons.star_rounded),
                  ],
                ),

                // ── Catatan pelatih ──
                if (rapor.catatan != null && rapor.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBgSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment_rounded, color: kPrimary, size: 13),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan Pelatih',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"${rapor.catatan!}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: kText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '— ${rapor.pelatihNama}',
                          style: TextStyle(fontSize: 10, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiTile(String label, int nilai, IconData icon) {
    final color = nilai >= 80
        ? const Color(0xFF2E7D32)
        : nilai >= 60
            ? const Color(0xFF1565C0)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(color: kMuted, fontSize: 9, fontWeight: FontWeight.w700),
              ),
              Text(
                '$nilai',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper format bulan tanpa locale (aman tanpa initializeDateFormatting)
  String _formatBulanTahun(String bulanStr) {
    const namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    try {
      final parts = bulanStr.split('-');
      final tahun = parts[0];
      final bln = int.tryParse(parts[1]) ?? 0;
      return '${namaBulan[bln]} $tahun';
    } catch (_) {
      return bulanStr;
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
                child: Icon(Icons.description_outlined, color: kPrimary, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum Ada Rapor',
                style: TextStyle(
                  color: kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Rapor pagelaran akan muncul setelah pelatih memasukkan nilai ujian.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
