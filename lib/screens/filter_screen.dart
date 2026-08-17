import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/filter.dart';
import '../widgets/primary_button.dart';

class FilterScreen extends StatefulWidget {
  final AtmFilter initial;
  const FilterScreen({super.key, required this.initial});
  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String _bank = widget.initial.bank;
  late List<String> _fasilitas = List.from(widget.initial.fasilitas);
  late double _jarak = widget.initial.jarakMaksKm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Filter Pencarian'), actions: [
      TextButton(onPressed: () => setState(() { _bank = 'Semua'; _fasilitas = []; _jarak = 5; }),
        child: const Text('Reset')),
    ]),
    body: Column(children: [
      Expanded(child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(children: [
          const Text('Pilih Bank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: AppConstants.filterBanks.map((b) {
            final act = b == _bank;
            return ChoiceChip(
              label: Text(b, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: act ? Colors.white : AppColors.textGrey)),
              selected: act, selectedColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              onSelected: (_) => setState(() => _bank = b));
          }).toList()),
          const SizedBox(height: 20),
          const Text('Fasilitas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...AppConstants.facilities.map((f) => CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: Text(f, style: const TextStyle(fontSize: 13)),
            value: _fasilitas.contains(f),
            onChanged: (v) => setState(() => v == true ? _fasilitas.add(f) : _fasilitas.remove(f)))),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Jarak Maksimal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_jarak.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          Slider(min: 1, max: 10, divisions: 9, value: _jarak, activeColor: AppColors.primary,
            label: '${_jarak.toStringAsFixed(0)} km', onChanged: (v) => setState(() => _jarak = v)),
        ]))),
      Padding(padding: const EdgeInsets.all(20),
        child: PrimaryButton(label: 'Terapkan Filter', onPressed: () =>
          Navigator.pop(context, AtmFilter(bank: _bank, fasilitas: _fasilitas, jarakMaksKm: _jarak)))),
    ]));
  }
}