// pages/reservation_page.dart
import 'package:flutter/material.dart';
import '../models/user_session.dart';
import 'success_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/app_logger.dart';

class ReservationPage extends StatefulWidget {
  final String eventType;

  const ReservationPage({super.key, required this.eventType});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedFromTime;
  TimeOfDay? selectedToTime;
  bool _isSaving = false;
  List<DocumentImage> uploadedDocuments = [];
  final ImagePicker _picker = ImagePicker();

  // Store approved reservations for validation
  List<Map<String, dynamic>> approvedReservations = [];
  bool _isLoadingReservations = false;

  @override
  void initState() {
    super.initState();
    _loadApprovedReservations();
  }

  // Load all approved reservations for validation
  Future<void> _loadApprovedReservations() async {
    setState(() => _isLoadingReservations = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'approved')
          .get();

      approvedReservations = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'eventType': data['eventType'] ?? '',
          'date': (data['date'] as Timestamp).toDate(),
          'timeFrom': data['timeFrom'] ?? '',
          'timeTo': data['timeTo'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reservations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingReservations = false);
      }
    }
  }

  // Check if a date is available for booking
 // Check if a date is available for booking
  bool _isDateAvailable(DateTime date) {
    try {
      // Basic validation
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        return false;
      }

      final dateOnly = DateTime(date.year, date.month, date.day);
      final reservationsOnDate = approvedReservations.where((res) {
        try {
          final resDate = res['date'] as DateTime;
          final resDateOnly =
              DateTime(resDate.year, resDate.month, resDate.day);
          return resDateOnly.isAtSameMomentAs(dateOnly);
        } catch (e) {
          return false;
        }
      }).toList();

      // Wedding constraints
      if (widget.eventType.toLowerCase() == 'wedding') {
        // No weddings on Sunday (7)
        if (date.weekday == DateTime.sunday) {
          return false;
        }
        // Maximum 2 weddings per day
        final weddingsOnDate = reservationsOnDate
            .where((res) =>
                (res['eventType'] ?? '').toString().toLowerCase() == 'wedding')
            .length;
        if (weddingsOnDate >= 2) return false;
      }

      // Funeral constraint: No funerals on Monday (1) and Saturday (6)
      if (widget.eventType.toLowerCase() == 'funeral') {
        if (date.weekday == DateTime.monday ||
            date.weekday == DateTime.saturday) {
          return false;
        }
      }

      // General constraint: Maximum 2 events per day (regardless of type)
      if (reservationsOnDate.length >= 2) return false;

      // All other constraints passed
      return true;
    } catch (e) {
      // REPLACE THIS LINE:
      // debugPrint('Error in date validation: $e');
      
      // WITH THIS LINE:
      AppLogger.error('Error in date validation', e, StackTrace.current, 'RESERVATION');
      return true;
    }
  }

  // Get conflicting time slots for a specific date
  List<String> _getConflictingTimeSlots(DateTime date) {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final reservationsOnDate = approvedReservations.where((res) {
        try {
          final resDate = res['date'] as DateTime;
          final resDateOnly =
              DateTime(resDate.year, resDate.month, resDate.day);
          return resDateOnly.isAtSameMomentAs(dateOnly);
        } catch (e) {
          return false;
        }
      }).toList();

      return reservationsOnDate
          .map((res) => '${res['timeFrom'] ?? ''} - ${res['timeTo'] ?? ''}')
          .where((timeSlot) => timeSlot.trim() != ' - ')
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Check if selected time conflicts with existing bookings
  bool _isTimeSlotAvailable(
      DateTime date, TimeOfDay fromTime, TimeOfDay toTime) {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final reservationsOnDate = approvedReservations.where((res) {
        try {
          final resDate = res['date'] as DateTime;
          final resDateOnly =
              DateTime(resDate.year, resDate.month, resDate.day);
          return resDateOnly.isAtSameMomentAs(dateOnly);
        } catch (e) {
          return false;
        }
      }).toList();

      final selectedFromMinutes = fromTime.hour * 60 + fromTime.minute;
      final selectedToMinutes = toTime.hour * 60 + toTime.minute;

      for (final reservation in reservationsOnDate) {
        final existingFrom =
            _parseTimeString(reservation['timeFrom']?.toString() ?? '');
        final existingTo =
            _parseTimeString(reservation['timeTo']?.toString() ?? '');

        if (existingFrom != null && existingTo != null) {
          final existingFromMinutes =
              existingFrom.hour * 60 + existingFrom.minute;
          final existingToMinutes = existingTo.hour * 60 + existingTo.minute;

          // Check for time overlap
          bool hasOverlap = !(selectedToMinutes <= existingFromMinutes ||
              selectedFromMinutes >= existingToMinutes);

          if (hasOverlap) return false;
        }
      }
      return true;
    } catch (e) {
      return true; // Default to allowing if there's an error
    }
  }

  // Parse time string to TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      if (timeStr.isEmpty) return null;

      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minutePart = parts[1].split(' ')[0]; // Remove AM/PM if present
        final minute = int.parse(minutePart);

        // Handle AM/PM
        int finalHour = hour;
        if (timeStr.toLowerCase().contains('pm') && hour != 12) {
          finalHour += 12;
        } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
          finalHour = 0;
        }

        return TimeOfDay(hour: finalHour, minute: minute);
      }
    } catch (e) {
      // Handle parsing errors
    }
    return null;
  }

  // Document requirements based on event type
  Map<String, List<String>> getRequiredDocuments() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        return {
          'Required Documents': [
            'PSA Certified birth certificate',
            'CENOMAR (Certificate of No Marriage)',
            'Baptismal Certificate from parish',
            'Confirmation Certificate from parish'
          ]
        };
      case 'funeral':
        return {
          'Required Documents': ['Death certificate']
        };
      case 'baptism':
        return {
          'Required Documents': ['Parents\' Catholic marriage contract']
        };
      case 'house blessing':
        return {
          'Note': [
            'No formal documents required',
            'Contact priest from local parish to schedule'
          ]
        };
      default:
        return {
          'Documents': ['Upload any relevant documents']
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final requirements = getRequiredDocuments();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Reservation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingReservations
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.black,
                                Colors.grey,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getEventIcon(widget.eventType),
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Booking for',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      widget.eventType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Personal Information Section
                        _buildSectionHeader(
                            'Personal Information', Icons.person),
                        const SizedBox(height: 20),
                        _buildModernTextField('Name', nameController,
                            icon: Icons.person_outline, isRequired: true),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                            'Contact Number', contactController,
                            icon: Icons.phone_outlined,
                            isRequired: true,
                            isPhone: true),
                        const SizedBox(height: 30),

                        // Event Details Section
                        _buildSectionHeader('Event Details', Icons.event),
                        const SizedBox(height: 20),
                        _buildDateField(),
                        const SizedBox(height: 20),
                        _buildTimeField(),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                            'Additional Comments', commentsController,
                            icon: Icons.message_outlined, maxLines: 4),
                        const SizedBox(height: 30),

                        // Document Requirements Section
                        if (widget.eventType.toLowerCase() !=
                            'house blessing') ...[
                          _buildSectionHeader(
                              'Document Requirements', Icons.description),
                          const SizedBox(height: 15),
                          _buildRequirementsCard(requirements),
                          const SizedBox(height: 20),
                          _buildDocumentUploadSection(),
                          const SizedBox(height: 30),
                        ] else ...[
                          _buildSectionHeader('Note', Icons.info_outline),
                          const SizedBox(height: 15),
                          _buildRequirementsCard(requirements),
                          const SizedBox(height: 30),
                        ],

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Submit Reservation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'funeral':
        return Icons.local_florist;
      case 'baptism':
        return Icons.child_care;
      case 'house blessing':
        return Icons.home;
      default:
        return Icons.event;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    bool isRequired = false,
    bool isPhone = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          if (isPhone && value != null && value.isNotEmpty) {
            if (!RegExp(r'^\d{10,15}$')
                .hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
              return 'Please enter a valid phone number';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: icon != null ? Icon(icon, color: Colors.black) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon != null ? 12 : 20,
            vertical: maxLines > 1 ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: dateController,
        readOnly: true,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
        onTap: () async {
          final DateTime now = DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365)),
            // Remove selectableDayPredicate to prevent crashes
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null && mounted) {
            final messenger = ScaffoldMessenger.of(context);

            // Validate AFTER the user picks a date
            String? errorMessage;

            // Check wedding Sunday constraint
            if (widget.eventType.toLowerCase() == 'wedding' &&
                picked.weekday == DateTime.sunday) {
              errorMessage =
                  'Weddings cannot be booked on Sundays. Please select another date.';
            }

            // Check funeral Monday/Saturday constraint
            if (widget.eventType.toLowerCase() == 'funeral' &&
                (picked.weekday == DateTime.monday ||
                    picked.weekday == DateTime.saturday)) {
              errorMessage =
                  'Funerals cannot be booked on Mondays or Saturdays. Please select another date.';
            }

            // Check booking limit (only if reservations are loaded)
            if (errorMessage == null && !_isLoadingReservations) {
              try {
                final dateOnly =
                    DateTime(picked.year, picked.month, picked.day);
                int bookingsCount = 0;

                for (var reservation in approvedReservations) {
                  try {
                    final resDate = reservation['date'] as DateTime;
                    final resDateOnly =
                        DateTime(resDate.year, resDate.month, resDate.day);
                    if (resDateOnly.isAtSameMomentAs(dateOnly)) {
                      bookingsCount++;
                    }
                  } catch (e) {
                    continue;
                  }
                }

                if (bookingsCount >= 2) {
                  errorMessage =
                      'This date is fully booked. Please select another date.';
                }
              } catch (e) {
                // If validation fails, allow the date
              }
            }

            // Show error or accept the date
            if (errorMessage != null) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height - 150,
                    right: 20,
                    left: 20,
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              // Date is valid, accept it
              setState(() {
                selectedDate = picked;
                dateController.text =
                    "${picked.day}/${picked.month}/${picked.year}";
                // Clear time when date changes
                selectedFromTime = null;
                selectedToTime = null;
                timeController.clear();
              });
            }
          }
        },
        decoration: InputDecoration(
          labelText: 'Event Date',
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon:
              const Icon(Icons.calendar_today_outlined, color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: timeController,
        readOnly: true,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please select time';
          return null;
        },
        onTap: () async {
          if (selectedDate == null) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Please select a date first'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  right: 20,
                  left: 20,
                ),
              ),
            );
            return;
          }

          // Reload reservations to get the latest data
          await _loadApprovedReservations();

          if (!mounted) return;

          final scaffoldMessenger = ScaffoldMessenger.of(context);

          final fromPicked = await showTimePicker(
            context: context,
            initialTime:
                selectedFromTime ?? const TimeOfDay(hour: 7, minute: 0),
          );
          if (fromPicked == null) return;

          if (fromPicked.hour < 7 || fromPicked.hour > 17) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Time must be between 7:00 AM and 5:00 PM'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height - 150,
                    right: 20,
                    left: 20,
                  ),
                ),
              );
            }
            return;
          }

          if (!mounted) return;

          final toPicked = await showTimePicker(
            context: context,
            initialTime: selectedToTime ??
                TimeOfDay(hour: fromPicked.hour + 1, minute: fromPicked.minute),
          );
          if (toPicked == null || !mounted) return;

          if (toPicked.hour < 7 || toPicked.hour > 17) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Time must be between 7:00 AM and 5:00 PM'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  right: 20,
                  left: 20,
                ),
              ),
            );
            return;
          }

          final fromMinutes = fromPicked.hour * 60 + fromPicked.minute;
          final toMinutes = toPicked.hour * 60 + toPicked.minute;

          if (toMinutes <= fromMinutes) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('End time must be after start time'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  right: 20,
                  left: 20,
                ),
              ),
            );
            return;
          }

          // Check for time slot conflicts
          if (!_isTimeSlotAvailable(selectedDate!, fromPicked, toPicked)) {
            final conflictingSlots = _getConflictingTimeSlots(selectedDate!);
            String conflictMessage;

            if (conflictingSlots.isNotEmpty) {
              conflictMessage =
                  '${fromPicked.format(context)} - ${toPicked.format(context)} conflicts with existing bookings: ${conflictingSlots.join(', ')} are already reserved';
            } else {
              conflictMessage =
                  'Selected time slot ${fromPicked.format(context)} - ${toPicked.format(context)} is not available';
            }

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(conflictMessage),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  right: 20,
                  left: 20,
                ),
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }

          setState(() {
            selectedFromTime = fromPicked;
            selectedToTime = toPicked;
            timeController.text =
                '${fromPicked.format(context)} - ${toPicked.format(context)}';
          });

          // Show success message
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Time slot selected successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                right: 20,
                left: 20,
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
        decoration: InputDecoration(
          labelText: 'Time (From - To)',
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon:
              const Icon(Icons.access_time_outlined, color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRequirementsCard(Map<String, List<String>> requirements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent[300],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix: Remove unnecessary toList() from spread operator
          ...requirements.entries.expand((entry) => [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...entry.value.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              req,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ]),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildUploadButton('Camera', Icons.camera_alt,
                      () => _pickImage(ImageSource.camera)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUploadButton('Gallery', Icons.photo_library,
                      () => _pickImage(ImageSource.gallery)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (uploadedDocuments.isNotEmpty) _buildUploadedDocumentsList(),
      ],
    );
  }

  Widget _buildUploadButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedDocumentsList() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Documents (${uploadedDocuments.length})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ...uploadedDocuments.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    doc.type == 'camera' ? Icons.camera_alt : Icons.photo,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Uploaded via ${doc.type}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeDocument(index),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required to take photos'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndAddImage(image, source);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAndAddImage(XFile image, ImageSource source) async {
    AppLogger.imageProcessing('Starting image processing for: ${image.name}');

    try {
      // Read image bytes
      final bytes = await File(image.path).readAsBytes();
      AppLogger.imageProcessing('Read ${bytes.length} bytes from image file');

      // Decode and compress image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        AppLogger.error(
            'Failed to decode image: ${image.name}', null, null, 'IMAGE');
        return;
      }

      AppLogger.imageProcessing(
          'Original image size: ${originalImage.width}x${originalImage.height}');

      // Resize if too large (max 800px width)
      if (originalImage.width > 800) {
        originalImage = img.copyResize(originalImage, width: 800);
        AppLogger.imageProcessing(
            'Resized image to: ${originalImage.width}x${originalImage.height}');
      }

      // Encode as JPEG with compression
      final compressedBytes = img.encodeJpg(originalImage, quality: 70);
      AppLogger.imageProcessing(
          'Compressed image to ${compressedBytes.length} bytes');

      // Convert to base64
      final base64String = base64Encode(compressedBytes);

      // Check size (Firestore has 1MB limit per document)
      if (base64String.length > 500000) {
        AppLogger.warning(
            'Image too large after compression: ${base64String.length} characters',
            'IMAGE');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Please choose a smaller image.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final docImage = DocumentImage(
        name: 'Document_${DateTime.now().millisecondsSinceEpoch}',
        base64Data: base64String,
        type: source == ImageSource.camera ? 'camera' : 'gallery',
        uploadedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          uploadedDocuments.add(docImage);
        });

        AppLogger.imageProcessing(
            'Successfully added document: ${docImage.name}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error processing image: ${image.name}', e,
          StackTrace.current, 'IMAGE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error processing image: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      uploadedDocuments.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document removed'),
        backgroundColor: Colors.grey,
      ),
    );
  }

// pages/reservation_page.dart (Updated _saveReservation method)
// Replace the existing _saveReservation method with this updated version:

void _saveReservation() async {
  if (_formKey.currentState!.validate()) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;

    AppLogger.reservation('Starting reservation save process for ${widget.eventType}');

    // Check if documents are required and uploaded
    if (widget.eventType.toLowerCase() != 'house blessing' &&
        uploadedDocuments.isEmpty) {
      AppLogger.warning('No documents uploaded for ${widget.eventType} reservation', 'RESERVATION');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one required document'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Final validation before saving
    if (selectedDate != null && !_isDateAvailable(selectedDate!)) {
      AppLogger.warning('Selected date is no longer available: $selectedDate', 'RESERVATION');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Selected date is no longer available'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: 20,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final reservation = ReservationData(
      reservationId: '',
      userId: user!.uid,
      eventType: widget.eventType,
      name: nameController.text.trim(),
      email: user.email ?? '',
      contact: contactController.text.trim(),
      date: selectedDate!,
      timeFrom: selectedFromTime!.format(context),
      timeTo: selectedToTime!.format(context),
      comments: commentsController.text.trim(),
      status: "pending",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      documents: uploadedDocuments,
    );

    AppLogger.reservation('Reservation data prepared - Event: ${widget.eventType}, Date: $selectedDate, User: ${user.uid}');

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('reservations')
          .add(reservation.toMap());

      reservation.reservationId = docRef.id;
      UserSession.addReservation(reservation);

      AppLogger.reservation('Successfully saved reservation with ID: ${docRef.id}');

      if (mounted) {
        // Navigate to success page with reservation ID for payment flow
        navigator.push(
          MaterialPageRoute(
            builder: (context) => SuccessPage(
              eventType: widget.eventType,
              name: reservation.name,
              email: reservation.email,
              date: reservation.date,
              contact: reservation.contact,
              timeFrom: reservation.timeFrom,
              timeTo: reservation.timeTo,
              reservationId: docRef.id, // Add this line
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save reservation to Firestore', e, StackTrace.current, 'RESERVATION');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save reservation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    contactController.dispose();
    commentsController.dispose();
    timeController.dispose();
    super.dispose();
  }
}
