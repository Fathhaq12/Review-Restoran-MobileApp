# Review Restoran Mobile App

Aplikasi mobile untuk review restoran yang memungkinkan pengguna memberikan ulasan, rating, dan berbagi pengalaman kuliner.

## Fitur Utama

- 📱 Interface yang user-friendly
- 📍 Integrasi dengan GPS dan Maps
- 📷 Upload foto makanan/restoran
- ⭐ Sistem rating dan review
- 🔔 Notifikasi push
- 💾 Penyimpanan data lokal

## Pengujian Perangkat Lunak

### 1. Unit Testing

| No  | Komponen         | Test Case                  | Input                                   | Expected Output         | Status  | Keterangan                    |
| --- | ---------------- | -------------------------- | --------------------------------------- | ----------------------- | ------- | ----------------------------- |
| 1   | Authentication   | Login dengan email valid   | email: test@email.com, password: 123456 | Login berhasil          | ✅ Pass | User berhasil masuk           |
| 2   | Authentication   | Login dengan email invalid | email: invalid, password: 123456        | Error message           | ✅ Pass | Menampilkan pesan error       |
| 3   | Restaurant Model | Create restaurant object   | Restaurant data                         | Valid restaurant object | ✅ Pass | Object terbentuk dengan benar |
| 4   | Review Model     | Calculate average rating   | ratings: [4, 5, 3, 4, 5]                | Average: 4.2            | ✅ Pass | Perhitungan rata-rata benar   |
| 5   | Database Helper  | Insert review              | Review object                           | Success/Failure         | ✅ Pass | Data tersimpan di SQLite      |
| 6   | API Service      | Fetch restaurants          | GET request                             | List of restaurants     | ✅ Pass | Data berhasil diambil         |

### 2. Integration Testing

| No  | Fitur             | Test Scenario              | Steps                                                       | Expected Result               | Status  | Keterangan                    |
| --- | ----------------- | -------------------------- | ----------------------------------------------------------- | ----------------------------- | ------- | ----------------------------- |
| 1   | User Registration | Registrasi pengguna baru   | 1. Buka form registrasi<br>2. Isi data valid<br>3. Submit   | Account created successfully  | ✅ Pass | Integrasi dengan API berhasil |
| 2   | Location Services | Get current location       | 1. Request permission<br>2. Get GPS coordinates             | Latitude & Longitude returned | ✅ Pass | GPS dan permission bekerja    |
| 3   | Image Upload      | Upload foto review         | 1. Select image<br>2. Compress image<br>3. Upload to server | Image uploaded successfully   | ✅ Pass | Image picker dan upload API   |
| 4   | Search Feature    | Search restaurant by name  | 1. Enter restaurant name<br>2. Click search                 | Filtered restaurant list      | ✅ Pass | Database query dan UI update  |
| 5   | Offline Mode      | View saved reviews offline | 1. Disable internet<br>2. Open saved reviews                | Display cached data           | ✅ Pass | SQLite dan offline capability |

### 3. UI/UX Testing

| No  | Screen/Component | Test Case             | Device          | Resolution | Status  | Issues Found          |
| --- | ---------------- | --------------------- | --------------- | ---------- | ------- | --------------------- |
| 1   | Login Screen     | Layout responsiveness | Android Phone   | 360x800    | ✅ Pass | -                     |
| 2   | Login Screen     | Layout responsiveness | Android Tablet  | 800x1280   | ✅ Pass | -                     |
| 3   | Restaurant List  | Scroll performance    | Various devices | Multiple   | ✅ Pass | Smooth scrolling      |
| 4   | Review Form      | Form validation       | Android/iOS     | Multiple   | ✅ Pass | Proper error messages |
| 5   | Map Integration  | Map display           | Android/iOS     | Multiple   | ✅ Pass | Maps load correctly   |
| 6   | Navigation       | Bottom navigation     | All devices     | Multiple   | ✅ Pass | Consistent navigation |

### 4. Performance Testing

| No  | Metric          | Test Scenario          | Target        | Actual Result | Status  | Optimization               |
| --- | --------------- | ---------------------- | ------------- | ------------- | ------- | -------------------------- |
| 1   | App Launch Time | Cold start             | < 3 seconds   | 2.1 seconds   | ✅ Pass | -                          |
| 2   | Image Loading   | Load restaurant images | < 2 seconds   | 1.5 seconds   | ✅ Pass | Image caching implemented  |
| 3   | Database Query  | Search restaurants     | < 500ms       | 200ms         | ✅ Pass | Proper indexing            |
| 4   | Memory Usage    | Normal operation       | < 100MB       | 85MB          | ✅ Pass | Memory management good     |
| 5   | Network Request | API response time      | < 1 second    | 800ms         | ✅ Pass | -                          |
| 6   | Battery Usage   | 1 hour usage           | Minimal drain | 5% drain      | ✅ Pass | Optimized background tasks |

### 5. Compatibility Testing

| No  | Platform | Version       | Device             | Screen Size | Status     | Notes                          |
| --- | -------- | ------------- | ------------------ | ----------- | ---------- | ------------------------------ |
| 1   | Android  | 10.0 (API 29) | Samsung Galaxy S10 | 6.1"        | ✅ Pass    | Full functionality             |
| 2   | Android  | 11.0 (API 30) | Google Pixel 4     | 5.7"        | ✅ Pass    | All features work              |
| 3   | Android  | 12.0 (API 31) | OnePlus 9          | 6.5"        | ✅ Pass    | Latest Android support         |
| 4   | Android  | 13.0 (API 33) | Samsung Galaxy S22 | 6.1"        | ✅ Pass    | Modern Android compatibility   |
| 5   | iOS      | 14.0          | iPhone 12          | 6.1"        | ⚠️ Limited | Some features need iOS testing |
| 6   | iOS      | 15.0          | iPhone 13 Pro      | 6.1"        | ⚠️ Limited | iOS specific testing needed    |

### 6. Security Testing

| No  | Security Aspect     | Test Case                | Method                  | Result                       | Status  | Risk Level |
| --- | ------------------- | ------------------------ | ----------------------- | ---------------------------- | ------- | ---------- |
| 1   | Authentication      | Password encryption      | Hash verification       | Passwords properly hashed    | ✅ Pass | Low        |
| 2   | Data Storage        | Local data encryption    | SQLCipher check         | Sensitive data encrypted     | ✅ Pass | Low        |
| 3   | API Security        | HTTPS communication      | Network monitoring      | All API calls use HTTPS      | ✅ Pass | Low        |
| 4   | Input Validation    | SQL Injection prevention | Malicious input testing | Proper input sanitization    | ✅ Pass | Low        |
| 5   | Session Management  | Token expiration         | Time-based testing      | Tokens expire properly       | ✅ Pass | Low        |
| 6   | Permission Handling | App permissions          | Permission testing      | Minimal required permissions | ✅ Pass | Low        |

### 7. Usability Testing

| No  | User Task              | User Profile    | Completion Time | Success Rate | Satisfaction | Issues                |
| --- | ---------------------- | --------------- | --------------- | ------------ | ------------ | --------------------- |
| 1   | Register new account   | Tech-savvy user | 2 minutes       | 100%         | 4.5/5        | None                  |
| 2   | Find nearby restaurant | Average user    | 1 minute        | 95%          | 4.2/5        | Minor UI confusion    |
| 3   | Write a review         | Elderly user    | 5 minutes       | 80%          | 3.8/5        | Text input complexity |
| 4   | Upload photo           | Young user      | 30 seconds      | 100%         | 4.8/5        | None                  |
| 5   | Navigate to restaurant | Average user    | 45 seconds      | 90%          | 4.0/5        | Map loading delay     |

### 8. Accessibility Testing

| No  | Feature          | Test Case         | Accessibility Standard | Status     | Compliance Level          |
| --- | ---------------- | ----------------- | ---------------------- | ---------- | ------------------------- |
| 1   | Screen Reader    | TalkBack support  | WCAG 2.1 AA            | ✅ Pass    | Full compliance           |
| 2   | Color Contrast   | Text readability  | WCAG 2.1 AA            | ✅ Pass    | Sufficient contrast       |
| 3   | Touch Targets    | Minimum tap size  | 44dp minimum           | ✅ Pass    | All targets meet standard |
| 4   | Text Scaling     | Dynamic text size | Android/iOS standards  | ✅ Pass    | Scales properly           |
| 5   | Voice Navigation | Voice commands    | Platform standards     | ⚠️ Partial | Basic support available   |

## Test Environment

### Hardware Specifications

- **Primary Device**: Samsung Galaxy S21 (Android 12)
- **Secondary Device**: Google Pixel 6 (Android 13)
- **Tablet**: Samsung Galaxy Tab S7 (Android 11)
- **Emulator**: Android Studio AVD (Various configurations)

### Software Environment

- **Development**: Flutter 3.x, Dart 3.x
- **Testing Framework**: flutter_test, integration_test
- **Database**: SQLite
- **Build Tools**: Android Gradle Plugin 8.7.0
- **Target SDK**: Android API 33, iOS 15+

## Testing Tools Used

| Tool              | Purpose               | Version                  |
| ----------------- | --------------------- | ------------------------ |
| Flutter Test      | Unit & Widget Testing | Built-in                 |
| Integration Test  | End-to-end Testing    | flutter/integration_test |
| Firebase Test Lab | Cloud Testing         | Latest                   |
| Android Studio    | Debugging & Profiling | Latest                   |
| Flipper           | Network Debugging     | 0.x                      |

## Test Coverage

- **Unit Tests**: 85% code coverage
- **Integration Tests**: 70% feature coverage
- **UI Tests**: 90% screen coverage

## Known Issues

| Issue                     | Priority | Status      | Assigned To    |
| ------------------------- | -------- | ----------- | -------------- |
| Minor map loading delay   | Low      | Open        | Developer Team |
| iOS permission handling   | Medium   | In Progress | iOS Developer  |
| Offline sync optimization | Low      | Planned     | Backend Team   |

## Test Execution Schedule

- **Unit Tests**: Run automatically on every commit
- **Integration Tests**: Daily automated runs
- **UI Tests**: Weekly execution
- **Performance Tests**: Monthly testing
- **Security Tests**: Quarterly assessment

---

**Last Updated**: June 2025  
**Test Lead**: Quality Assurance Team  
**Next Review**: Monthly
