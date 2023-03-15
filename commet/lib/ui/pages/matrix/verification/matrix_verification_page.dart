import 'package:commet/ui/pages/matrix/verification/matrix_verification_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption/utils/key_verification.dart';

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
    originalOnUpdate = widget.request.onUpdate;

    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      if (mounted) {
        setState(() {});
      }
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MatrixVerificationPageView(
      state: widget.request.state,
      // Have to do this because the sasNumber are freed after verification finishes
      sasTypes: widget.request.state == KeyVerificationState.askSas ? widget.request.sasTypes : [],
      sasEmoji: widget.request.state == KeyVerificationState.askSas ? widget.request.sasEmojis : [],
      sasNumbers: widget.request.state == KeyVerificationState.askSas ? widget.request.sasNumbers : [],
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
