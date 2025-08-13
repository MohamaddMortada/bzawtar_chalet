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

class AddReservationPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddReservationPage({super.key, this.selectedDate});

  @override
  State<AddReservationPage> createState() => _AddReservationPageState();
}

class _AddReservationPageState extends State<AddReservationPage> {
  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedChalet = "A";

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
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
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay(hour: 16, minute: 0));
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _saveReservation() async {
    if (_startTime == null || _endTime == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    final reservation = {
      "date": DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
          .toIso8601String(),
      "start": _startTime!.format(context),
      "end": _endTime!.format(context),
      "price": double.tryParse(_priceController.text) ?? 0,
      "title": _titleController.text.isEmpty ? "Reservation" : _titleController.text,
      "chalet": _selectedChalet,
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('reservations');
    List<Map<String, dynamic>> reservations =
        data != null ? List<Map<String, dynamic>>.from(jsonDecode(data)) : [];

    reservations.add(reservation);
    await prefs.setString('reservations', jsonEncode(reservations));

    Navigator.pop(context, true);
  }

  Widget _buildInputCard({required Widget child}) {
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
        title: const Text("Add Reservation"),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputCard(
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
            _buildInputCard(
              child: ListTile(
                title: Text(
                  "Start Time: ${_startTime != null ? _startTime!.format(context) : '--:--'}",
                  style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  color: kBackgroundColor,
                  onPressed: _pickStartTime,
                ),
              ),
            ),
            _buildInputCard(
              child: ListTile(
                title: Text(
                  "End Time: ${_endTime != null ? _endTime!.format(context) : '--:--'}",
                  style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time_filled),
                  color: kBackgroundColor,
                  onPressed: _pickEndTime,
                ),
              ),
            ),
            _buildInputCard(
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Title (optional)",
                  labelStyle: const TextStyle(color: kInactiveTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                  filled: true,
                  fillColor: kSecondaryColor.withOpacity(0.2),
                ),
              ),
            ),
            _buildInputCard(
              child: TextField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: const TextStyle(color: kInactiveTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                  filled: true,
                  fillColor: kSecondaryColor.withOpacity(0.2),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            _buildInputCard(
              child: Row(
                children: [
                  const Text("Chalet: ", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("A"),
                    selected: _selectedChalet == "A",
                    selectedColor: kPrimaryColor,
                    backgroundColor: kSecondaryColor.withOpacity(0.3),
                    labelStyle: TextStyle(color: _selectedChalet == "A" ? kBackgroundColor : kTextColor),
                    onSelected: (val) => setState(() => _selectedChalet = "A"),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("B"),
                    selected: _selectedChalet == "B",
                    selectedColor: kPrimaryColor,
                    backgroundColor: kSecondaryColor.withOpacity(0.3),
                    labelStyle: TextStyle(color: _selectedChalet == "B" ? kBackgroundColor : kTextColor),
                    onSelected: (val) => setState(() => _selectedChalet = "B"),
                  ),
                ],
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
                  "Save Reservation",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
