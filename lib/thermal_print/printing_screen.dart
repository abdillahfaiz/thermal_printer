import 'dart:developer';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrintingScreen extends StatefulWidget {
  const PrintingScreen({super.key});

  @override
  State<PrintingScreen> createState() => _PrintingScreenState();
}

class _PrintingScreenState extends State<PrintingScreen> {
  final TextEditingController qtyValue = TextEditingController();
  List<BluetoothInfo> devicesList = [];
  List<TotalProduct> finalProduct = [];
  String? errMsg;
  BluetoothInfo? selectedDevice;
  String formattedDate =
      DateFormat('dd MMMM yyyy, kk:mm', 'id').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    initPrinter();
  }

  Future<void> initPrinter() async {
    if (await PrintBluetoothThermal.bluetoothEnabled) {
      final List<BluetoothInfo> result =
          await PrintBluetoothThermal.pairedBluetooths;
          
      setState(() {
        devicesList = result;
      });

      for (var x in result) {
        log('Device Name: ${x.name}, Device MAC: ${x.macAdress}');
      }
    } else {
      setState(() {
        errMsg = 'Aktfikan Bluetooth Anda';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Print'),
      ),
      body: errMsg != null
          ? Center(
              child: Text(errMsg!),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final BluetoothInfo device = devicesList[index];
                      return ListTile(
                        title: Text(
                          device.name,
                          style: TextStyle(
                              color: selectedDevice == device
                                  ? Colors.blue
                                  : Colors.black),
                        ),
                        subtitle: Text(
                          device.macAdress,
                          style: TextStyle(
                              color: selectedDevice == device
                                  ? Colors.blue
                                  : Colors.black),
                        ),
                        onTap: () async {
                          bool isConnected = false;
                          isConnected =
                              await PrintBluetoothThermal.connectionStatus;
                          bool connectSuccess = false;
                          try {
                            if (isConnected) {
                              await PrintBluetoothThermal.disconnect;
                              connectSuccess =
                                  await PrintBluetoothThermal.connect(
                                      macPrinterAddress: device.macAdress);
                            } else {
                              connectSuccess =
                                  await PrintBluetoothThermal.connect(
                                      macPrinterAddress: device.macAdress);
                            }
                          } catch (e) {}
                          setState(() {
                            selectedDevice = device;
                          });
                          if (connectSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Berhasil terhubung ke printer',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'gagal terhubung ke printer',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool connected =
                              await PrintBluetoothThermal.connectionStatus;
                          if (!context.mounted) return;
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih perangkat terlebih dahulu',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            await printTest().whenComplete(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Print berhasil',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue),
                        ),
                        child: const Text(
                          'Print',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: kToolbarHeight * 3),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: qtyValue,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan jumlah produk',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> printTest() async {
    setState(() {
      finalProduct = List.generate(int.parse(qtyValue.text),
          (i) => TotalProduct(name: 'product_$i', price: 100000, qty: 1));
    });
    bool conecctionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conecctionStatus) {
      try {
        List<int> ticket = await printTicket();
        await PrintBluetoothThermal.writeBytes(ticket);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        errMsg = 'Gagal terhubung ke printer';
      });
    }
  }

  PosTransaction transaction = PosTransaction(
    storeName: 'PT INOVASI KARYA RESMAN',
    storeAddress:
        'Jl. Podomoro Park Cluster Padmagriya 3 No.5, Lengkong, Kec. Bojongsoang,\nKabupaten Bandung, Jawa Barat 40287',
    cashier: 'Abdillah Faiz',
    paymentType: 'Tunai',
    totalPay: 500000,
    receiptNumber: 32365736582,
  );

  String idrFormatter(int price) {
    final f = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return f.format(price);
  }

  int total() {
    int total = 0;
    for (var i = 0; i < finalProduct.length; i++) {
      var item = finalProduct[i];
      total = total + (item.price * item.qty);
    }
    return total;
  }

  Future<List<int>> printTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.setGlobalFont(PosFontType.fontB);
    bytes += generator.reset();

    bytes += generator.text(
      transaction.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.text(
      transaction.storeAddress,
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
      linesAfter: 1,
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(
        align: PosAlign.left,
        bold: false,
        fontType: PosFontType.fontA,
        height: PosTextSize.size1,
      ),
    );
    bytes += generator.text(
      'Kasir : ${transaction.cashier}',
      styles: const PosStyles(
        align: PosAlign.left,
      ),
    );
    bytes += generator.text(
      'Waktu : ${DateFormat('dd MMMM yyyy, kk:mm', 'id').format(DateTime.now())}',
      styles: const PosStyles(
        align: PosAlign.left,
      ),
    );
    bytes += generator.text(
      'No. Struk : ${transaction.receiptNumber}',
      styles: const PosStyles(
        align: PosAlign.left,
      ),
    );
    bytes += generator.text(
      'Bayar : ${transaction.paymentType}',
      styles: const PosStyles(
        align: PosAlign.left,
      ),
    );

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(
        align: PosAlign.left,
        bold: false,
        fontType: PosFontType.fontA,
        height: PosTextSize.size1,
      ),
    );

    for (var i = 0; i < finalProduct.length; i++) {
      var item = finalProduct[i];

      bytes += generator.text(
        item.name,
        styles: const PosStyles(
          align: PosAlign.left,
          fontType: PosFontType.fontB,
        ),
      );
      bytes += generator.row([
        PosColumn(
          text: '${idrFormatter(item.price)} x ${item.qty}',
          width: 8,
          styles: const PosStyles(
              align: PosAlign.left,
              underline: false,
              fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: (idrFormatter(item.price * item.qty)),
          width: 4,
          styles: const PosStyles(
              align: PosAlign.right,
              underline: false,
              fontType: PosFontType.fontB),
        ),
      ]);
    }
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(
        align: PosAlign.left,
        bold: false,
        fontType: PosFontType.fontA,
        height: PosTextSize.size1,
      ),
    );
    bytes += generator.row([
      PosColumn(
        text: 'Subtotal',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            underline: false,
            fontType: PosFontType.fontB),
      ),
      PosColumn(
        text: idrFormatter(total()),
        width: 8,
        styles: const PosStyles(
            align: PosAlign.right,
            underline: false,
            fontType: PosFontType.fontB),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Total',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            underline: false,
            fontType: PosFontType.fontB),
      ),
      PosColumn(
        text: idrFormatter(total()),
        width: 8,
        styles: const PosStyles(
            align: PosAlign.right,
            underline: false,
            fontType: PosFontType.fontB),
      ),
    ]);
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(
        align: PosAlign.left,
        bold: false,
        height: PosTextSize.size1,
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.row([
      PosColumn(
        text: 'Bayar',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            underline: false,
            fontType: PosFontType.fontB),
      ),
      PosColumn(
        text: idrFormatter(transaction.totalPay),
        width: 8,
        styles: const PosStyles(
            align: PosAlign.right,
            underline: false,
            fontType: PosFontType.fontB),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Kembali',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            underline: false,
            fontType: PosFontType.fontB),
      ),
      PosColumn(
        text: idrFormatter(transaction.totalPay - total()),
        width: 8,
        styles: const PosStyles(
            align: PosAlign.right,
            underline: false,
            fontType: PosFontType.fontB),
      ),
    ]);

    bytes += generator.text(
      '',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: false,
        fontType: PosFontType.fontB,
      ),
    );

    bytes += generator.qrcode(
      'https://inkare.co.id/',
      size: QRSize.Size8,
    );
    bytes += generator.text(
      '',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: false,
        fontType: PosFontType.fontB,
      ),
      linesAfter: 1,
    );

    bytes += generator.text(
      'Powered by INKARE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: false,
        fontType: PosFontType.fontB,
      ),
      linesAfter: 1,
    );
    return bytes;
  }
}

class PosTransaction {
  final String storeName, storeAddress, cashier, paymentType;
  final int totalPay, receiptNumber;

  PosTransaction({
    required this.cashier,
    required this.storeAddress,
    required this.storeName,
    required this.paymentType,
    required this.totalPay,
    required this.receiptNumber,
  });
}

class TotalProduct {
  final String name;
  final int price;
  final int qty;

  TotalProduct({
    required this.name,
    required this.price,
    required this.qty,
  });
}
