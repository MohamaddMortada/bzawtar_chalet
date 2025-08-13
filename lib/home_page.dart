import 'dart:convert';
import 'package:bzawtar_chalet/add_reservation.dart';
import 'package:bzawtar_chalet/reservation_detail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

// -------------------- Constants --------------------
const Color kPrimaryColor = Color.fromARGB(255, 0, 107, 92); // main teal
const Color kSecondaryColor = Color.fromARGB(184, 0, 150, 136); // slightly darker teal for accents
const Color kCardColor = Color.fromARGB(255, 0, 107, 92); // day card
const Color kBackgroundColor = Color(0xFFE0F2F1); // light background
const Color kTextColor = Colors.white; // main text color for cards
const Color kInactiveTextColor = Colors.white70; // secondary text
const double kCardRadius = 12.0;

enum CalendarView { weekly, monthly }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarView _currentView = CalendarView.monthly;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _reservations = [];

  late PageController _pageController;
  int _currentWeekPage = 5000;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _pageController = PageController(initialPage: _currentWeekPage);
  }

  Future<void> _loadReservations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('reservations');
    if (data != null) {
      setState(() {
        _reservations = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  List<Map<String, dynamic>> _getReservationsForDay(DateTime day) {
    var list = _reservations.where((res) {
      DateTime resDate = DateTime.parse(res["date"]);
      return resDate.year == day.year &&
          resDate.month == day.month &&
          resDate.day == day.day;
    }).toList();

    list.sort((a, b) {
      String chaletA = a["chalet"] ?? "B";
      String chaletB = b["chalet"] ?? "B";
      return chaletA.compareTo(chaletB);
    });

    return list;
  }

  DateTime _startOfWeek(DateTime day) =>
      day.subtract(Duration(days: day.weekday - 1));

  List<DateTime> _getWeekDays(DateTime day) {
    DateTime startOfWeek = _startOfWeek(day);
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  Widget _buildWeeklyViewPage(DateTime referenceDay) {
    List<DateTime> weekDays = _getWeekDays(referenceDay);

    // Weekly total
    double weekTotal = 0;
    for (var day in weekDays) {
      var dayReservations = _getReservationsForDay(day);
      for (var r in dayReservations) weekTotal += (r["price"] ?? 0);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly total card
        Card(
          color: kPrimaryColor,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total This Week",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kBackgroundColor)),
                Text("\$${weekTotal.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kBackgroundColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Days
        ...weekDays.map((day) {
          var dayReservations = _getReservationsForDay(day);
          return GestureDetector(
            onTap: () async {
              if (dayReservations.isEmpty) {
                bool? added = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddReservationPage(selectedDate: day)),
                );
                if (added == true) _loadReservations();
              }
            },
            child: Card(
              color: kCardColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][day.weekday-1]} - ${day.day}/${day.month}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kTextColor),
                    ),
                    const SizedBox(height: 8),
                    ...dayReservations.map((r) {
                      return GestureDetector(
                        onTap: () async {
                          bool? updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ReservationDetailPage(reservation: r)),
                          );
                          if (updated == true) _loadReservations();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              r["avatar"] != null && r["avatar"] != ""
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(r["avatar"]))
                                  : CircleAvatar(
                                      backgroundColor: kSecondaryColor,
                                      child: Icon(Icons.event, color: kBackgroundColor),
                                    ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${r["chalet"]} - ${r["title"]}",
                                        style: TextStyle(
                                            color: kTextColor,
                                            fontWeight: FontWeight.bold)),
                                    Text("${r["start"]} - ${r["end"]}",
                                        style: TextStyle(
                                            color: kInactiveTextColor,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text("\$${r["price"]}",
                                  style: TextStyle(
                                      color: kTextColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (dayReservations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          "No reservations",
                          style: TextStyle(color: kInactiveTextColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWeeklyView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          int delta = index - _currentWeekPage;
          _selectedDay = _selectedDay.add(Duration(days: delta * 7));
          _currentWeekPage = index;
        });
      },
      itemBuilder: (context, index) {
        int delta = index - _currentWeekPage;
        DateTime referenceDay = _selectedDay.add(Duration(days: delta * 7));
        return _buildWeeklyViewPage(referenceDay);
      },
    );
  }

  Widget _buildMonthlyView() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: kSecondaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: kPrimaryColor,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: kPrimaryColor),
        weekendTextStyle: TextStyle(color: kPrimaryColor),
      ),
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) async {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _currentView = CalendarView.weekly;
        });

        bool? added = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AddReservationPage(selectedDate: selectedDay)),
        );
        if (added == true) _loadReservations();
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          var dayReservations = _getReservationsForDay(date);
          if (dayReservations.isNotEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: dayReservations.take(3).map((r) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      "${r["chalet"]} - ${r["title"]}",
                      style: TextStyle(color: kBackgroundColor, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarView.weekly:
        return _buildWeeklyView();
      case CalendarView.monthly:
        return _buildMonthlyView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("Chalet Schedule"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                const Text("View: ",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 10),
                DropdownButton<CalendarView>(
                  value: _currentView,
                  dropdownColor: kPrimaryColor,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: CalendarView.weekly,
                      child: Text("Weekly"),
                    ),
                    DropdownMenuItem(
                      value: CalendarView.monthly,
                      child: Text("Monthly"),
                    ),
                  ],
                  onChanged: (view) {
                    if (view != null) {
                      setState(() {
                        _currentView = view;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildCurrentView(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () async {
          bool? added = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddReservationPage(
                      selectedDate: _selectedDay,
                    )),
          );
          if (added == true) _loadReservations();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
