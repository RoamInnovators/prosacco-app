import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

class ShareMarketplaceScreen extends StatefulWidget {
  const ShareMarketplaceScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<ShareMarketplaceScreen> createState() => _ShareMarketplaceScreenState();
}

class _ShareMarketplaceScreenState extends State<ShareMarketplaceScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  ShareMarketplaceListingsResponse? _market;
  ShareMarketplaceValuation? _valuation;
  List<ShareMarketplaceListing> _myListings = const [];
  List<ShareMarketplaceTrade> _trades = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ProsaccoMemberAuthApi();
      final results = await Future.wait([
        api.fetchShareMarketplaceListings(token: widget.authToken),
        api.fetchShareMarketplaceValuation(token: widget.authToken),
        api.fetchMyShareListings(token: widget.authToken),
        api.fetchShareMarketplaceTrades(token: widget.authToken),
      ]);
      if (!mounted) return;
      setState(() {
        _market = results[0] as ShareMarketplaceListingsResponse;
        _valuation = results[1] as ShareMarketplaceValuation;
        _myListings = results[2] as List<ShareMarketplaceListing>;
        _trades = results[3] as List<ShareMarketplaceTrade>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _money(int cents) => (cents / 100).toStringAsFixed(2);

  Future<void> _buy(ShareMarketplaceListing listing) async {
    final sharesCtrl = TextEditingController(text: '${listing.remainingShares}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy shares'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Seller: ${listing.sellerName ?? 'Member'}'),
            Text('Price: KES ${_money(listing.pricePerShareCents)} per share'),
            const SizedBox(height: 12),
            TextField(
              controller: sharesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Shares to buy',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Buy')),
        ],
      ),
    );
    if (ok != true) {
      sharesCtrl.dispose();
      return;
    }
    final shares = int.tryParse(sharesCtrl.text.trim()) ?? 0;
    sharesCtrl.dispose();
    if (shares <= 0) return;
    try {
      await ProsaccoMemberAuthApi().buyShareMarketplaceListing(
        token: widget.authToken,
        listingId: listing.id,
        shares: shares,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share trade completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _createListing() async {
    final sharesCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: _valuation == null ? '' : '${(_valuation!.pricePerShareCents / 100).toStringAsFixed(0)}',
    );
    final notesCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sell Shares', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Available to sell: ${_valuation?.availableToSellShares ?? 0} shares'),
              const SizedBox(height: 16),
              TextField(
                controller: sharesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Shares', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price per share', prefixText: 'KES ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create Listing')),
            ],
          ),
        ),
      ),
    );
    if (ok != true) {
      sharesCtrl.dispose();
      priceCtrl.dispose();
      notesCtrl.dispose();
      return;
    }
    final shares = int.tryParse(sharesCtrl.text.trim()) ?? 0;
    final priceCents = ((double.tryParse(priceCtrl.text.trim()) ?? 0) * 100).round();
    final notes = notesCtrl.text.trim();
    sharesCtrl.dispose();
    priceCtrl.dispose();
    notesCtrl.dispose();
    if (shares <= 0 || priceCents <= 0) return;
    try {
      await ProsaccoMemberAuthApi().createShareMarketplaceListing(
        token: widget.authToken,
        shares: shares,
        pricePerShareCents: priceCents,
        notes: notes,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share listing created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancel(ShareMarketplaceListing listing) async {
    try {
      await ProsaccoMemberAuthApi().cancelShareMarketplaceListing(
        token: widget.authToken,
        listingId: listing.id,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Share Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createListing,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell Shares'),
      ),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: p.error)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                    children: [
                      _valuationCard(context),
                      const SizedBox(height: 16),
                      SegmentedButton<int>(
                        selected: {_tab},
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Market')),
                          ButtonSegment(value: 1, label: Text('My Listings')),
                          ButtonSegment(value: 2, label: Text('Trades')),
                        ],
                        onSelectionChanged: (value) => setState(() => _tab = value.first),
                      ),
                      const SizedBox(height: 16),
                      if (_tab == 0) _marketList(context),
                      if (_tab == 1) _myListingsList(context),
                      if (_tab == 2) _tradesList(context),
                    ],
                  ),
                ),
    );
  }

  Widget _valuationCard(BuildContext context) {
    final v = _valuation;
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your share position', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('${v?.totalShares ?? 0} shares', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Market value KES ${_money(v?.markToMarketCents ?? 0)}', style: const TextStyle(color: Colors.white)),
          Text('Available to sell: ${v?.availableToSellShares ?? 0} shares', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _marketList(BuildContext context) {
    final rows = _market?.listings ?? const [];
    if (rows.isEmpty) return const _EmptyShareState(text: 'No share listings are available right now.');
    return Column(
      children: rows
          .map(
            (row) => _ListingTile(
              row: row,
              actionLabel: 'Buy',
              onAction: () => _buy(row),
            ),
          )
          .toList(),
    );
  }

  Widget _myListingsList(BuildContext context) {
    if (_myListings.isEmpty) return const _EmptyShareState(text: 'You have not listed any shares yet.');
    return Column(
      children: _myListings
          .map(
            (row) => _ListingTile(
              row: row,
              actionLabel: row.status == 'ACTIVE' ? 'Cancel' : row.status,
              onAction: row.status == 'ACTIVE' ? () => _cancel(row) : null,
            ),
          )
          .toList(),
    );
  }

  Widget _tradesList(BuildContext context) {
    if (_trades.isEmpty) return const _EmptyShareState(text: 'No marketplace trades yet.');
    return Column(
      children: _trades
          .map(
            (t) => Card(
              child: ListTile(
                leading: Icon(t.side == 'BUY' ? Icons.south_west_rounded : Icons.north_east_rounded),
                title: Text('${t.side} ${t.shares} shares'),
                subtitle: Text('${t.status} · ${t.createdAt}'),
                trailing: Text('KES ${_money(t.totalAmountCents)}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.row, required this.actionLabel, this.onAction});

  final ShareMarketplaceListing row;
  final String actionLabel;
  final VoidCallback? onAction;

  String _money(int cents) => (cents / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.pal.secondaryContainer.withValues(alpha: 0.45),
              child: Icon(Icons.trending_up_rounded, color: context.pal.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${row.remainingShares} shares', style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('KES ${_money(row.pricePerShareCents)} each · ${row.sellerName ?? 'Member'}'),
                  Text('Total KES ${_money(row.totalAmountCents)}', style: TextStyle(color: context.pal.onSurfaceVariant)),
                ],
              ),
            ),
            if (onAction != null)
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              )
            else
              Text(actionLabel, style: TextStyle(color: context.pal.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _EmptyShareState extends StatelessWidget {
  const _EmptyShareState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_rounded, size: 42, color: context.pal.primary.withValues(alpha: 0.45)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
