import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold, FloatingActionButton, Icons;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'transaction_model.dart';
import 'OrderTrackingScreen.dart';
import 'MapPickerScreen.dart';

// FOOD PANDA THEME COLORS
const Color kPandaPink = Color(0xFFD70F64);
const Color kPandaWhite = Color(0xFFFFFFFF);
const Color kPandaGrey = Color(0xFFF7F7F7);
const Color kPandaDark = Color(0xFF333333);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionHistoryAdapter());
  await Hive.openBox("database");
  await Hive.openBox("todoBox");
  await Hive.openBox<TransactionHistory>("historyBox");
  await Hive.openBox('transactions');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, widget) {
        bool isDark = box.get("isDark") ?? false; // Default to Light for FoodPanda look

        return CupertinoApp(
          theme: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: kPandaPink,
            scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : kPandaGrey,
            barBackgroundColor: isDark ? const Color(0xFF1F1F1F) : kPandaWhite,
          ),
          debugShowCheckedModeBanner: false,
          home: (box.get("username") == null) ? const Signup() : const Homepage(),
        );
      },
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final LocalAuthentication auth = LocalAuthentication();
  final box = Hive.box("database");
  bool hidePassword = true;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  Future<void> authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        biometricOnly: true,
      );
      if (didAuthenticate) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const RobuxStoreMain()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK", style: TextStyle(color: kPandaPink)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = box.get("isDark") ?? false;
    Color textColor = isDark ? kPandaWhite : kPandaDark;
    Color inputBgColor = isDark ? const Color(0xFF2C2C2C) : kPandaWhite;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FOODPANDA STYLE ICON
              const Icon(CupertinoIcons.bag_fill, size: 80, color: kPandaPink),
              const SizedBox(height: 10),
              const Text("foodpanda",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: kPandaPink)
              ),
              const SizedBox(height: 40),
              CupertinoTextField(
                  controller: _username,
                  placeholder: "Email or Phone Number",
                  style: TextStyle(color: textColor),
                  decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey4)
                  ),
                  padding: const EdgeInsets.all(16)
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _password,
                placeholder: "Password",
                style: TextStyle(color: textColor),
                obscureText: hidePassword,
                decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemGrey4)
                ),
                padding: const EdgeInsets.all(16),
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: Colors.grey),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: kPandaPink,
                  borderRadius: BorderRadius.circular(8),
                  child: const Text('Log In',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  onPressed: () {
                    if (_username.text.trim() == box.get("username") && _password.text.trim() == box.get("password")) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        CupertinoPageRoute(builder: (context) => const RobuxStoreMain()),
                            (route) => false,
                      );
                    } else {
                      _showAlert("Login Error", "Invalid account details");
                    }
                  },
                ),
              ),
              const SizedBox(height: 15),
              if (box.get("biometrics") ?? false)
                CupertinoButton(
                    child: const Icon(Icons.fingerprint, size: 50, color: kPandaPink),
                    onPressed: authenticate
                ),
              CupertinoButton(
                child: const Text("Reset App Data", style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("Reset App?"),
                      content: const Text("This will erase all your local data including transaction history."),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () async {
                            await box.clear();
                            await Hive.box("todoBox").clear();
                            await Hive.box<TransactionHistory>("historyBox").clear();
                            await Hive.box('transactions').clear();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(builder: (context) => const Signup())
                              );
                            }
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Signup extends StatefulWidget {
  const Signup({super.key});
  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final box = Hive.box("database");
  final TextEditingController _u = TextEditingController();
  final TextEditingController _p = TextEditingController();

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK", style: TextStyle(color: kPandaPink)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kPandaPink,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.person_add_solid, size: 60, color: kPandaWhite),
              const SizedBox(height: 20),
              const Text("Join foodpanda",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPandaWhite)
              ),
              const SizedBox(height: 30),
              CupertinoTextField(
                  controller: _u,
                  placeholder: "Username",
                  placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
                  decoration: BoxDecoration(color: kPandaWhite, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(16)
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                  controller: _p,
                  placeholder: "Password (Min. 8 characters)",
                  placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
                  obscureText: true,
                  decoration: BoxDecoration(color: kPandaWhite, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(16)
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: kPandaDark,
                  borderRadius: BorderRadius.circular(8),
                  child: const Text("Create Account",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  onPressed: () {
                    String user = _u.text.trim();
                    String pass = _p.text.trim();
                    if (user.isEmpty || pass.isEmpty) {
                      _showAlert("Error", "Please fill in all fields.");
                    } else if (pass.length < 8) {
                      _showAlert("Error", "Password too short.");
                    } else {
                      box.put("username", user);
                      box.put("password", pass);
                      box.put("biometrics", false);
                      box.put("isDark", false);
                      box.put("balance", 0);
                      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const Homepage()));
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RobuxStoreMain extends StatefulWidget {
  const RobuxStoreMain({super.key});
  @override
  State<RobuxStoreMain> createState() => _RobuxStoreMainState();
}

class _RobuxStoreMainState extends State<RobuxStoreMain> {
  final box = Hive.box("database");
  final todoBox = Hive.box("todoBox");
  final String secretKey = "xnd_development_eK78SFIvggTwLxrFpMVLLP0oh9U4fls1lt6Iszi3QFvXKhcdxqzIpuXw3007WxT";

  Future<void> payNow(BuildContext context, int price, int amount) async {
    showCupertinoDialog(
        context: context,
        builder: (context) => const CupertinoAlertDialog(
          title: Text("Preparing Order..."),
          content: Padding(padding: EdgeInsets.only(top: 10), child: CupertinoActivityIndicator()),
        ));

    try {
      String authHeader = 'Basic ${base64Encode(utf8.encode("$secretKey:"))}';
      final response = await http.post(Uri.parse("https://api.xendit.co/v2/invoices/"),
          headers: {"Authorization": authHeader, "Content-Type": "application/json"},
          body: jsonEncode({
            "external_id": "inv_${DateTime.now().millisecondsSinceEpoch}",
            "amount": price,
            "currency": "PHP"
          }));

      final data = jsonDecode(response.body);
      String id = data['id'];
      String invoiceUrl = data['invoice_url'];

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => PaymentPage(url: invoiceUrl)));

      _startStatusCheck(authHeader, id, amount, price);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error: $e");
    }
  }

  void _startStatusCheck(String auth, String id, int amount, int price) {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final response = await http.get(
          Uri.parse("https://api.xendit.co/v2/invoices/$id"),
          headers: {"Authorization": auth},
        );
        final data = jsonDecode(response.body);

        if (data["status"] == "PAID") {
          timer.cancel();
          final historyBox = Hive.box<TransactionHistory>("historyBox");
          await historyBox.add(TransactionHistory(
            itemName: "$amount Meal Package",
            amount: price.toDouble(),
            date: DateTime.now(),
          ));
          int currentBalance = box.get("balance") ?? 0;
          await box.put("balance", currentBalance + amount);

          if (mounted) {
            // Isara ang anumang loading dialog
            Navigator.of(context, rootNavigator: true).pop();

            // Dadalhin ang user sa Map Picker para sila ang mag-pin ng address
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const MapPickerScreen(),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Check Error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ["balance", "isDark", "biometrics"]),
      builder: (context, Box box, _) {
        int currentBalance = box.get("balance") ?? 0;
        bool isDark = box.get("isDark") ?? false;

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
              activeColor: kPandaPink,
              inactiveColor: CupertinoColors.systemGrey,
              items: const [
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: "Delivery"),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text_fill), label: "Orders"),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "Profile")
              ]
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0: return _buildStoreTab(currentBalance, isDark);
              case 1: return _buildListTab(isDark);
              case 2: return _buildSettingsTab(isDark);
              default: return _buildStoreTab(currentBalance, isDark);
            }
          },
        );
      },
    );
  }

  Widget _buildStoreTab(int currentBalance, bool isDark) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: Text("Food Delivery", style: TextStyle(color: isDark ? kPandaWhite : kPandaDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,

        ),
      ),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: Text("Popular Deals",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? kPandaWhite : kPandaDark)
            ),
          ),
          _listPackage("80", 80, isDark),
          _listPackage("400", 400, isDark),
          _listPackage("800", 800, isDark),
          _listPackage("1700", 1700, isDark),
          _listPackage("3400", 3400, isDark),
          const SizedBox(height: 100),123
        ],
      ),
    );
  }

  Widget _listPackage(String price, int amount, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : kPandaWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$amount Meal Combo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? kPandaWhite : kPandaDark)
              ),
              const Text("Fast Delivery • ₱0 Fee", style: TextStyle(fontSize: 12, color: kPandaPink)),
            ],
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: kPandaPink,
            borderRadius: BorderRadius.circular(20),
            child: Text("₱$price", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () => payNow(context, int.parse(price.replaceAll(',', '')), amount),
          )
        ],
      ),
    );
  }

  Widget _buildListTab(bool isDark) {
    final historyBox = Hive.box<TransactionHistory>("historyBox");
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: Text("Past Orders", style: TextStyle(color: isDark ? kPandaWhite : kPandaDark))
      ),
      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: historyBox.listenable(),
          builder: (context, Box<TransactionHistory> box, _) {
            if (box.isEmpty) return const Center(child: Text("No orders found"));
            return ListView.builder(
              padding: const EdgeInsets.only(top: 15, bottom: 100),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final transaction = box.getAt(box.length - 1 - index);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : kPandaWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(transaction?.itemName ?? "Unknown Item",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${transaction?.date.month}/${transaction?.date.day}/${transaction?.date.year}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text("₱${transaction?.amount.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kPandaPink)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsTab(bool isDark) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: Text("Profile", style: TextStyle(color: isDark ? kPandaWhite : kPandaDark))
      ),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          CupertinoListSection.insetGrouped(
            children: [
              CupertinoListTile(
                title: const Text("Dark Mode"),
                leading: const Icon(CupertinoIcons.moon_fill, color: Colors.indigo),
                trailing: CupertinoSwitch(value: isDark, onChanged: (v) => box.put("isDark", v)),
              ),
              CupertinoListTile(
                title: const Text("Biometric Authentication"),
                leading: const Icon(Icons.fingerprint, color: kPandaPink),
                trailing: CupertinoSwitch(
                  value: box.get("biometrics") ?? false,
                  onChanged: (v) => box.put("biometrics", v),
                ),
              ),
              CupertinoListTile(
                title: const Text("Logout", style: TextStyle(color: kPandaPink)),
                leading: const Icon(CupertinoIcons.square_arrow_right, color: kPandaPink),
                onTap: () {
                  // Ibinabalik natin ang Confirmation Dialog dito
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("Sign Out"),
                      content: const Text("Are you sure you want to sign out?"),
                      actions: [
                        // CHOICE 1: CANCEL
                        CupertinoDialogAction(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // CHOICE 2: YES
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text("Yes"),
                          onPressed: () {
                            Navigator.pop(context); // Isara ang dialog
                            Navigator.pushAndRemoveUntil(
                              context,
                              CupertinoPageRoute(builder: (context) => const Homepage()),
                                  (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  final String url;
  const PaymentPage({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Checkout")),
      child: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}