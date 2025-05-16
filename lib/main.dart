import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/features/chat/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/data/data_sources/local/hive_chat_repository.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'common/extensions/custom_theme_extension.dart';
import 'common/routes/routes.dart';
import 'common/themes/theme_provider.dart';
import 'features/splash/pages/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  Hive
    ..init(dir.path)
    ..registerAdapter(MessageModelAdapter())
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageStatusAdapter());

  // await HiveChatRepository.instance.clearAllMessages();
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
          create:
              (context) =>
                  ChatItemBloc(appwriteRepository: AppwriteRepository())
                    ..add(GetChatItemEvent()),
        ),
      ],
      child: MaterialApp(
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
