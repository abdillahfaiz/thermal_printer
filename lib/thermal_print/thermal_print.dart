// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class ThermalPrint with ChangeNotifier {
  ThermalPrint({
    this.listDevice,
    this.selectedMacAddress,
    this.connectionStatus,
  });

  List<BluetoothInfo>? listDevice = [];
  String? selectedMacAddress = '';
  bool? connectionStatus = false;

  Future<void> scanPrinter({String? initialMacAddress = ''}) async {
    bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (isBluetoothEnabled) {
      List<BluetoothInfo> result = await PrintBluetoothThermal.pairedBluetooths;
      listDevice = result;
      if (initialMacAddress!.isNotEmpty) {
        for (BluetoothInfo device in result) {
          if (device.macAdress == initialMacAddress) {
            selectedMacAddress = initialMacAddress;
          }
        }
        connectionStatus = await PrintBluetoothThermal.connect(
            macPrinterAddress: selectedMacAddress!);
      }
      notifyListeners();
    } else {
      throw Exception('Bluetooth is not enabled');
    }
  }

  Future<void> connectPrinter(BluetoothInfo device) async {
    try {
      connectionStatus = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress);
    } catch (e) {
      throw Exception('Failed to connect to printer');
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      await PrintBluetoothThermal.disconnect;
      connectionStatus = false;
    } catch (e) {
      throw Exception('Failed to disconnect from printer');
    }
  }

  Future<void> printTicket({
    List<int>? ticket = const [],
    bool? useTicketTemplate = false,
    TicketTemplate? template,
  }) async {
    try {
      if (useTicketTemplate!) {
        if (template == null) {
          throw Exception('Template is required if useTicketTemplate is true');
        }
        ticket = template.build();
      }
      await PrintBluetoothThermal.writeBytes(ticket ?? []);
    } catch (e) {
      throw Exception('Failed to print ticket');
    }
  }
}

class TicketTemplate {
  final List<int> header;
  final List<int> profile;
  final List<int> data;
  final List<int> footer;
  TicketTemplate({
    required this.header,
    required this.profile,
    required this.data,
    required this.footer,
  });

  List<int> build() {
    final List<int> ticket = [];
    ticket.addAll(header);
    ticket.addAll(profile);
    ticket.addAll(data);
    ticket.addAll(footer);
    return ticket;
  }
}
