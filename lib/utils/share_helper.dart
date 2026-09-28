import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/candidate.dart';

class ShareHelper {
  /// Builds clean, readable text representation of candidate biodata
  static String buildProfileText(Candidate c, {int attachedPhotoCount = 0}) {
    final photoNote = attachedPhotoCount > 0
        ? '📸 $attachedPhotoCount photo(s) attached with this profile.\n'
        : (c.allPhotos.isNotEmpty ? '📸 ${c.allPhotos.length} photo(s) available.\n' : '');

    final buffer = StringBuffer();
    buffer.writeln('💍 *NikkahPakkah — Rishta Profile*');
    buffer.writeln();
    buffer.writeln('*Name:* ${c.name}');
    buffer.writeln('*Gender:* ${c.gender}');
    if (c.dob.isNotEmpty) buffer.writeln('*Date of Birth:* ${c.dob}');
    buffer.writeln('*Age:* ${c.age} years');
    buffer.writeln('*Height:* ${c.heightDisplay}');
    if (c.complexion.isNotEmpty) buffer.writeln('*Complexion:* ${c.complexion}');
    buffer.writeln('*Sect:* ${c.sect}');
    buffer.writeln('*Caste:* ${c.caste}');
    buffer.writeln('*Education:* ${c.education}');
    if (c.occupation.isNotEmpty) buffer.writeln('*Occupation:* ${c.occupation}');
    if (c.fatherName.isNotEmpty) buffer.writeln('*Father:* ${c.fatherName}');
    if (c.fatherOccupation.isNotEmpty) buffer.writeln('*Father\'s Occupation:* ${c.fatherOccupation}');
    if (c.motherName.isNotEmpty) buffer.writeln('*Mother:* ${c.motherName}');
    if (c.city.isNotEmpty) buffer.writeln('*City:* ${c.city}');
    if (c.address.isNotEmpty) buffer.writeln('*Address:* ${c.address}');
    if (c.contactNumber.isNotEmpty) buffer.writeln('*Contact:* ${c.contactNumber}');
    buffer.writeln('*Reference:* ${c.agentReferenceName}');
    if (photoNote.isNotEmpty) buffer.writeln(photoNote.trim());
    buffer.writeln();
    buffer.writeln('_Shared via NikkahPakkah · Confidential_');

    return buffer.toString();
  }

  /// Shares candidate profile text + all attached photos to WhatsApp / native share sheet
  static Future<void> shareCandidateWithPhotos(BuildContext context, Candidate c) async {
    final photoFiles = <XFile>[];
    for (final p in c.allPhotos) {
      if (File(p).existsSync()) {
        photoFiles.add(XFile(p));
      }
    }

    final text = buildProfileText(c, attachedPhotoCount: photoFiles.length);

    try {
      if (photoFiles.isNotEmpty) {
        await Share.shareXFiles(
          photoFiles,
          text: text,
          subject: 'NikkahPakkah Profile — ${c.name}',
        );
      } else {
        await Share.share(
          text,
          subject: 'NikkahPakkah Profile — ${c.name}',
        );
      }
    } catch (e) {
      // Fallback to URL launcher if Share fails
      final encoded = Uri.encodeComponent(text);
      final url = Uri.parse('https://wa.me/?text=$encoded');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share profile: $e')),
        );
      }
    }
  }

  /// Shares an individual photo
  static Future<void> shareSinglePhoto(BuildContext context, String photoPath, String candidateName) async {
    final file = File(photoPath);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo file not found.')),
        );
      }
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(photoPath)],
        text: '$candidateName\'s Photo — NikkahPakkah',
        subject: '$candidateName\'s Photo — NikkahPakkah',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share photo: $e')),
        );
      }
    }
  }

  /// Shares the original scanned biodata image
  static Future<void> shareScannedBiodata(BuildContext context, Candidate c) async {
    if (c.biodataImagePath == null || !File(c.biodataImagePath!).existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No original scanned biodata image found.')),
        );
      }
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(c.biodataImagePath!)],
        text: '📄 Scanned Biodata Sheet — ${c.name} (${c.education}, ${c.city})\n_Shared via NikkahPakkah_',
        subject: 'Scanned Biodata — ${c.name}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share biodata document: $e')),
        );
      }
    }
  }

  /// Shows a modal bottom sheet with multiple share options
  static void showShareOptions(BuildContext context, Candidate c) {
    final hasPhotos = c.allPhotos.any((p) => File(p).existsSync());
    final hasScan = c.biodataImagePath != null && File(c.biodataImagePath!).existsSync();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Share ${c.name}\'s Profile',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                ),
                title: Text(hasPhotos ? 'Share Profile & Photos' : 'Share Profile Details'),
                subtitle: Text(hasPhotos
                    ? 'Attaches ${c.allPhotos.length} photo(s) + complete biodata text'
                    : 'Sends complete formatted biodata text'),
                onTap: () {
                  Navigator.pop(ctx);
                  shareCandidateWithPhotos(context, c);
                },
              ),
              if (hasPhotos)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                  ),
                  title: const Text('Share Photos Only'),
                  subtitle: Text('Sends all ${c.allPhotos.length} candidate photo(s)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final files = c.allPhotos.where((p) => File(p).existsSync()).map((p) => XFile(p)).toList();
                    if (files.isNotEmpty) {
                      await Share.shareXFiles(files, text: '${c.name}\'s Photos — NikkahPakkah');
                    }
                  },
                ),
              if (hasScan)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.amber),
                  ),
                  title: const Text('Share Original Scanned Biodata'),
                  subtitle: const Text('Sends the scanned document image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    shareScannedBiodata(context, c);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
