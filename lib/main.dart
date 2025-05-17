import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/common/services/notification_service.dart';
import 'package:messenger_clone/features/chat/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'common/extensions/custom_theme_extension.dart';
import 'common/routes/routes.dart';
import 'common/themes/theme_provider.dart';
import 'features/meta_ai/bloc/meta_ai_bloc.dart';
import 'features/meta_ai/bloc/meta_ai_event.dart';
import 'features/meta_ai/data/meta_ai_message_hive.dart';
import 'features/splash/pages/splash.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dir = await getApplicationDocumentsDirectory();
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  NotificationService().initializeNotifications();
  NotificationService().setNavigatorKey(navigatorKey);
  Hive
    ..init(dir.path)
    ..registerAdapter(MessageModelAdapter())
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageStatusAdapter());

  await MetaAiServiceHive.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MessengerClone(),
    ),
  );
}

class MessengerClone extends StatefulWidget {
  const MessengerClone({super.key});

  @override
  State<MessengerClone> createState() => _MessengerCloneState();
}

class _MessengerCloneState extends State<MessengerClone> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) =>
            MetaAiBloc()
              ..add(InitializeMetaAi())),
        BlocProvider(
          create:
              (context) =>
          ChatItemBloc(appwriteRepository: AppwriteRepository())
            ..add(GetChatItemEvent()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeNotifier.value,
        onGenerateRoute: Routes.onGenerateRoute,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}
