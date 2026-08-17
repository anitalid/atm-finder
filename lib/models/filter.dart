class AtmFilter {
  final String bank;
  final List<String> fasilitas;
  final double jarakMaksKm;

  const AtmFilter({this.bank = 'Semua', this.fasilitas = const [], this.jarakMaksKm = 5});

  AtmFilter copyWith({String? bank, List<String>? fasilitas, double? jarakMaksKm}) => AtmFilter(
    bank: bank ?? this.bank,
    fasilitas: fasilitas ?? this.fasilitas,
    jarakMaksKm: jarakMaksKm ?? this.jarakMaksKm,
  );
}