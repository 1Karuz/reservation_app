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

// Wedding-specific controllers
  final TextEditingController groomNameController = TextEditingController();
  final TextEditingController brideNameController = TextEditingController();
  final TextEditingController groomFatherController = TextEditingController();
  final TextEditingController groomMotherController = TextEditingController();
  final TextEditingController brideFatherController = TextEditingController();
  final TextEditingController brideMotherController = TextEditingController();

// Baptism-specific controllers
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController childBirthdateController =
      TextEditingController();
  final TextEditingController childBirthplaceController =
      TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherMaidenNameController =
      TextEditingController();
  final TextEditingController sponsorsController = TextEditingController();
  String? parentMarriageType;

// Funeral-specific controllers
  final TextEditingController deceasedNameController = TextEditingController();
  final TextEditingController deceasedAgeController = TextEditingController();
  final TextEditingController deathDateController = TextEditingController();
  final TextEditingController burialDateController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  final TextEditingController causeOfDeathController = TextEditingController();
  final TextEditingController guardianNameController = TextEditingController();
  final TextEditingController burialPlaceController = TextEditingController();
  bool? wasBaptized;
  bool? receivedLastSacrament;

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
      AppLogger.error(
          'Error in date validation', e, StackTrace.current, 'RESERVATION');
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
            'PSA Certified Birth Certificate (Bride & Groom)',
            'CENOMAR - Certificate of No Marriage Record',
            'Baptismal Certificate from Parish',
            'Confirmation Certificate from Parish',
            'Marriage License from City Hall',
            'Pre-Cana Seminar Certificate'
          ]
        };
      case 'funeral':
        return {
          'Required Documents': [
            'Death Certificate',
            'Burial Permit (if applicable)',
            'Baptismal Certificate of Deceased (if available)'
          ]
        };
      case 'baptism':
        return {
          'Required Documents': [
            'PSA Birth Certificate of Child',
            'Parents\' Catholic Marriage Certificate',
            'Baptismal Certificates of Parents',
            'Confirmation Certificates of Godparents'
          ]
        };
      case 'house blessing':
        return {
          'Note': [
            'No formal documents required',
            'Please contact the parish priest to schedule',
            'Prepare your home for the blessing ceremony'
          ]
        };
      case 'confession':
        return {
          'Note': [
            'No documents required for confession',
            'Simply book your preferred time slot',
            'Arrive 5-10 minutes early'
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
                        // Header (keep existing)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.black, Colors.grey],
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

                        // Event-Specific Fields
                        _buildEventSpecificFields(),

                        const SizedBox(height: 30),

                        // Event Details Section (Date & Time - keep for all events)
                        _buildSectionHeader('Event Details', Icons.event),
                        const SizedBox(height: 20),
                        _buildDateField(),
                        const SizedBox(height: 20),
                        _buildTimeField(),

                        // Comments field (only for certain events)
                        if (widget.eventType.toLowerCase() !=
                                'house blessing' &&
                            widget.eventType.toLowerCase() != 'confession') ...[
                          const SizedBox(height: 20),
                          _buildModernTextField(
                              'Additional Comments (Optional)',
                              commentsController,
                              icon: Icons.message_outlined,
                              maxLines: 4,
                              isRequired: false),
                        ],

                        const SizedBox(height: 30),

                        // Document Requirements Section
                        if (widget.eventType.toLowerCase() !=
                                'house blessing' &&
                            widget.eventType.toLowerCase() != 'confession') ...[
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

  // ===== WEDDING FIELDS =====
  Widget _buildWeddingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Groom Information', Icons.male),
        const SizedBox(height: 20),
        _buildModernTextField('Groom Full Name', groomNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Groom Father\'s Name', groomFatherController,
            icon: Icons.supervisor_account, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField(
            'Groom Mother\'s Maiden Name', groomMotherController,
            icon: Icons.supervisor_account, isRequired: true),
        const SizedBox(height: 30),
        _buildSectionHeader('Bride Information', Icons.female),
        const SizedBox(height: 20),
        _buildModernTextField('Bride Full Name', brideNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Bride Father\'s Name', brideFatherController,
            icon: Icons.supervisor_account, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField(
            'Bride Mother\'s Maiden Name', brideMotherController,
            icon: Icons.supervisor_account, isRequired: true),
        const SizedBox(height: 30),
        _buildSectionHeader('Contact Information', Icons.contact_phone),
        const SizedBox(height: 20),
        _buildModernTextField('Contact Number', contactController,
            icon: Icons.phone_outlined, isRequired: true, isPhone: true),
      ],
    );
  }

// ===== BAPTISM FIELDS =====
  Widget _buildBaptismFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Child Information', Icons.child_care),
        const SizedBox(height: 20),
        _buildModernTextField('Child Full Name', childNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildDatePickerField('Child Birth Date', childBirthdateController,
            isPast: true),
        const SizedBox(height: 20),
        _buildModernTextField('Place of Birth', childBirthplaceController,
            icon: Icons.location_on_outlined, isRequired: true),
        const SizedBox(height: 30),
        _buildSectionHeader('Parents Information', Icons.family_restroom),
        const SizedBox(height: 20),
        _buildModernTextField('Father\'s Name', fatherNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField(
            'Mother\'s Maiden Name', motherMaidenNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildMarriageTypeDropdown(),
        const SizedBox(height: 20),
        _buildModernTextField('Contact Number', contactController,
            icon: Icons.phone_outlined, isRequired: true, isPhone: true),
        const SizedBox(height: 30),
        _buildSectionHeader('Sponsors (Ninong/Ninang)', Icons.groups),
        const SizedBox(height: 20),
        _buildModernTextField(
            'Sponsors Names (separated by comma)', sponsorsController,
            icon: Icons.people_outline, maxLines: 3, isRequired: true),
      ],
    );
  }

// ===== FUNERAL FIELDS =====
  Widget _buildFuneralFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Deceased Information', Icons.local_florist),
        const SizedBox(height: 20),
        _buildModernTextField('Name of Deceased', deceasedNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField('Age', deceasedAgeController,
                  icon: Icons.calendar_today, isRequired: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDatePickerField('Date of Death', deathDateController,
                  isPast: true),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDatePickerField('Date Buried', burialDateController,
            isPast: true),
        const SizedBox(height: 20),
        _buildModernTextField('Residence', residenceController,
            icon: Icons.home_outlined, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Cause of Death', causeOfDeathController,
            icon: Icons.medical_services_outlined, isRequired: true),
        const SizedBox(height: 30),
        _buildSectionHeader('Sacramental Status', Icons.church),
        const SizedBox(height: 20),
        _buildCheckboxField('Was Baptized?', wasBaptized, (value) {
          setState(() => wasBaptized = value);
        }),
        const SizedBox(height: 12),
        _buildCheckboxField('Received Last Sacrament?', receivedLastSacrament,
            (value) {
          setState(() => receivedLastSacrament = value);
        }),
        const SizedBox(height: 30),
        _buildSectionHeader(
            'Contact & Burial Information', Icons.contact_phone),
        const SizedBox(height: 20),
        _buildModernTextField(
            'Parent/Spouse/Guardian Name', guardianNameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Contact Number', contactController,
            icon: Icons.phone_outlined, isRequired: true, isPhone: true),
        const SizedBox(height: 20),
        _buildModernTextField('Where Buried', burialPlaceController,
            icon: Icons.location_on_outlined, isRequired: true),
      ],
    );
  }

// ===== HOUSE BLESSING FIELDS =====
  Widget _buildHouseBlessingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Homeowner Information', Icons.home),
        const SizedBox(height: 20),
        _buildModernTextField('Homeowner Name', nameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Contact Number', contactController,
            icon: Icons.phone_outlined, isRequired: true, isPhone: true),
        const SizedBox(height: 20),
        _buildModernTextField('House Address', commentsController,
            icon: Icons.location_on_outlined, maxLines: 3, isRequired: true),
      ],
    );
  }

// ===== CONFESSION FIELDS =====
  Widget _buildConfessionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Personal Information', Icons.person),
        const SizedBox(height: 20),
        _buildModernTextField('Name', nameController,
            icon: Icons.person_outline, isRequired: true),
        const SizedBox(height: 20),
        _buildModernTextField('Contact Number', contactController,
            icon: Icons.phone_outlined, isRequired: true, isPhone: true),
        const SizedBox(height: 20),
        _buildModernTextField('Additional Notes (Optional)', commentsController,
            icon: Icons.message_outlined, maxLines: 3, isRequired: false),
      ],
    );
  }

// ===== HELPER WIDGETS =====
  Widget _buildDatePickerField(String label, TextEditingController controller,
      {bool isPast = false}) {
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
            initialDate: isPast
                ? now.subtract(const Duration(days: 365 * 5))
                : now, // Default to 5 years ago for past dates
            firstDate: isPast ? DateTime(1900) : now,
            lastDate: isPast ? now : now.add(const Duration(days: 365)),
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
            setState(() {
              controller.text = "${picked.day}/${picked.month}/${picked.year}";
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildMarriageTypeDropdown() {
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
      child: DropdownButtonFormField<String>(
        value: parentMarriageType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select marriage type';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Parents Marriage Type',
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: const Icon(Icons.favorite_outline, color: Colors.black),
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
        items: const [
          DropdownMenuItem(value: 'Catholic', child: Text('Catholic')),
          DropdownMenuItem(value: 'Aglipay', child: Text('Aglipay')),
          DropdownMenuItem(value: 'Civil', child: Text('Civil')),
          DropdownMenuItem(
              value: 'Not Yet Married', child: Text('Not Yet Married')),
          DropdownMenuItem(value: 'Others', child: Text('Others')),
        ],
        onChanged: (value) {
          setState(() {
            parentMarriageType = value;
          });
        },
      ),
    );
  }

  Widget _buildCheckboxField(
      String label, bool? value, Function(bool?) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value ?? false,
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSpecificFields() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        return _buildWeddingFields();
      case 'baptism':
        return _buildBaptismFields();
      case 'funeral':
        return _buildFuneralFields();
      case 'house blessing':
        return _buildHouseBlessingFields();
      case 'confession':
        return _buildConfessionFields();
      default:
        return Container();
    }
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
    final requirements = getRequiredDocuments();
    final requirementsList =
        requirements.values.expand((list) => list).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Required Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All documents must be uploaded to proceed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Individual document upload cards
        ...requirementsList.asMap().entries.map((entry) {
          final index = entry.key;
          final docName = entry.value;
          final isUploaded =
              uploadedDocuments.any((doc) => doc.type == 'requirement_$index');

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color:
                    isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isUploaded ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUploaded
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isUploaded ? Icons.check_circle : Icons.description,
                          color: isUploaded
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUploaded ? 'Uploaded' : 'Required',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUploaded
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUploaded)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 28,
                        ),
                    ],
                  ),
                ),

                // Upload area
                Container(
                  padding: const EdgeInsets.all(16),
                  child: isUploaded
                      ? _buildUploadedPreview(index)
                      : _buildUploadButtons(index, docName),
                ),
              ],
            ),
          );
        }).toList(),

        // Progress indicator
        const SizedBox(height: 16),
        _buildUploadProgress(requirementsList.length),
      ],
    );
  }

  Widget _buildUploadedPreview(int docIndex) {
    final doc = uploadedDocuments.firstWhere(
      (d) => d.type == 'requirement_$docIndex',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: Image.memory(
                base64Decode(doc.base64Data),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeDocument(docIndex),
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons(int docIndex, String docName) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernUploadButton(
                'Camera',
                Icons.camera_alt,
                () => _pickImageForDocument(
                    ImageSource.camera, docIndex, docName),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildModernUploadButton(
                'Gallery',
                Icons.photo_library,
                () => _pickImageForDocument(
                    ImageSource.gallery, docIndex, docName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload this document',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildModernUploadButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(int totalRequired) {
    final uploadedCount = uploadedDocuments
        .where((doc) => doc.type.startsWith('requirement_'))
        .length;
    final progress = totalRequired > 0 ? uploadedCount / totalRequired : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upload Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '$uploadedCount / $totalRequired',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
              ),
              minHeight: 8,
            ),
          ),
          if (progress < 1.0) ...[
            const SizedBox(height: 8),
            Text(
              '${totalRequired - uploadedCount} document${totalRequired - uploadedCount != 1 ? 's' : ''} remaining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImageForDocument(
      ImageSource source, int docIndex, String docName) async {
    try {
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
        await _processAndAddDocumentImage(image, source, docIndex, docName);
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

  Future<void> _processAndAddDocumentImage(
      XFile image, ImageSource source, int docIndex, String docName) async {
    AppLogger.imageProcessing('Processing document: $docName');

    try {
      final bytes = await File(image.path).readAsBytes();
      AppLogger.imageProcessing('Read ${bytes.length} bytes from image file');

      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        AppLogger.error(
            'Failed to decode image: ${image.name}', null, null, 'IMAGE');
        return;
      }

      if (originalImage.width > 800) {
        originalImage = img.copyResize(originalImage, width: 800);
      }

      final compressedBytes = img.encodeJpg(originalImage, quality: 70);
      final base64String = base64Encode(compressedBytes);

      if (base64String.length > 500000) {
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

      // Remove existing document for this requirement if any
      setState(() {
        uploadedDocuments
            .removeWhere((doc) => doc.type == 'requirement_$docIndex');
      });

      final docImage = DocumentImage(
        name: docName,
        base64Data: base64String,
        type: 'requirement_$docIndex',
        uploadedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          uploadedDocuments.add(docImage);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docName uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
          'Error processing document image', e, StackTrace.current, 'IMAGE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument(int docIndex) {
    setState(() {
      uploadedDocuments
          .removeWhere((doc) => doc.type == 'requirement_$docIndex');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document removed'),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

// pages/reservation_page.dart (Updated _saveReservation method)
  void _saveReservation() async {
    // FIRST: Validate the form
    if (!_formKey.currentState!.validate()) {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: 20,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // SECOND: Validate event-specific required fields
    String? eventValidationError = _validateEventSpecificFields();
    if (eventValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventValidationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: 20,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;

    AppLogger.reservation(
        'Starting reservation save process for ${widget.eventType}');

    // Check if all required documents are uploaded
    if (widget.eventType.toLowerCase() != 'house blessing' &&
        widget.eventType.toLowerCase() != 'confession') {
      final requirements = getRequiredDocuments();
      final requirementsList =
          requirements.values.expand((list) => list).toList();
      final requiredCount = requirementsList.length;
      final uploadedCount = uploadedDocuments
          .where((doc) => doc.type.startsWith('requirement_'))
          .length;

      if (uploadedCount < requiredCount) {
        AppLogger.warning(
            'Incomplete documents: $uploadedCount/$requiredCount uploaded for ${widget.eventType}',
            'RESERVATION');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Please upload all $requiredCount required documents (${uploadedCount}/$requiredCount uploaded)'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    // Final validation before saving
    if (selectedDate != null && !_isDateAvailable(selectedDate!)) {
      AppLogger.warning(
          'Selected date is no longer available: $selectedDate', 'RESERVATION');
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Selected date is no longer available'),
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

    // Build event-specific data
    Map<String, dynamic> eventSpecificData = _buildEventSpecificData();

    final reservation = ReservationData(
      reservationId: '',
      userId: user!.uid,
      eventType: widget.eventType,
      name: _getPrimaryName(),
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

    AppLogger.reservation(
        'Reservation data prepared - Event: ${widget.eventType}, Date: $selectedDate, User: ${user.uid}');

    try {
      // Merge base reservation data with event-specific data
      Map<String, dynamic> reservationData = reservation.toMap();
      reservationData.addAll(eventSpecificData);

      final docRef = await FirebaseFirestore.instance
          .collection('reservations')
          .add(reservationData);

      reservation.reservationId = docRef.id;
      UserSession.addReservation(reservation);

      AppLogger.reservation(
          'Successfully saved reservation with ID: ${docRef.id}');

      if (mounted) {
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
              reservationId: docRef.id,
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save reservation to Firestore', e,
          StackTrace.current, 'RESERVATION');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to save reservation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

// Validate event-specific required fields
  String? _validateEventSpecificFields() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        if (groomNameController.text.trim().isEmpty) {
          return 'Please enter the groom\'s full name';
        }
        if (brideNameController.text.trim().isEmpty) {
          return 'Please enter the bride\'s full name';
        }
        if (groomFatherController.text.trim().isEmpty) {
          return 'Please enter the groom\'s father\'s name';
        }
        if (groomMotherController.text.trim().isEmpty) {
          return 'Please enter the groom\'s mother\'s name';
        }
        if (brideFatherController.text.trim().isEmpty) {
          return 'Please enter the bride\'s father\'s name';
        }
        if (brideMotherController.text.trim().isEmpty) {
          return 'Please enter the bride\'s mother\'s name';
        }
        break;

      case 'baptism':
        if (childNameController.text.trim().isEmpty) {
          return 'Please enter the child\'s full name';
        }
        if (childBirthdateController.text.trim().isEmpty) {
          return 'Please select the child\'s birth date';
        }
        if (childBirthplaceController.text.trim().isEmpty) {
          return 'Please enter the child\'s birth place';
        }
        if (fatherNameController.text.trim().isEmpty) {
          return 'Please enter the father\'s name';
        }
        if (motherMaidenNameController.text.trim().isEmpty) {
          return 'Please enter the mother\'s maiden name';
        }
        if (parentMarriageType == null || parentMarriageType!.isEmpty) {
          return 'Please select the parents\' marriage type';
        }
        if (sponsorsController.text.trim().isEmpty) {
          return 'Please enter the sponsors\' names (separate multiple sponsors with commas)';
        }
        break;

      case 'funeral':
        if (deceasedNameController.text.trim().isEmpty) {
          return 'Please enter the name of the deceased';
        }
        if (deceasedAgeController.text.trim().isEmpty) {
          return 'Please enter the age of the deceased';
        }
        if (deathDateController.text.trim().isEmpty) {
          return 'Please select the date of death';
        }
        if (burialDateController.text.trim().isEmpty) {
          return 'Please select the burial date';
        }
        if (residenceController.text.trim().isEmpty) {
          return 'Please enter the residence';
        }
        if (causeOfDeathController.text.trim().isEmpty) {
          return 'Please enter the cause of death';
        }
        if (guardianNameController.text.trim().isEmpty) {
          return 'Please enter the guardian/contact person\'s name';
        }
        if (burialPlaceController.text.trim().isEmpty) {
          return 'Please enter the burial place';
        }
        break;

      case 'house blessing':
        if (nameController.text.trim().isEmpty) {
          return 'Please enter the homeowner\'s name';
        }
        if (commentsController.text.trim().isEmpty) {
          return 'Please enter the house address';
        }
        break;

      case 'confession':
        if (nameController.text.trim().isEmpty) {
          return 'Please enter your name';
        }
        break;
    }

    return null; // No validation errors
  }

// Helper method to build event-specific data
  Map<String, dynamic> _buildEventSpecificData() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        return {
          'groomName': groomNameController.text.trim(),
          'groomFather': groomFatherController.text.trim(),
          'groomMother': groomMotherController.text.trim(),
          'brideName': brideNameController.text.trim(),
          'brideFather': brideFatherController.text.trim(),
          'brideMother': brideMotherController.text.trim(),
        };
      case 'baptism':
        return {
          'childName': childNameController.text.trim(),
          'childBirthdate': childBirthdateController.text.trim(),
          'childBirthplace': childBirthplaceController.text.trim(),
          'fatherName': fatherNameController.text.trim(),
          'motherMaidenName': motherMaidenNameController.text.trim(),
          'parentMarriageType': parentMarriageType ?? '',
          'sponsors': sponsorsController.text.trim(),
        };
      case 'funeral':
        return {
          'deceasedName': deceasedNameController.text.trim(),
          'deceasedAge': deceasedAgeController.text.trim(),
          'deathDate': deathDateController.text.trim(),
          'burialDate': burialDateController.text.trim(),
          'residence': residenceController.text.trim(),
          'causeOfDeath': causeOfDeathController.text.trim(),
          'wasBaptized': wasBaptized ?? false,
          'receivedLastSacrament': receivedLastSacrament ?? false,
          'guardianName': guardianNameController.text.trim(),
          'burialPlace': burialPlaceController.text.trim(),
        };
      case 'house blessing':
        return {
          'homeownerName': nameController.text.trim(),
          'houseAddress': commentsController.text.trim(),
        };
      case 'confession':
        return {
          'personName': nameController.text.trim(),
          'notes': commentsController.text.trim(),
        };
      default:
        return {};
    }
  }

// Helper method to get primary name for display
  String _getPrimaryName() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        return '${groomNameController.text.trim()} & ${brideNameController.text.trim()}';
      case 'baptism':
        return childNameController.text.trim();
      case 'funeral':
        return deceasedNameController.text.trim();
      case 'house blessing':
        return nameController.text.trim();
      case 'confession':
        return nameController.text.trim();
      default:
        return nameController.text.trim();
    }
  }

  @override
  void dispose() {
    // Base controllers
    nameController.dispose();
    dateController.dispose();
    contactController.dispose();
    commentsController.dispose();
    timeController.dispose();

    // Wedding controllers
    groomNameController.dispose();
    brideNameController.dispose();
    groomFatherController.dispose();
    groomMotherController.dispose();
    brideFatherController.dispose();
    brideMotherController.dispose();

    // Baptism controllers
    childNameController.dispose();
    childBirthdateController.dispose();
    childBirthplaceController.dispose();
    fatherNameController.dispose();
    motherMaidenNameController.dispose();
    sponsorsController.dispose();

    // Funeral controllers
    deceasedNameController.dispose();
    deceasedAgeController.dispose();
    deathDateController.dispose();
    burialDateController.dispose();
    residenceController.dispose();
    causeOfDeathController.dispose();
    guardianNameController.dispose();
    burialPlaceController.dispose();

    super.dispose();
  }
}
