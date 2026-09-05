import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_root_navigator.dart';
import 'package:vidxon_admin/features/admin_locale/application/admin_locale_controller.dart';
import 'package:vidxon_admin/features/admin_locale/domain/admin_ui_locales.dart';
import 'package:vidxon_admin/features/admin_locale/presentation/admin_locale_scope.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeController = AdminLocaleController();
  await localeController.load();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(MissingConfigurationApp(localeController: localeController));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(VidxonAdminApp(localeController: localeController));
}

class MissingConfigurationApp extends StatelessWidget {
  const MissingConfigurationApp({required this.localeController, super.key});

  final AdminLocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeController.locale,
          supportedLocales: AdminUiLocales.supportedLocales,
          localeResolutionCallback: (_, _) => localeController.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.missingSupabaseConfig,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class VidxonAdminApp extends StatelessWidget {
  const VidxonAdminApp({required this.localeController, super.key});

  final AdminLocaleController localeController;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE50914);

    return AdminLocaleScope(
      controller: localeController,
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Vidxon Admin',
            debugShowCheckedModeBanner: false,
            locale: localeController.locale,
            supportedLocales: AdminUiLocales.supportedLocales,
            localeResolutionCallback: (_, _) => localeController.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF090909),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF181818),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;

    _session = auth.currentSession;

    _authSubscription = auth.onAuthStateChange.listen((authState) {
      if (!mounted) {
        return;
      }

      setState(() {
        _session = authState.session;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    if (session == null) {
      return const AdminLoginPage();
    }

    return AdminAuthorizationGate(
      key: ValueKey(session.user.id),
      userId: session.user.id,
      email: session.user.email ?? '',
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'ibrahim@vidxon.com');
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.loginUnexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.appBrand,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Color(0xFFE50914),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.adminPanel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFB3B3B3),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return context.l10n.emailRequired;
                          }

                          if (!email.contains('@')) {
                            return context.l10n.emailInvalid;
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: context.l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.l10n.passwordRequired;
                          }

                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE50914,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFE50914,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFFFB4B4)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.l10n.signIn,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminAuthorizationGate extends StatefulWidget {
  const AdminAuthorizationGate({
    required this.userId,
    required this.email,
    this.adminCheckOverride,
    super.key,
  });

  final String userId;
  final String email;
  final Future<bool> Function()? adminCheckOverride;

  @override
  State<AdminAuthorizationGate> createState() => _AdminAuthorizationGateState();
}

class _AdminAuthorizationGateState extends State<AdminAuthorizationGate> {
  late Future<bool> _adminCheck;

  @override
  void initState() {
    super.initState();
    _adminCheck = _checkAdminAccess();
  }

  Future<bool> _checkAdminAccess() async {
    final override = widget.adminCheckOverride;
    if (override != null) {
      return override();
    }

    final result = await Supabase.instance.client.rpc('is_admin');
    return result == true;
  }

  void _retry() {
    setState(() {
      _adminCheck = _checkAdminAccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AccessMessagePage(
            icon: Icons.error_outline,
            title: context.l10n.authorizationFailed,
            message: snapshot.error.toString(),
            actionLabel: context.l10n.retry,
            onAction: _retry,
          );
        }

        if (snapshot.data != true) {
          return const AccessDeniedPage();
        }

        return AdminContextLoader(
          key: ValueKey(widget.userId),
          child: AdminRootNavigator(email: widget.email),
        );
      },
    );
  }
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessMessagePage(
      icon: Icons.admin_panel_settings_outlined,
      title: context.l10n.accessDenied,
      message: context.l10n.accessDeniedMessage,
      actionLabel: context.l10n.signOut,
      onAction: () async {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      },
    );
  }
}

class AccessMessagePage extends StatelessWidget {
  const AccessMessagePage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: const Color(0xFFE50914)),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
