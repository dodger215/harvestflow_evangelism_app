import 'dart:convert';
import 'package:http/http.dart' as http;

class SMSService {
  static const String _baseUrl = 'https://sms.arkesel.com/api/v2/sms/send';
  
  Future<bool> sendSMS({
    required String recipient,
    required String message,
    required String apiKey,
    String sender = 'SoulReach',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'recipient': recipient,
          'sender': sender,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  Future<List<bool>> sendBulkSMS({
    required List<String> recipients,
    required String message,
    required String apiKey,
    String sender = 'SoulReach',
  }) async {
    List<bool> results = [];
    
    for (String recipient in recipients) {
      final result = await sendSMS(
        recipient: recipient,
        message: message,
        apiKey: apiKey,
        sender: sender,
      );
      results.add(result);
      
      // Add a small delay between requests to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  String formatMessage(String template, Map<String, String> variables) {
    String message = template;
    variables.forEach((key, value) {
      message = message.replaceAll('{$key}', value);
    });
    return message;
  }
}