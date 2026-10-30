import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkdate/core/network/api_exception.dart';
import 'package:sparkdate/core/network/idempotency.dart';
import 'package:sparkdate/features/billing/data/billing_models.dart';
import 'package:sparkdate/features/billing/data/payments_repository.dart';
import 'package:sparkdate/features/connections/data/connections_models.dart';
import 'package:sparkdate/features/connections/data/connections_repository.dart';
import 'package:sparkdate/features/events/data/event_models.dart';
import 'package:sparkdate/features/events/data/remote_events_repository.dart';
import 'package:sparkdate/features/refund/data/refund_repository.dart';

/// Fake backend: records requests, answers from [handler] (or throws a connection error).
class FakeServer extends Interceptor {
  FakeServer(this.handler);
  final Object? Function(RequestOptions o) handler;
  final requests = <RequestOptions>[];
  int failNext = 0;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    requests.add(o);
    if (failNext > 0) {
      failNext--;
      return h.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError));
    }
    final r = handler(o);
    if (r is Response) return h.resolve(r..requestOptions = o);
    h.resolve(Response(requestOptions: o, statusCode: 200, data: r));
  }
}

Dio dioWith(FakeServer s) => Dio(BaseOptions(baseUrl: 'http://x/api/v1'))..interceptors.add(s);

final eventJson = {
  'id': 'e1',
  'title': 'Friday Sparks',
  'city': 'Indore',
  'description': 'desc',
  'startsAt': '2026-11-06T14:30:00.000Z',
  'endsAt': null,
  'roundMinutes': 4,
  'priceInPaise': 19900,
  'isFree': false,
  'playProductId': 'event_ticket_199',
  'status': 'published',
  'seatsLeft': 7,
};

final bookingJson = {
  'id': 'b1',
  'eventId': 'e1',
  'status': 'pending',
  'gender': 'female',
  'amountInPaise': 19900,
  'holdExpiresAt': '2026-11-01T10:10:00.000Z',
  'confirmedAt': null,
  'refundEligible': false,
  'refund': null,
  'createdAt': '2026-11-01T10:00:00.000Z',
};

void main() {
  group('parsing', () {
    test('event list item + detail extras', () {
      final e = SparkEvent.fromJson({
        ...eventJson,
        'liked': true,
        'saved': false,
        'myBooking': {...bookingJson, 'status': 'confirmed', 'holdExpiresAt': null, 'refundEligible': true},
      });
      expect(e.status, EventStatus.upcoming);
      expect(e.pricePaise, 19900);
      expect(e.priceLabel, '₹199');
      expect(e.spotsLeft, 7);
      expect(e.roundMinutes, 4);
      expect(e.liked, isTrue);
      expect(e.booked, isTrue);
      expect(e.myBooking!.refundEligible, isTrue);
      expect(SparkEvent.fromJson({...eventJson, 'status': 'cancelled', 'seatsLeft': null, 'city': null}).spotsLeft, isNull);
      expect(SparkEvent.fromJson(e.toJson()).pricePaise, 19900);
    });

    test('booking statuses + refund block', () {
      for (final (s, v) in [
        ('pending', BookingStatus.pending),
        ('confirmed', BookingStatus.confirmed),
        ('cancelled', BookingStatus.cancelled),
        ('expired', BookingStatus.expired),
        ('refund_requested', BookingStatus.refundRequested),
        ('refunded', BookingStatus.refunded),
        ('cancelled_by_admin', BookingStatus.cancelledByAdmin),
      ]) {
        final b = Booking.fromJson({...bookingJson, 'status': s});
        expect(b.status, v);
        expect(Booking.fromJson(b.toJson()).status, v);
      }
      final b = Booking.fromJson({
        ...bookingJson,
        'status': 'refund_requested',
        'refund': {
          'status': 'rejected',
          'reason': 'no matches',
          'rejectReason': 'attended',
          'requestedAt': '2026-11-02T00:00:00Z'
        },
        'event': eventJson,
      });
      expect(b.refund!.status, RefundStatus.rejected);
      expect(b.refund!.rejectReason, 'attended');
      expect(b.event!.title, 'Friday Sparks');
    });

    test('POST /bookings result, verify results, subscription, notifications', () {
      final r = BookingResult.fromJson({
        'booking': bookingJson,
        'play': {'productId': 'event_ticket_199', 'obfuscatedAccountId': 'u1', 'obfuscatedProfileId': 'b1'}
      });
      expect(r.play!.obfuscatedProfileId, 'b1');
      expect(VerifyResult.fromJson({'status': 'pending', 'booking': bookingJson}).pending, isTrue);
      expect(VerifyResult.fromJson({'status': 'confirmed', 'chatPassUntil': '2026-12-01T00:00:00Z'}).chatPassUntil, isNotNull);
      final c = ChatPassStatus.fromJson({
        'chatPass': {
          'active': true,
          'expiresAt': '2026-12-01T00:00:00Z',
          'productId': 'chat_pass_monthly',
          'autoRenewing': true,
          'state': 'active'
        }
      });
      expect(c.active && c.autoRenewing, isTrue);
      expect(
          ChatPassStatus.fromJson({
            'chatPass': {'active': false, 'expiresAt': null, 'productId': null, 'autoRenewing': false, 'state': null}
          }).active,
          isFalse);
      final n = AppNotification.fromJson({
        'id': 'n1',
        'type': 'refund_processed',
        'title': 'Refund processed',
        'body': '₹199',
        'data': {'bookingId': 'b1', 'eventId': 'e1'},
        'read': false,
        'createdAt': '2026-11-02T00:00:00Z',
      });
      expect(n.type, NotificationType.refundProcessed);
      expect(n.eventId, 'e1');
    });

    test('error codes map', () {
      for (final c in [
        'PROFILE_INCOMPLETE',
        'VERIFICATION_REQUIRED',
        'EVENT_FULL',
        'EVENT_NOT_BOOKABLE',
        'NOT_FOUND',
        'BOOKING_NOT_FOUND',
        'BOOKING_NOT_CANCELLABLE',
        'REFUND_NOT_ELIGIBLE',
        'REFUND_ALREADY_REQUESTED',
        'REFUND_REJECTED',
        'PURCHASE_INVALID',
        'PRODUCT_MISMATCH',
        'PURCHASE_ALREADY_USED',
        'EVENT_FULL_REFUNDED',
        'PLAY_UNAVAILABLE',
        'IDEMPOTENCY_KEY_REQUIRED',
        'IDEMPOTENCY_IN_PROGRESS',
        'IDEMPOTENCY_KEY_REUSED',
        'VERIFICATION_NOT_ALLOWED',
      ]) {
        expect(ApiErrorCode.fromCode(c).code, c);
      }
    });
  });

  group('idempotency', () {
    test('uuidV4 matches the server key pattern', () {
      final k = uuidV4();
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(k), isTrue);
      expect(RegExp(r'^[A-Za-z0-9_\-:.]{8,128}$').hasMatch(k), isTrue);
      expect(uuidV4(), isNot(k));
    });

    test('POST /bookings sends Idempotency-Key; retry after a network error reuses it; next action gets a new one', () async {
      final s = FakeServer((o) => Response(requestOptions: o, statusCode: 201, data: {
            'booking': bookingJson,
            'play': {'productId': 'event_ticket_199', 'obfuscatedAccountId': 'u1', 'obfuscatedProfileId': 'b1'}
          }));
      final repo = RemoteEventsRepository(dioWith(s));
      final action = IdempotentAction();
      s.failNext = 1;
      await expectLater(action.run((k) => repo.book('e1', idempotencyKey: k)),
          throwsA(isA<ApiException>().having((e) => e.error, 'error', ApiErrorCode.network)));
      final r = await action.run((k) => repo.book('e1', idempotencyKey: k));
      expect(r.created, isTrue);
      expect(s.requests.map((o) => o.path), ['/bookings', '/bookings']);
      expect(s.requests.map((o) => o.data), everyElement({'eventId': 'e1'}));
      final k1 = s.requests[0].headers['Idempotency-Key'], k2 = s.requests[1].headers['Idempotency-Key'];
      expect(k1, isNotNull);
      expect(k2, k1);
      await action.run((k) => repo.book('e1', idempotencyKey: k));
      expect(s.requests[2].headers['Idempotency-Key'], isNot(k1));
    });

    test('final 4xx drops the key; IDEMPOTENCY_IN_PROGRESS keeps it', () async {
      var code = 'IDEMPOTENCY_IN_PROGRESS';
      final s = FakeServer((o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: o, statusCode: 409, data: {
            'error': {'code': code}
          })));
      final repo = RemoteEventsRepository(dioWith(s));
      final a = IdempotentAction();
      await expectLater(a.run((k) => repo.book('e1', idempotencyKey: k)), throwsA(isA<ApiException>()));
      final k1 = a.key;
      code = 'EVENT_FULL';
      await expectLater(a.run((k) => repo.book('e1', idempotencyKey: k)), throwsA(isA<ApiException>()));
      expect(s.requests[1].headers['Idempotency-Key'], k1);
      expect(a.key, isNot(k1));
    });

    test('verify + refund-request bodies, paths and headers', () async {
      final s = FakeServer((o) => switch (o.path) {
            '/payments/play/verify' =>
              Response(requestOptions: o, statusCode: 202, data: {'status': 'pending', 'booking': bookingJson}),
            _ => {
                'booking': {
                  ...bookingJson,
                  'status': 'refund_requested',
                  'refund': {'status': 'requested', 'reason': 'x', 'rejectReason': null, 'requestedAt': null}
                }
              },
          });
      final dio = dioWith(s);
      final v = await RemotePaymentsRepository(dio).verifyPlayPurchase(
          const PurchaseResult(productId: 'event_ticket_199', purchaseToken: 'tok_1234567890'),
          kind: PurchaseKind.ticket,
          bookingId: 'b1',
          idempotencyKey: 'verify-key-1');
      expect(v.pending, isTrue);
      expect(s.requests.last.data,
          {'purchaseToken': 'tok_1234567890', 'productId': 'event_ticket_199', 'kind': 'ticket', 'bookingId': 'b1'});
      expect(s.requests.last.headers['Idempotency-Key'], 'verify-key-1');

      await RemotePaymentsRepository(dio).verifyPlayPurchase(
          const PurchaseResult(productId: 'chat_pass_monthly', purchaseToken: 'tok_abcdefghij'),
          kind: PurchaseKind.chatPass,
          idempotencyKey: 'verify-key-2');
      expect((s.requests.last.data as Map)['kind'], 'chat_pass');
      expect((s.requests.last.data as Map).containsKey('bookingId'), isFalse);

      final rr = await RemoteRefundRepository(dio)
          .request('b1', RefundReason.noMatches, note: 'nobody showed', idempotencyKey: 'refund-key-1');
      expect(s.requests.last.path, '/bookings/b1/refund-request');
      expect(s.requests.last.data, {'reason': 'No matches / dates did not happen: nobody showed'});
      expect(s.requests.last.headers['Idempotency-Key'], 'refund-key-1');
      expect(rr.status, RefundStatus.requested);
    });
  });

  group('remote paths', () {
    test('events list query, like/save verbs, my bookings, notifications paging + read', () async {
      final s = FakeServer((o) => switch ((o.method, o.path)) {
            ('GET', '/events') => {
                'items': [eventJson],
                'nextCursor': 'c2'
              },
            ('GET', '/events/e1') => {...eventJson, 'liked': true, 'saved': true, 'myBooking': null},
            ('GET', '/me/bookings') => {
                'upcoming': [
                  {...bookingJson, 'event': eventJson}
                ],
                'past': []
              },
            ('GET', '/notifications') => {'items': []},
            ('POST', '/notifications/read') => {'updated': 2},
            _ => {'liked': true, 'saved': true},
          });
      final dio = dioWith(s);
      final repo = RemoteEventsRepository(dio);
      final p = await repo.page(filter: const EventFilter(cities: {'Indore'}, status: EventStatus.live, q: 'fri'), cursor: 'c1');
      expect(p.nextCursor, 'c2');
      expect(s.requests.last.queryParameters, {'status': 'live', 'city': 'Indore', 'q': 'fri', 'limit': 20, 'cursor': 'c1'});
      await repo.list(filter: const EventFilter(cities: {'Indore', 'Bhopal'}));
      expect(s.requests.reversed.take(2).map((o) => o.queryParameters['city']).toSet(), {'Indore', 'Bhopal'});
      await repo.setLiked('e1', true);
      expect(s.requests[s.requests.length - 2].method, 'POST');
      expect(s.requests[s.requests.length - 2].path, '/events/e1/like');
      await repo.setSaved('e1', false);
      expect(s.requests[s.requests.length - 2].method, 'DELETE');
      expect(s.requests[s.requests.length - 2].path, '/events/e1/save');
      expect((await repo.myUpcoming()).single.booked, isTrue);

      final c = RemoteConnectionsRepository(dio, () => 'u1');
      await c.notifications(before: DateTime.utc(2026, 11, 1), limit: 10);
      expect(s.requests.last.queryParameters, {'before': '2026-11-01T00:00:00.000Z', 'limit': 10});
      expect(await c.markRead(['n1', 'n2']), 2);
      expect(s.requests.last.data, {
        'ids': ['n1', 'n2']
      });
    });
  });
}
