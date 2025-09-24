// pages/payment_page.dart (Updated - Strict receipt validation)
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_session.dart';
import '../services/app_logger.dart';
import 'home_screen.dart';

class PaymentPage extends StatefulWidget {
  final String eventType;
  final String name;
  final String email;
  final DateTime date;
  final String contact;
  final String timeFrom;
  final String timeTo;
  final String reservationId;

  const PaymentPage({
    super.key,
    required this.eventType,
    required this.name,
    required this.email,
    required this.date,
    required this.contact,
    required this.timeFrom,
    required this.timeTo,
    required this.reservationId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isUploading = false;
  List<DocumentImage> uploadedReceipts = [];
  final ImagePicker _picker = ImagePicker();

  // Payment amounts for each event type
  Map<String, double> getPaymentAmounts() {
    return {
      'wedding': 12000.0,
      'baptism': 2500.0,
      'funeral': 5000.0,
      'house blessing': 3000.0,
      'confession': 0.0, // Optional
    };
  }

  double getCurrentEventAmount() {
    final amounts = getPaymentAmounts();
    return amounts[widget.eventType.toLowerCase()] ?? 0.0;
  }

  bool isPaymentOptional() {
    return widget.eventType.toLowerCase() == 'confession';
  }

  Color _getServiceColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return const Color(0xFFE91E63);
      case 'baptism':
        return const Color(0xFF2196F3);
      case 'funeral':
        return const Color(0xFF757575);
      case 'house blessing':
        return const Color(0xFF4CAF50);
      case 'confession':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getServiceIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'baptism':
        return Icons.water_drop;
      case 'funeral':
        return Icons.local_florist;
      case 'house blessing':
        return Icons.home;
      case 'confession':
        return Icons.auto_stories;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceColor = _getServiceColor(widget.eventType);
    final serviceIcon = _getServiceIcon(widget.eventType);
    final amount = getCurrentEventAmount();
    final isOptional = isPaymentOptional();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          'Payment',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [serviceColor.withOpacity(0.8), serviceColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: serviceColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(serviceIcon, color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.eventType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.date.day}/${widget.date.month}/${widget.date.year} • ${widget.timeFrom} - ${widget.timeTo}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (!isOptional)
                          Text(
                            '₱${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (isOptional)
                          const Text(
                            'Optional Donation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // QR Code Section
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: serviceColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Scan to Pay',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: serviceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: QrImageView(
                        data: _generateQRData(),
                        version: QrVersions.auto,
                        size: 200.0,
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'STA URSULA PARISH CHURCH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'GCash: 09123456789',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (!isOptional)
                          Text(
                            'Amount: ₱${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Important Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    serviceColor.withOpacity(0.05),
                    serviceColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: serviceColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: serviceColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: serviceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPaymentInformation(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Receipt Upload Section
            _buildReceiptUploadSection(),

            const SizedBox(height: 40),

            // Action Buttons
            Column(
              children: [
                // Submit Payment Button (Requires receipts for online payment)
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: uploadedReceipts.isEmpty && !isOptional
                        ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                        : LinearGradient(
                            colors: [serviceColor.withOpacity(0.8), serviceColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: uploadedReceipts.isNotEmpty || isOptional
                        ? [
                            BoxShadow(
                              color: serviceColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : () => _submitPayment(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                isOptional ? 'Submit with Payment' : 'Submit Payment',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Receipt requirement warning for online payment
                if (uploadedReceipts.isEmpty && !isOptional) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please upload payment receipt to submit online payment',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 15),

                // Pay at Church Button (No receipt required)
                Container(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _isUploading ? null : () => _submitPayment(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: serviceColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.church, color: serviceColor),
                        const SizedBox(width: 10),
                        Text(
                          'Pay at Church',
                          style: TextStyle(
                            color: serviceColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _generateQRData() {
    final amount = getCurrentEventAmount();
    return 'STA_URSULA_PAYMENT:${widget.reservationId}:${widget.eventType}:${amount}:${widget.name}';
  }

  String _getPaymentInformation() {
    switch (widget.eventType.toLowerCase()) {
      case 'wedding':
        return "The church stipend for the sacrament of Matrimony is ₱12,000. This covers the ceremony, priest's ministry, and church facilities. Payment can be made online via GCash or at the parish office.";
      case 'baptism':
        return "The customary donation for Baptism is ₱2,500. This supports the church's ministry and the sacramental ceremony. Your contribution helps maintain our sacred traditions.";
      case 'funeral':
        return "The stipend for funeral mass is ₱5,000. This covers the celebrant's ministry and church services during this difficult time. Our prayers are with your family.";
      case 'house blessing':
        return "The customary offering for house blessing is ₱3,000. This covers the priest's visit and blessing ceremony for your new home. May God bless your dwelling.";
      case 'confession':
        return "The Sacrament of Reconciliation is a gift of grace with no required fee. Any donation to support the church's ministry is welcome but entirely optional.";
      default:
        return "Please contact the parish office for information regarding customary donations and arrangements for your event.";
    }
  }

  Widget _buildReceiptUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: _getServiceColor(widget.eventType), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload Payment Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getServiceColor(widget.eventType),
                  ),
                ),
              ),
              if (!isPaymentOptional())
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    'REQUIRED',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
                      Text(
            isPaymentOptional()
                ? 'Upload a screenshot or photo of your payment receipt (optional for donations).'
                : 'Upload a screenshot or photo of your payment receipt for verification. Required for online payment submission.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 15),
          if (uploadedReceipts.isNotEmpty) _buildUploadedReceiptsList(),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
          foregroundColor: _getServiceColor(widget.eventType),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _getServiceColor(widget.eventType)),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedReceiptsList() {
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
            'Uploaded Receipts (${uploadedReceipts.length})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ...uploadedReceipts.asMap().entries.map((entry) {
            final index = entry.key;
            final receipt = entry.value;
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
                    receipt.type == 'camera' ? Icons.camera_alt : Icons.photo,
                    color: _getServiceColor(widget.eventType),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Receipt via ${receipt.type}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeReceipt(index),
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
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndAddReceipt(image, source);
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

  Future<void> _processAndAddReceipt(XFile image, ImageSource source) async {
    AppLogger.imageProcessing('Processing payment receipt: ${image.name}');

    try {
      final bytes = await File(image.path).readAsBytes();
      
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
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
              content: Text('Receipt image too large. Please choose a smaller image.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final receiptImage = DocumentImage(
        name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}',
        base64Data: base64String,
        type: source == ImageSource.camera ? 'camera' : 'gallery',
        uploadedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          uploadedReceipts.add(receiptImage);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error processing receipt image', e, StackTrace.current, 'PAYMENT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing receipt. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeReceipt(int index) {
    setState(() {
      uploadedReceipts.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt removed'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _submitPayment(bool paidOnline) async {
    // Strict validation: Online payment requires receipts (except for optional payments)
    if (paidOnline && uploadedReceipts.isEmpty && !isPaymentOptional()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one payment receipt before submitting online payment.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Update reservation with payment information
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .update({
        'paymentStatus': paidOnline ? 'paid_online' : 'pay_at_church',
        'paymentAmount': getCurrentEventAmount(),
        'paymentReceipts': uploadedReceipts.map((r) => r.toMap()).toList(),
        'paymentSubmittedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      AppLogger.info('Payment submission completed: ${paidOnline ? "Online" : "At Church"}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paidOnline 
                ? 'Payment submitted successfully!' 
                : 'Reservation confirmed. Payment will be made at the church.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.error('Payment submission failed', e, StackTrace.current, 'PAYMENT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}