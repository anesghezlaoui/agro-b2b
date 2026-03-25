import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/phone_utils.dart';
import 'auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('AgroB2B - Connexion')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Nom obligatoire'
                            : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (10 chiffres, ex. 0555123456)',
                    hintText: 'Espaces acceptés',
                  ),
                  validator: (value) => isValidLocalPhone10(value ?? '')
                      ? null
                      : '10 chiffres requis (ex. 0555123456)',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Minimum 6 caractères'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;
                    bool ok;
                    final phoneDigits = digitsOnlyPhone(_phoneController.text);
                    if (_isLogin) {
                      ok = await auth.login(
                        phone: phoneDigits,
                        password: _passwordController.text,
                      );
                    } else {
                      ok = await auth.register(
                        name: _nameController.text,
                        phone: phoneDigits,
                        password: _passwordController.text,
                      );
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? (_isLogin
                                  ? 'Connexion réussie'
                                  : 'Compte créé: en attente de validation admin')
                              : (auth.errorMessage ?? 'Vérifie les champs'),
                        ),
                      ),
                    );
                  },
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'Se connecter' : "S'inscrire"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Pas de compte ? S'inscrire"
                        : 'Déjà un compte ? Se connecter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
