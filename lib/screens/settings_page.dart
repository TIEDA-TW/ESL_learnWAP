import 'package:flutter/material.dart';
import 'package:english_learning_app/services/auth_service.dart';
import 'package:english_learning_app/routes/app_routes.dart';
// Import LoginFormScreen if direct navigation is needed and not solely relying on AppRoutes.getRoutes
// import 'package:english_learning_app/screens/login_form_screen.dart'; 

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); 
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.lock_outline, color: theme.colorScheme.secondary),
            title: Text('Change Password', style: theme.textTheme.titleMedium),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.changePassword);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Logout', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onTap: () async {
              await authService.signOut();
              // Navigate to login screen and remove all previous routes
              // Ensuring the login route exists in AppRoutes.getRoutes(context)
              final routes = AppRoutes.getRoutes(context);
              final loginPageRouteFactory = routes[AppRoutes.login];
              
              if (loginPageRouteFactory != null) {
                 Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: loginPageRouteFactory), // Use the factory
                    (Route<dynamic> route) => false, 
                  );
              } else {
                // Fallback or error handling if login route is not defined
                print("Error: Login route not found in AppRoutes");
                // Potentially navigate to a default screen or show an error
              }
            },
          ),
          // TODO: Add other settings like theme selection, language, etc.
        ],
      ),
    );
  }
}
