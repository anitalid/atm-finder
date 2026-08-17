import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../models/atm.dart';
import '../models/filter.dart';
import '../services/atm_service.dart';
import '../services/history_service.dart';
import '../widgets/atm_list_item.dart';
import 'detail_screen.dart';
import 'filter_screen.dart';

class ResultsScreen extends StatefulWidget {
  final LatLng user;
  final AtmFilter filter;
  final String query;
  const ResultsScreen({super.key, required this.user, required this.filter, this.query = ''});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _service = AtmService();
  late AtmFilter _filter = widget.filter;
  late Future<List<Atm>> _atmsFuture;
  Future<List<AtmResult>>? _rankedFuture;

  @override
  void initState() {
    super.initState();
    _atmsFuture = _service.getAllAtms();
    HistoryService().addHistory(widget.query.isEmpty ? 'Pencarian (${_filter.bank})' : widget.query, _filter.bank);
  }

  Future<void> _openFilter() async {
    final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => FilterScreen(initial: _filter)));
    if (r != null) {
      setState(() {
        _filter = r as AtmFilter;
        _rankedFuture = null; // paksa hitung ulang skor dengan filter baru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Hasil Pencarian'), actions: [
      IconButton(onPressed: _openFilter, icon: const Icon(Icons.tune_rounded, color: AppColors.primary)),
    ]),
    body: FutureBuilder<List<Atm>>(future: _atmsFuture, builder: (ctx, atmSnap) {
      if (!atmSnap.hasData) return const Center(child: CircularProgressIndicator());
      _rankedFuture ??= _service.rankAtms(atms: atmSnap.data!, user: widget.user, filter: _filter, query: widget.query);
      return FutureBuilder<List<AtmResult>>(future: _rankedFuture, builder: (ctx, rankSnap) {
        if (!rankSnap.hasData) return const Center(child: CircularProgressIndicator());
        final results = rankSnap.data!;
        if (results.isEmpty) return const Center(child: Text('ATM tidak ditemukan', style: TextStyle(color: AppColors.textGrey)));
        return ListView.separated(padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: results.length,
          itemBuilder: (_, i) => AtmListItem(index: i, result: results[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(atm: results[i].atm, user: widget.user)))));
      });
    }));
  }
}