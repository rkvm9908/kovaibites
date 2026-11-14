# 🍛 Kovai Bites

A full-stack food delivery web app for Coimbatore, built with **Flutter** and **Firebase**.
Customers order food and track deliveries in real time, admins run the business from a
dashboard, and delivery partners apply, get approved and fulfil orders from their own portal.

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00B8D4)
![License](https://img.shields.io/badge/License-MIT-green)

<!-- Add screenshots to /docs and update the paths below -->
<p align="center">
  <img src="docs/home.png" width="30%" alt="Home" />
</p>

---

## ✨ Features

### Customer
- Browse restaurants with filters (veg only, rating 4.0+, under 30 min, open now)
- **Dish-first search**: searching a dish or cuisine shows matching dishes before restaurants
- Category shortcuts, popular dishes and skeleton loading states
- Restaurant pages with image gallery (up to 5 images) and dish galleries (up to 3 images)
- Single-restaurant cart with swipe-to-remove and animated totals
- Checkout with **live location sharing** or map pin picker (typing an address is optional)
- Cash on Delivery
- Real-time order tracking with an animated progress tracker
- Star and comment **reviews for every dish**
- Restaurant map with pins for all restaurants
- In-app notifications that open the relevant screen when tapped
- Profile photo, forgot password and account settings

### Admin
- Dashboard with live revenue, order counts and status breakdown (every card is clickable)
- Order management: accept, prepare, dispatch, deliver or cancel
- Restaurant and menu management (create, edit, delete, stock toggle, open/close)
- Restaurant location editing on a map
- **Delivery partner approvals** with rejection reasons sent to the applicant
- Partner management: view, edit details, remove access, see online status

### Delivery Partner
- Apply from Account settings with vehicle and licence details
- Online/offline toggle with heartbeat presence
- Available and My deliveries tabs, one-tap claim with race-condition protection
- Pickup to drop route card with distance, call and navigation buttons

### Automation
- **Auto-accept**: if a delivery partner is online and the restaurant has not responded
  within 60 seconds, the order is accepted automatically (configurable in `lib/core/config.dart`)

---

## 🧱 Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter (Web), Dart |
| Backend | Firebase Authentication, Cloud Firestore |
| State management | Riverpod |
| Routing | go_router (role-based redirects) |
| Maps | flutter_map + OpenStreetMap, geolocator |
| Images | Cloudinary (unsigned upload preset) |
| UI / motion | Material 3, google_fonts, flutter_animate |
| Hosting | Firebase Hosting |

The project is designed to run entirely on Firebase's **free (Spark) plan**.

---

## 🗂️ Project Structure

```
lib/
├── core/         # theme, design tokens, router, config, deep links
├── models/       # Restaurant, MenuItem, AppOrder, AppUser, Review, ...
├── services/     # Firestore access (auth, orders, admin, delivery, reviews)
├── providers/    # Riverpod providers wrapping the services
├── features/
│   ├── auth/         ├── home/          ├── restaurant/
│   ├── cart/         ├── orders/        ├── map/
│   ├── settings/     ├── notifications/ ├── delivery/
│   └── admin/
└── widgets/      # reusable UI (cards, steppers, skeletons, avatar, ...)
```

---

## 🗄️ Data Model (Firestore)

```
users/{uid}                              name, email, role, isDelivery, photoUrl
restaurants/{id}                         name, cuisine, images[], rating, isOpen, lat, lng, ...
  └─ menu/{itemId}                       name, price, images[], category, isVeg, available
       └─ reviews/{uid}                  rating, comment, userName, createdAt
orders/{id}                              userId, restaurantId, items[], total, status,
                                         address, lat, lng, deliveryBoyId, createdAt
deliveryApplications/{uid}               vehicle, licence, area, status, rejectReason
onlineDelivery/{uid}                     lastSeen (presence heartbeat)
notifications/{id}                       toUid, title, body, route, read, createdAt
```

Order lifecycle: `placed → accepted → preparing → out_for_delivery → delivered` (or `cancelled`).

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel) with web enabled: `flutter config --enable-web`
- A Firebase project (Spark plan is enough)
- A free Cloudinary account

### 1. Clone and install

```bash
git clone https://github.com/YOUR_USERNAME/kovai-bites.git
cd kovai-bites
flutter pub get
```

### 2. Connect Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # select your project and the Web platform
```

In the Firebase console:
1. **Authentication → Sign-in method**: enable **Email/Password**
2. **Firestore Database**: create a database
3. **Firestore → Rules**: paste the contents of `firestore.rules` and publish

### 3. Configure Cloudinary

Create an **unsigned upload preset** (Settings → Upload) and set your values in
`lib/services/cloudinary_service.dart`:

```dart
const _cloudName = 'YOUR_CLOUD_NAME';
const _uploadPreset = 'YOUR_UPLOAD_PRESET';
```

> Never put your Cloudinary API secret in the app. Only the cloud name and an
> unsigned preset are needed. Restrict the preset to image formats and a max file size.

### 4. Create the first admin

1. Run the app and sign up a normal account
2. In Firestore, open `users/{your-uid}` and change `role` from `customer` to `admin`
3. Sign in again and you will be redirected to the admin dashboard

### 5. Run

```bash
flutter run -d chrome
```

### 6. Deploy

```bash
flutter build web
firebase init hosting        # public directory: build/web, single-page app: yes
firebase deploy
```

---

## 🔐 Security

- Role checks (`customer`, `admin`, delivery partner) are enforced by **Firestore Security Rules**,
  not only in the UI
- Users cannot change their own `role` or `isDelivery` flag
- Customers can only read their own orders; delivery partners can only update status and
  assignment fields on orders assigned to them
- Order claiming uses a Firestore transaction to prevent double assignment
- Reviews are limited to one per user per dish with a validated 1 to 5 rating

---

## ⚠️ Known Limitations

- **Auto-accept runs in the browser.** It needs a customer or admin tab to be open. A fully
  server-side version requires Cloud Functions (Blaze plan).
- **Partner presence** is heartbeat-based and requires the delivery dashboard tab to stay open.
- **Order totals are calculated on the client.** Add server-side price verification
  (Cloud Functions) before accepting online payments.
- **Payments:** Cash on Delivery only.
- **Notifications** are in-app only (no push notifications yet).
- **Cloudinary uploads are unsigned**, so the upload preset name is visible in the client.
  Use format and size limits, and move to signed uploads for production.
- OpenStreetMap public tiles are meant for light usage. Switch tile providers if traffic grows.

---

## 🛣️ Roadmap

- [ ] Online payments (Razorpay) with server-side verification
- [ ] Push notifications (FCM)
- [ ] Server-side auto-accept and order validation with Cloud Functions
- [ ] Persistent cart
- [ ] Reviews restricted to delivered orders
- [ ] Coupons and offers
- [ ] Custom branded password-reset emails
- [ ] Analytics and earnings reports for delivery partners

---

## 🤝 Contributing

Contributions are welcome. Please open an issue first to discuss major changes, then submit
a pull request.

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

## 👤 Author

**Your Name**
GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
