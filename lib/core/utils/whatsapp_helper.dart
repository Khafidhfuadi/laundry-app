import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class WhatsAppHelper {
  static String _formatPhoneNumber(String phoneNumber) {
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Normalisasi nomor Indonesia:
    // 0812xxxx -> 62812xxxx
    // 812xxxx  -> 62812xxxx
    // 62xxxx   -> 62xxxx (tetap)
    if (formattedPhone.startsWith('62')) return formattedPhone;
    if (formattedPhone.startsWith('0')) {
      return '62${formattedPhone.substring(1)}';
    }
    if (formattedPhone.startsWith('8')) {
      return '62$formattedPhone';
    }

    return formattedPhone;
  }

  static Future<bool> _launchWhatsApp({
    required String formattedPhone,
    required String encodedMessage,
  }) async {
    final waScheme = Uri.parse(
      'whatsapp://send?phone=$formattedPhone&text=$encodedMessage',
    );
    final waMe = Uri.parse(
      'https://wa.me/$formattedPhone?text=$encodedMessage',
    );

    try {
      final opened = await launchUrl(
        waScheme,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return true;
    } catch (_) {}

    try {
      return await launchUrl(waMe, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendInvoice({
    required String phoneNumber,
    required String customerName,
    required String transactionCode,
    required double totalAmount,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);

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
    return _launchWhatsApp(
      formattedPhone: formattedPhone,
      encodedMessage: encodedMessage,
    );
  }

  static Future<bool> sendStatusUpdate({
    required String phoneNumber,
    required String customerName,
    required String transactionCode,
    required String status,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    String statusText = '';
    if (status == 'READY') {
      statusText = 'sudah SELESAI dan SIAP DIKIRIM';
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
    return _launchWhatsApp(
      formattedPhone: formattedPhone,
      encodedMessage: encodedMessage,
    );
  }

  static Future<bool> sendTransactionSummary({
    required String phoneNumber,
    required String customerName,
    required String transactionCode,
    required DateTime transactionDate,
    required DateTime estimatedCompletionDate,
    required List<String> itemLines,
    required double totalAmount,
    required double paidAmount,
    required String paymentStatus,
    String outletName = 'Laundry App',
    String notes = '',
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID');
    final remaining = (totalAmount - paidAmount).clamp(0, double.infinity);

    String paymentLabel;
    if (paymentStatus == 'PAID') {
      paymentLabel = 'Lunas';
    } else if (paymentStatus == 'PARTIAL') {
      paymentLabel = 'DP / Sebagian';
    } else {
      paymentLabel = 'Belum Bayar';
    }

    final itemSection = itemLines.isEmpty
        ? '1. Layanan laundry'
        : itemLines
              .asMap()
              .entries
              .map((entry) {
                final idx = entry.key + 1;
                return '$idx. ${entry.value}';
              })
              .join('\n');

    final notesSection = notes.trim().isEmpty
        ? ''
        : '\nCatatan: ${notes.trim()}\n';

    final message =
        '''
*STRUK NOTA DIGITAL*
$outletName

------------------------------

No Nota : *$transactionCode*
Pelanggan : *$customerName*
Tanggal : ${dateFormat.format(transactionDate)}
Estimasi : *${dateFormat.format(estimatedCompletionDate)}*

------------------------------

Detail Layanan:
$itemSection

------------------------------

Total : *${currency.format(totalAmount)}*
Dibayar : *${currency.format(paidAmount)}*
Sisa : *${currency.format(remaining)}*
Status Bayar : *$paymentLabel*$notesSection

------------------------------

Terima kasih.
''';

    final encodedMessage = Uri.encodeComponent(message);
    return _launchWhatsApp(
      formattedPhone: formattedPhone,
      encodedMessage: encodedMessage,
    );
  }
}
