import 'package:commet/ui/pages/matrix/verification/matrix_verification_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';

class MatrixVerificationPage extends StatefulWidget {
  final KeyVerification request;

  const MatrixVerificationPage({required this.request, super.key});

  @override
  State<MatrixVerificationPage> createState() => MatrixVerificationPageState();
}

class MatrixVerificationPageState extends State<MatrixVerificationPage> {
  void Function()? originalOnUpdate;

  @override
  void initState() {
    super.initState();

    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.request.userId;
    return MatrixVerificationPageView(
      state: widget.request.state,
      // Have to do this because the sasNumber are freed after verification finishes
      sasTypes: widget.request.state == KeyVerificationState.askSas ? widget.request.sasTypes : [],
      sasEmoji: widget.request.state == KeyVerificationState.askSas ? widget.request.sasEmojis : [],
      sasNumbers: widget.request.state == KeyVerificationState.askSas ? widget.request.sasNumbers : [],
      userID: userId,
      onSasAccepted: acceptSas,
      onSasRejected: rejectSas,
      onVerificationRequestAccepted: acceptRequest,
      onVerificationRequestRejected: rejectRequest,
    );
  }

  void acceptRequest() async {
    await widget.request.acceptVerification();
  }

  void rejectRequest() async {
    await widget.request.rejectVerification();
  }

  void acceptSas() async {
    widget.request.acceptSas();
  }

  void rejectSas() async {
    widget.request.rejectSas();
  }
}
