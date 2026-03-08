import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<bool> sendInvoice({
    required String phoneNumber,
    required String customerName,
    required String transactionCode,
    required double totalAmount,
  }) async {
    // Format ke nomor internasional untuk API WA (Misal dari 0812 ke 62812)
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    final message =
        '''
Halo Kak *$customerName*,
Terima kasih telah menggunakan layanan kami.

Nomor Nota: *$transactionCode*
Total Tagihan: *Rp${totalAmount.toInt()}*

Silakan simpan nomor ini untuk pengecekan status cucian Anda.
Terima kasih! 🙏
''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> sendStatusUpdate({
    required String phoneNumber,
    required String customerName,
    required String transactionCode,
    required String status,
  }) async {
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    String statusText = '';
    if (status == 'READY') {
      statusText = 'sudah SELESAI dan SIAP DIAMBIL';
    } else if (status == 'PICKED_UP') {
      statusText = 'telah DIAMBIL. Terima kasih!';
    } else {
      statusText = 'sedang DIPROSES';
    }

    final message =
        '''
Halo Kak *$customerName*,
Update status laundry dengan Nomor Nota *$transactionCode*:

Pakaian Anda saat ini *$statusText*.

Terima kasih! 🙏
''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
