import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design.dart';
import '../core/format.dart';
import '../models/menu_item.dart';
import '../providers/auth_providers.dart';
import '../providers/review_providers.dart';
import '../services/review_service.dart';
import 'ui_kit.dart';

void showReviewsSheet(BuildContext context, String rid, MenuItem item) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => ReviewsSheet(rid: rid, item: item),
    );

/// Row of filled/empty stars.
Widget stars(int n, {double size = 16}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= n ? Icons.star_rounded : Icons.star_border_rounded,
              size: size, color: Brand.star),
      ],
    );

class ReviewsSheet extends ConsumerStatefulWidget {
  final String rid;
  final MenuItem item;
  const ReviewsSheet({super.key, required this.rid, required this.item});

  @override
  ConsumerState<ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends ConsumerState<ReviewsSheet> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;

  static const _labels = ['Tap a star', 'Poor', 'Okay', 'Good', 'Great', 'Loved it!'];

  ItemKey get _key => (rid: widget.rid, itemId: widget.item.id);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a star rating')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(reviewServiceProvider)
          .submit(_key, user.uid, user.name, _rating, _comment.text.trim());
      _comment.clear();
      if (mounted) setState(() => _rating = 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Average score and the share of each star level.
  Widget _summary(List reviews) {
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map<int>((r) => r.rating as int).reduce((a, b) => a + b) /
            reviews.length;

    return Row(children: [
      Column(children: [
        CountUp(avg,
            decimals: 1,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
        stars(avg.round(), size: 18),
        const SizedBox(height: 2),
        Text('${reviews.length} review${reviews.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
      const SizedBox(width: Sp.lg),
      Expanded(
        child: Column(children: [
          for (var s = 5; s >= 1; s--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Text('$s', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, size: 12, color: Brand.star),
                const SizedBox(width: 8),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: reviews.isEmpty
                            ? 0
                            : reviews.where((r) => r.rating == s).length /
                                reviews.length),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        color: Brand.star,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final reviews = ref.watch(reviewsProvider(_key)).value ?? [];
    final me = ref.watch(authStateProvider).value?.uid;
    final hasMine = reviews.any((r) => r.userId == me);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          Sp.md, 0, Sp.md, MediaQuery.of(context).viewInsets.bottom + Sp.md),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name,
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summary(reviews),
                    const Divider(height: Sp.xl),

                    // Star picker
                    Text(hasMine ? 'Update your review' : 'Rate this dish',
                        style: t.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.sm),
                    Row(children: [
                      for (var i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setState(() => _rating = i),
                          child: AnimatedScale(
                            scale: i <= _rating ? 1.15 : 1,
                            duration: AppMotion.fast,
                            curve: Curves.easeOutBack,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                i <= _rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 40,
                                color: Brand.star,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: Sp.sm),
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text(_labels[_rating],
                            key: ValueKey(_rating),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _rating == 0
                                    ? t.colorScheme.outline
                                    : Brand.primary)),
                      ),
                    ]),
                    const SizedBox(height: Sp.sm),
                    TextField(
                      controller: _comment,
                      maxLines: 2,
                      maxLength: 500,
                      decoration: const InputDecoration(
                          hintText: 'Share a few words (optional)'),
                    ),
                    const SizedBox(height: Sp.xs),
                    GradientButton(
                      label: hasMine ? 'Update review' : 'Submit review',
                      icon: Icons.send_rounded,
                      loading: _busy,
                      onPressed: _submit,
                    ),
                    const Divider(height: Sp.xl),

                    // Review list
                    Text('What people say',
                        style: t.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.sm),
                    if (reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Sp.md),
                        child: Text('No reviews yet. Be the first!'),
                      )
                    else
                      for (final r in reviews)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: t.colorScheme.primaryContainer,
                                child: Text(
                                    r.userName.isEmpty
                                        ? '?'
                                        : r.userName[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Brand.primary,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(r.userName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      Text(timeAgo(r.createdAt),
                                          style: t.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: t.colorScheme.outline)),
                                    ]),
                                    stars(r.rating, size: 15),
                                    if (r.comment.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(r.comment),
                                      ),
                                  ],
                                ),
                              ),
                              if (r.userId == me)
                                IconButton(
                                  tooltip: 'Delete my review',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref
                                      .read(reviewServiceProvider)
                                      .delete(_key, r.userId),
                                ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}