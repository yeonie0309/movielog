import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoriteDetailViewModel>();
    if (vm.busy) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          key: Key('favorite-progress'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      key: const Key('favorite-button'),
      tooltip: vm.error != null
          ? '즐겨찾기 상태 다시 조회'
          : vm.isFavorite == true
          ? '즐겨찾기 해제'
          : '즐겨찾기 추가',
      icon: Icon(
        vm.error != null && vm.isFavorite == null
            ? Icons.sync_problem
            : vm.isFavorite == true
            ? Icons.bookmark
            : Icons.bookmark_border,
      ),
      onPressed: !vm.session.isSignedIn
          ? null
          : () async {
              if (vm.error != null || vm.isFavorite == null) {
                await vm.load();
                if (!context.mounted || vm.isDisposed) return;
                if (vm.error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(vm.error!)));
                }
                return;
              }
              final message = await vm.toggle();
              if (!context.mounted || message == null || vm.isDisposed) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            },
    );
  }
}
