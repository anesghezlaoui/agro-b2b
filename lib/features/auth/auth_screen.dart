import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/support_contact.dart';
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

  Future<void> _openUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF0E7A36),
                        child: Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 34),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'AgroB2B',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Votre grossiste digital, simple et rapide',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3EA)),
                  ),
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
                      if (!_isLogin) const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Mot de passe'),
                        validator: (value) =>
                            (value == null || value.length < 6)
                                ? 'Minimum 6 caractères'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  bool ok;
                                  final phoneDigits =
                                      digitsOnlyPhone(_phoneController.text);
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
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(auth.errorMessage ??
                                            'Vérifie les champs'),
                                      ),
                                    );
                                  } else if (_isLogin) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Connexion réussie')),
                                    );
                                  }
                                },
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isLogin
                                  ? 'Se connecter'
                                  : 'Créer un compte'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? "Pas de compte ? Créer un compte"
                              : 'Déjà un compte ? Se connecter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Commandez en quelques secondes, sans déplacement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const _AdvantageLine(
                    icon: Icons.flash_on_rounded, text: 'Commande rapide'),
                const _AdvantageLine(
                    icon: Icons.inventory_2_rounded,
                    text: 'Large choix produits'),
                const _AdvantageLine(
                    icon: Icons.savings_rounded, text: 'Prix distributeur'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3EA)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Un conseiller vous accompagne',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () =>
                                  _openUri(SupportContact.whatsappUri),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('Besoin d’aide'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openUri(SupportContact.phoneUri),
                              icon: const Icon(Icons.phone_rounded),
                              label: const Text('Appel direct'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _AdvantageLine extends StatelessWidget {
  const _AdvantageLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0E7A36)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
