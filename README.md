# TrueWay eCommerce App

Welcome to the **TrueWay eCommerce App**, a fully functional Flutter-based eCommerce application integrated with the WooCommerce API. This project supports user authentication, product browsing, cart management, order placement, and order tracking.

## 📌 Features
- User Authentication (Login, Signup, Logout)
- Fetch Products from WooCommerce API
- Category-wise Product Listing
- Product Details with Add to Cart
- Cart Management (Add/Remove Items, Checkout)
- Order Processing and History
- Order Details View
- Persistent Bottom Navigation Bar

## 🛠 Tech Stack
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Backend:** WooCommerce API
- **Networking:** HTTP Package

## 🚀 Installation & Setup

### 1️⃣ Prerequisites
Ensure you have Flutter installed. If not, install it from [Flutter Official Site](https://flutter.dev/docs/get-started/install).

### 2️⃣ Clone the Repository
```sh
git clone https://github.com/rutviknakum/trueway_ecommerce.git
cd trueway_ecommerce
```

### 3️⃣ Install Dependencies
```sh
flutter pub get
```

### 4️⃣ Setup WooCommerce API
Update the `lib/services/config.dart` file with your WooCommerce API keys.

```dart
class Config {
  static const String baseUrl = "https://your-woocommerce-site.com/wp-json/wc/v3";
  static const String consumerKey = "your_consumer_key";
  static const String consumerSecret = "your_consumer_secret";
}
```

### 5️⃣ Run the App
```sh
flutter run
```

## 📡 API Integration
- **Products:** `GET /products`
- **Categories:** `GET /products/categories`
- **Orders:** `POST /orders`
- **Order History:** `GET /orders?customer={customer_id}`



## 📜 License
This project is licensed under the MIT License.

## 🤝 Contributing
Feel free to fork this project and submit pull requests to improve functionality!

## 🔗 Contact
- **Developer:** Rutvik B. Nakum  
- **LinkedIn:** [linkedin.com/in/rutvik-b-nakum-376707237](https://www.linkedin.com/in/rutvik-b-nakum-376707237/)  
- **Skype:** [Join Skype](https://join.skype.com/invite/wJbX1JjBwxZP)

