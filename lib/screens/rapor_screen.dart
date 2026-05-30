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

class _RaporScreenState extends State<RaporScreen> {
  bool _loading = true;
  String? _error;
  List<RaporPagelaran> _rapors = [];
  RaporSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getRaporSaya(),
        ApiService.getRaporSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _rapors = results[0] as List<RaporPagelaran>;
        _summary = results[1] as RaporSummary?;
        _loading = false;
      });
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
        title: const Text('Rapor Pagelaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextMain,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const AppLoading(message: 'Memuat rapor...')
          : _error != null
              ? AppError(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  color: kPrimary,
                  onRefresh: _loadData,
                  child: _rapors.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            const Center(
                              child: Text('Belum ada data rapor pagelaran.', style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          slivers: [
                            if (_summary != null) SliverToBoxAdapter(child: _buildSummaryCard()),
                            SliverToBoxAdapter(child: const SizedBox(height: 16)),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildRaporCard(_rapors[index]),
                                childCount: _rapors.length,
                              ),
                            ),
                            SliverToBoxAdapter(child: const SizedBox(height: 32)),
                          ],
                        ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDark, kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('RATA-RATA NILAI AKHIR', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(_summary!.avgAkhir.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'PlayfairDisplay')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_summary!.predikatUmum, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Teknik', _summary!.avgTeknik),
              _buildSummaryItem('Hafalan', _summary!.avgHafalan),
              _buildSummaryItem('Ekspresi', _summary!.avgEkspresi),
              _buildSummaryItem('Penampilan', _summary!.avgPenampilan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildRaporCard(RaporPagelaran rapor) {
    Color gradeColor = rapor.nilaiAkhir >= 80 ? Colors.green : (rapor.nilaiAkhir >= 60 ? Colors.blue : Colors.red);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rapor.namaPagelaran, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(rapor.tanggalPagelaran, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rapor.nilaiAkhir.toStringAsFixed(1), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: gradeColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: gradeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(rapor.predikat, style: TextStyle(fontSize: 10, color: gradeColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.music_note, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text('Tari: ${rapor.tarianNama}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Kehadiran', '${rapor.nilaiKehadiran}%'),
          _buildDetailRow('Teknik', rapor.nilaiTeknik.toString()),
          _buildDetailRow('Hafalan', rapor.nilaiHafalan.toString()),
          _buildDetailRow('Ekspresi', rapor.nilaiEkspresi.toString()),
          _buildDetailRow('Penampilan', rapor.nilaiPenampilan.toString()),
          if (rapor.catatan != null && rapor.catatan!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan Pelatih:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('"${rapor.catatan!}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text('- ${rapor.pelatihNama}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
