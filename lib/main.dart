import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter/material.dart';
import 'package:panoply/services/news_service.dart';
import 'package:panoply/services/nntp_server.dart';
import 'package:panoply/views/headers.dart';
import 'package:panoply/views/server_status.dart';
import 'package:provider/provider.dart';

import 'blocs/overviews_bloc.dart';

void main() {
  Loggy.initLoggy();

  runApp(
      MultiBlocProvider(
          providers: [
            BlocProvider<NewsService>(
                create: (context) => NewsService(NntpServer('aioe', 'nntp.aioe.org'))
            ),
            BlocProvider<OverviewsBloc>(
                create: (context) => OverviewsBloc()
            ),
          ],
          child: const MyApp()),
  );
}

const kBodyEdgeInsets = 10.0;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panoply',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Groups'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with UiLoggy {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Widget _buildSubscriptionItem(String name) {
    return ListTile(
      title: Text(name,),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HeaderList(group:name))
        );
      },
    );
  }

  List<Widget> _buildSubscriptionList(BuildContext context) {
    return <Widget>[
      _buildSubscriptionItem('aioe.system'),
      _buildSubscriptionItem('alt.free.newsservers'),
      _buildSubscriptionItem('alt.test'),
      _buildSubscriptionItem('rec.outdoors.rv-travel'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(kBodyEdgeInsets),
        child: ListView(
            children: _buildSubscriptionList(context),
        ),
      ),
      bottomSheet: Container(
          padding: const EdgeInsets.all(kBodyEdgeInsets),
          child: const ServerStatus(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
