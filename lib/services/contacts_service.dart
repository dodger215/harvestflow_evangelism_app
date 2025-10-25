import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:harvestflow/models/member.dart';

class DeviceContactsService {
  static Future<bool> requestPermission() async {
    final permission = await Permission.contacts.request();
    return permission == PermissionStatus.granted;
  }

  static Future<bool> saveToContacts(Member member) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return false;
      }

      final contact = Contact(
        givenName: member.name,
        phones: [Item(label: 'mobile', value: member.phone)],
        postalAddresses: member.address.isNotEmpty
            ? [PostalAddress(label: 'home', street: member.address)]
            : [],
        company: 'SoulWinning Ministry',
        jobTitle: member.groupTag,
      );

      await ContactsService.addContact(contact);
      return true;
    } catch (e) {
      print('Error saving contact: $e');
      return false;
    }
  }

  static Future<bool> checkIfContactExists(String phone) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return false;
      }

      final contacts = await ContactsService.getContacts();
      return contacts.any((contact) => 
        contact.phones?.any((phoneItem) => 
          phoneItem.value?.replaceAll(RegExp(r'[^\d]'), '') == 
          phone.replaceAll(RegExp(r'[^\d]'), '')
        ) ?? false
      );
    } catch (e) {
      print('Error checking contact: $e');
      return false;
    }
  }

  static Future<List<Contact>> searchContacts(String query) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return [];
      }

      final contacts = await ContactsService.getContacts(query: query);
      return contacts;
    } catch (e) {
      print('Error searching contacts: $e');
      return [];
    }
  }
}