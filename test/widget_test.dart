// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_reservation_app/main.dart';
// import 'package:event_reservation_app/models/event_model.dart';
// import 'package:event_reservation_app/widgets/event_card_widget.dart';
// import 'package:event_reservation_app/pages/home_screen.dart';
// import 'package:event_reservation_app/pages/auth_page.dart';
// import 'package:event_reservation_app/pages/reservation_page.dart';

void main() {
  group('Church Events App Tests', () {
    // Test the main app initialization
    testWidgets('App starts with AuthPage', (WidgetTester tester) async {
      await tester.pumpWidget(const EventReservationApp());
      
      // Verify that AuthPage is displayed initially
      expect(find.text('Church Events'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
    });

//     // Test Event Model
//     test('Event model creates correctly', () {
//       final event = Event(
//         id: '1',
//         title: 'Sunday Mass',
//         description: 'Weekly Sunday service',
//         date: '2024-01-15',
//         location: 'Main Chapel',
//         imageUrl: 'https://example.com/image.jpg',
//       );

//       expect(event.id, '1');
//       expect(event.title, 'Sunday Mass');
//       expect(event.description, 'Weekly Sunday service');
//       expect(event.date, '2024-01-15');
//       expect(event.location, 'Main Chapel');
//       expect(event.imageUrl, 'https://example.com/image.jpg');
//     });

//     // Test EventCardWidget
//     testWidgets('EventCardWidget displays event information', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'This is a test event description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: EventCardWidget(event: testEvent),
//           ),
//         ),
//       );

//       // Verify event information is displayed
//       expect(find.text('Test Event'), findsOneWidget);
//       expect(find.text('This is a test event description'), findsOneWidget);
//       expect(find.text('2024-01-15'), findsOneWidget);
//       expect(find.text('Test Location'), findsOneWidget);
//       expect(find.text('Reserve Now'), findsOneWidget);
      
//       // Verify icons are present
//       expect(find.byIcon(Icons.calendar_today), findsOneWidget);
//       expect(find.byIcon(Icons.location_on), findsOneWidget);
//     });

//     // Test EventCardWidget navigation
//     testWidgets('EventCardWidget navigates to ReservationPage', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'This is a test event description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: EventCardWidget(event: testEvent),
//           ),
//         ),
//       );

//       // Tap the Reserve Now button
//       await tester.tap(find.text('Reserve Now'));
//       await tester.pumpAndSettle();

//       // Verify navigation to ReservationPage
//       expect(find.text('Event Reservation'), findsOneWidget);
//       expect(find.text('Test Event'), findsWidgets);
//     });

//     // Test AuthPage login functionality
//     testWidgets('AuthPage login form validation', (WidgetTester tester) async {
//       await tester.pumpWidget(const MaterialApp(home: AuthPage()));

//       // Find login form elements
//       expect(find.text('Username'), findsOneWidget);
//       expect(find.text('Password'), findsOneWidget);
      
//       // Test empty form submission
//       await tester.tap(find.text('LOGIN'));
//       await tester.pumpAndSettle();
      
//       // Should show validation errors
//       expect(find.text('Please enter username'), findsOneWidget);
//       expect(find.text('Please enter password'), findsOneWidget);
//     });

//     // Test valid login
//     testWidgets('Valid login navigates to HomeScreen', (WidgetTester tester) async {
//       await tester.pumpWidget(const MaterialApp(home: AuthPage()));

//       // Enter valid credentials
//       await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
//       await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      
//       // Tap login button
//       await tester.tap(find.text('LOGIN'));
//       await tester.pumpAndSettle();

//       // Should navigate to HomeScreen
//       expect(find.text('EVENTS'), findsOneWidget);
//       expect(find.byIcon(Icons.menu), findsOneWidget);
//     });

//     // Test HomeScreen displays events
//     testWidgets('HomeScreen displays events list', (WidgetTester tester) async {
//       await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

//       // Verify events are displayed
//       expect(find.text('EVENTS'), findsOneWidget);
//       expect(find.text('Sunday Mass'), findsOneWidget);
//       expect(find.text('Bible Study'), findsOneWidget);
//       expect(find.text('Prayer Meeting'), findsOneWidget);
      
//       // Verify Reserve Now buttons are present
//       expect(find.text('Reserve Now'), findsWidgets);
//     });

//     // Test drawer functionality
//     testWidgets('Drawer opens and displays menu items', (WidgetTester tester) async {
//       await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

//       // Open drawer
//       await tester.tap(find.byIcon(Icons.menu));
//       await tester.pumpAndSettle();

//       // Verify drawer items
//       expect(find.text('Church Events'), findsOneWidget);
//       expect(find.text('Home'), findsOneWidget);
//       expect(find.text('My Bookings'), findsOneWidget);
//       expect(find.text('About'), findsOneWidget);
//       expect(find.text('Quit'), findsOneWidget);
//     });

//     // Test ReservationPage form validation
//     testWidgets('ReservationPage validates form fields', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'Test Description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: ReservationPage(event: testEvent),
//         ),
//       );

//       // Try to submit empty form
//       await tester.tap(find.text('RESERVE'));
//       await tester.pumpAndSettle();

//       // Should show validation errors
//       expect(find.text('Please enter your name'), findsOneWidget);
//       expect(find.text('Please enter email'), findsOneWidget);
//       expect(find.text('Please enter phone number'), findsOneWidget);
//     });

//     // Test email validation
//     testWidgets('ReservationPage validates email format', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'Test Description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: ReservationPage(event: testEvent),
//         ),
//       );

//       // Enter invalid email
//       await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
//       await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
//       await tester.enterText(find.byKey(const Key('phone_field')), '1234567890');
      
//       await tester.tap(find.text('RESERVE'));
//       await tester.pumpAndSettle();

//       // Should show email validation error
//       expect(find.text('Please enter a valid email'), findsOneWidget);
//     });

//     // Test successful reservation
//     testWidgets('Valid reservation navigates to success page', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'Test Description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: ReservationPage(event: testEvent),
//         ),
//       );

//       // Fill out form with valid data
//       await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
//       await tester.enterText(find.byKey(const Key('email_field')), 'john@example.com');
//       await tester.enterText(find.byKey(const Key('phone_field')), '1234567890');
//       await tester.enterText(find.byKey(const Key('notes_field')), 'Test notes');
      
//       // Submit form
//       await tester.tap(find.text('RESERVE'));
//       await tester.pumpAndSettle();

//       // Should navigate to success page
//       expect(find.text('Reservation Successful!'), findsOneWidget);
//       expect(find.text('Your reservation has been confirmed'), findsOneWidget);
//     });

//     // Test date picker functionality
//     testWidgets('Date picker opens when calendar icon is tapped', (WidgetTester tester) async {
//       final testEvent = Event(
//         id: '1',
//         title: 'Test Event',
//         description: 'Test Description',
//         date: '2024-01-15',
//         location: 'Test Location',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: ReservationPage(event: testEvent),
//         ),
//       );

//       // Tap calendar icon
//       await tester.tap(find.byIcon(Icons.calendar_today));
//       await tester.pumpAndSettle();

//       // Date picker should be displayed
//       expect(find.byType(DatePickerDialog), findsOneWidget);
//     });

//     // Test app theme
//     testWidgets('App uses correct theme colors', (WidgetTester tester) async {
//       await tester.pumpWidget(const MyApp());
      
//       final MaterialApp app = tester.widget(find.byType(MaterialApp));
//       expect(app.theme?.primarySwatch, Colors.blue);
//       expect(app.theme?.scaffoldBackgroundColor, Colors.white);
//       expect(app.theme?.appBarTheme.backgroundColor, Colors.black);
//       expect(app.theme?.appBarTheme.foregroundColor, Colors.white);
//     });
//   });

//   group('Edge Cases and Error Handling', () {
//     // Test long text handling
//     testWidgets('EventCard handles long text properly', (WidgetTester tester) async {
//       final longTextEvent = Event(
//         id: '1',
//         title: 'This is a very long event title that should be truncated properly',
//         description: 'This is a very long description that should be truncated properly and not overflow the card boundaries. It should show ellipsis when text is too long to fit in the designated space.',
//         date: '2024-01-15',
//         location: 'This is a very long location name that should also be truncated',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: EventCardWidget(event: longTextEvent),
//           ),
//         ),
//       );

//       // Widget should render without overflow errors
//       expect(tester.takeException(), isNull);
//     });

//     // Test empty data handling
//     testWidgets('EventCard handles empty data gracefully', (WidgetTester tester) async {
//       final emptyEvent = Event(
//         id: '',
//         title: '',
//         description: '',
//         date: '',
//         location: '',
//         imageUrl: '',
//       );

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: EventCardWidget(event: emptyEvent),
//           ),
//         ),
//       );

//       // Widget should render without errors
//       expect(tester.takeException(), isNull);
//       expect(find.text('Reserve Now'), findsOneWidget);
//     });
  });
}