+ # GUMC Church App
+ 
+ A Flutter-based church management application that helps connect and organize church communities through teams, events, and communications.
+ 
+ ## Features
+ 
+ ### Ministry Teams
+ - Create and join ministry teams
+ - Team member management with roles
+ - Real-time team chat
+ - File sharing within teams
+ - Team event scheduling
+ 
+ ### Events
+ - Create and manage church events
+ - Recurring event support
+ - Calendar view with event details
+ - Event attendance tracking
+ - Push notifications for events
+ 
+ ### Communication
+ - Church-wide announcements
+ - Team-specific messaging
+ - File attachments
+ - Real-time notifications
+ 
+ ### Admin Portal
+ - Secure admin access
+ - Member management
+ - Event oversight
+ - Analytics dashboard
+ 
+ ## Getting Started
+ 
+ ### Prerequisites
+ - Flutter SDK (latest stable version)
+ - Firebase account
+ - Android Studio or Xcode
+ 
+ ### Installation
+ 
+ 1. Clone the repository
+ ```bash
+ git clone https://github.com/your-org/gumc-app.git
+ cd gumc-app
+ ```
+ 
+ 2. Install dependencies
+ ```bash
+ flutter pub get
+ ```
+ 
+ 3. Firebase Setup
+ - Create a new Firebase project
+ - Add Android & iOS apps in Firebase console
+ - Download configuration files:
+   - `google-services.json` for Android
+   - `GoogleService-Info.plist` for iOS
+ - Place configuration files in their respective directories
+ 
+ 4. Run the app
+ ```bash
+ flutter run
+ ```
+ 
+ ## Project Structure
+ ```
+ lib/
+ ├── models/       # Data models
+ ├── screens/      # UI screens
+ ├── services/     # Business logic
+ ├── widgets/      # Reusable components
+ └── utils/        # Helper functions
+ ```
+ 
+ ## Dependencies
+ ```yaml
+ dependencies:
+   firebase_core: ^2.24.2
+   firebase_auth: ^4.15.3
+   cloud_firestore: ^4.13.6
+   firebase_messaging: ^14.7.10
+   flutter_local_notifications: ^16.3.0
+   shared_preferences: ^2.2.2
+   intl: ^0.18.1
+ ```
+ 
+ ## Testing
+ ```bash
+ # Run unit tests
+ flutter test
+ 
+ # Run integration tests
+ flutter test integration_test
+ ```
+ 
+ ## Contributing
+ 1. Fork the repository
+ 2. Create your feature branch
+ 3. Commit your changes
+ 4. Push to the branch
+ 5. Create a Pull Request
+ 
+ ## Security
+ - Firebase Authentication
+ - Secure admin access
+ - Data validation
+ - Error handling
+ - Crash reporting
+ 
+ ## Support
+ For support or questions, please contact:
+ - Email: support@gumcapp.com
+ - Discord: [GUMC App Community](https://discord.gg/gumcapp)
+ 
+ ## License
+ This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
+ 
+ ---
+ Built with ❤️ for GUMC Church
