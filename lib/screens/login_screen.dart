import 'package:flutter/material.dart';
import '../theme.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();

  void _handleLogin() {
    // Logique de sécurité : mot de passe administrateur sécurisé
    if (_passwordController.text == 'Winner@53539706360') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe incorrect'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: AppStyles.glass(opacity: 0.9, radius: 25, borderColor: AppColors.accent.withValues(alpha: 0.3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo "pur" sans décorations circulaires, tel quel.
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/images/Logo_Final.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.videogame_asset, color: AppColors.accent, size: 60),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'WINNER GAME MANAGER',
                style: TextStyle(
                  fontFamily: 'Bahnschrift',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'ACCÈS ADMINISTRATION',
                style: TextStyle(
                  fontFamily: 'Bahnschrift',
                  fontSize: 10,
                  color: AppColors.accent,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Veuillez saisir votre mot de passe pour accéder à la configuration.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSoft),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  filled: true,
                  fillColor: AppColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF05111B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour', style: TextStyle(color: AppColors.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
