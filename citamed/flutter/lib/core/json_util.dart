/// Conversiones tolerantes: PHP/MySQL a veces entrega números como texto.
int aInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
double aDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
bool aBool(dynamic v) => v == true || v == 1 || v == '1';
