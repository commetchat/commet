import 'package:commet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'loading_page.dart';

@WidgetbookUseCase(name: 'Loading Page', type: LoadingPageView)
@Deprecated("widgetbook")
Widget wbLoadingpage(BuildContext context) {
  return const LoadingPageView();
}

class LoadingPageView extends StatelessWidget {
  const LoadingPageView({super.key, this.state});
  final LoadingPageState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(T.current.loading),
          )
        ],
      ),
    );
  }
}
