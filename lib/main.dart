import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:thermalprint/thermal_print/printing_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:thermalprint/thermal_print/thermal_print.dart';

void main() {
  GetIt.I.registerSingleton<ThermalPrint>(ThermalPrint());
  runApp(const MyApp());
  initializeDateFormatting(
    'id_ID',
    null,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    GetIt.I.call<ThermalPrint>().scanPrinter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Flutter Demo Printing Widget',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListenableBuilder(
        listenable: GetIt.I.call<ThermalPrint>(),
        builder: (context, child) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title:
                    Text(GetIt.I.call<ThermalPrint>().listDevice?[index].name ?? ''),
                subtitle: Text(
                    GetIt.I.call<ThermalPrint>().listDevice?[index].macAdress ?? ''),
                onTap: () {
                  GetIt.I.call<ThermalPrint>().connectPrinter(
                      GetIt.I.call<ThermalPrint>().listDevice![index]);
                },
              );
            },
            itemCount: GetIt.I.call<ThermalPrint>().listDevice?.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrintingScreen()),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.print),
      ),
    );
  }

  List<Map<String, dynamic>> product = [];

  List<String> dummyProduct = ['Javscript Package'];
}
