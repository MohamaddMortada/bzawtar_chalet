import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -------------------- Constants --------------------
const Color kPrimaryColor = Color.fromARGB(255, 0, 107, 92);
const Color kSecondaryColor = Color.fromARGB(184, 0, 150, 136);
const Color kCardColor = Color.fromARGB(255, 0, 107, 92);
const Color kBackgroundColor = Color(0xFFE0F2F1);
const Color kTextColor = Colors.white;
const Color kInactiveTextColor = Colors.white70;
const double kCardRadius = 12.0;

class ReservationDetailPage extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _chalet = "A";

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.tryParse(widget.reservation["date"]) ?? DateTime.now();
    _startTime = _timeFromString(widget.reservation["start"]);
    _endTime = _timeFromString(widget.reservation["end"]);
    _titleController = TextEditingController(text: widget.reservation["title"]);
    _priceController =
        TextEditingController(text: widget.reservation["price"].toString());
    _chalet = widget.reservation["chalet"] == "B" ? "B" : "A";
  }

  // Robust parsing for HH:mm
  TimeOfDay _timeFromString(String timeStr) {
    try {
      final parts = timeStr.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0].split(".")[0].trim()) ?? 0;
        int minute = int.tryParse(parts[1].split(".")[0].trim()) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 0, minute: 0);
  }

  String _formatTime(TimeOfDay t) =>
      t.hour.toString().padLeft(2, '0') + ':' + t.minute.toString().padLeft(2, '0');

  Future<void> _pickStartTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: kPrimaryColor,
                onPrimary: Colors.white,
                onSurface: kPrimaryColor,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              ),
            ),
            child: child!,
          );
        });
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveReservation() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('reservations');
    List<Map<String, dynamic>> reservations =
        data != null ? List<Map<String, dynamic>>.from(jsonDecode(data)) : [];

    int index = reservations.indexWhere(
        (r) => r["date"] == widget.reservation["date"] &&
               r["start"] == widget.reservation["start"] &&
               r["title"] == widget.reservation["title"]);

    if (index != -1) {
      reservations[index] = {
        "date": _selectedDate.toIso8601String(),
        "start": _formatTime(_startTime),
        "end": _formatTime(_endTime),
        "price": double.tryParse(_priceController.text) ?? 0,
        "title": _titleController.text,
        "chalet": _chalet,
        "avatar": widget.reservation["avatar"] ?? ""
      };
      await prefs.setString('reservations', jsonEncode(reservations));
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteReservation() async {
    bool confirm = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Delete Reservation"),
              content: const Text("Are you sure you want to delete this reservation?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete", style: TextStyle(color: Colors.red))),
              ],
            )) ?? false;

    if (!confirm) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('reservations');
    List<Map<String, dynamic>> reservations =
        data != null ? List<Map<String, dynamic>>.from(jsonDecode(data)) : [];

    reservations.removeWhere(
        (r) => r["date"] == widget.reservation["date"] &&
               r["start"] == widget.reservation["start"] &&
               r["title"] == widget.reservation["title"]);

    await prefs.setString('reservations', jsonEncode(reservations));
    Navigator.pop(context, true);
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Reservation Details"),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              child: ListTile(
                title: Text(
                  "Date: ${_selectedDate.toLocal()}".split(' ')[0],
                  style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  color: kBackgroundColor,
                  onPressed: _pickDate,
                ),
              ),
            ),
            _buildCard(
              child: ListTile(
                title: Text(
                  "Start Time: ${_formatTime(_startTime)}",
                  style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  color: kBackgroundColor,
                  onPressed: _pickStartTime,
                ),
              ),
            ),
            _buildCard(
              child: ListTile(
                title: Text(
                  "End Time: ${_formatTime(_endTime)}",
                  style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time_filled),
                  color: kBackgroundColor,
                  onPressed: _pickEndTime,
                ),
              ),
            ),
            _buildCard(
              child: Row(
                children: [
                  const Text("Chalet: ", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("A"),
                    selected: _chalet == "A",
                    selectedColor: kPrimaryColor,
                    backgroundColor: kSecondaryColor.withOpacity(0.3),
                    labelStyle: TextStyle(color: _chalet == "A" ? kBackgroundColor : kTextColor),
                    onSelected: (val) => setState(() => _chalet = "A"),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("B"),
                    selected: _chalet == "B",
                    selectedColor: kPrimaryColor,
                    backgroundColor: kSecondaryColor.withOpacity(0.3),
                    labelStyle: TextStyle(color: _chalet == "B" ? kBackgroundColor : kTextColor),
                    onSelected: (val) => setState(() => _chalet = "B"),
                  ),
                ],
              ),
            ),
            _buildCard(
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: const TextStyle(color: kInactiveTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                  ),
                  filled: true,
                  fillColor: kSecondaryColor.withOpacity(0.2),
                ),
              ),
            ),
            _buildCard(
              child: TextField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: const TextStyle(color: kInactiveTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                  ),
                  filled: true,
                  fillColor: kSecondaryColor.withOpacity(0.2),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _deleteReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
                ),
                child: const Text(
                  "Delete Reservation",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
