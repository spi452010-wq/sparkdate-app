abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const verify = '/login/verify';
  static const completeProfile = '/profile/complete';
  static const home = '/home';

  // Events
  static const events = '/events';
  static const eventDetail = '/events/detail';
  static const freeBooking = '/events/free-booking';
  static const selfie = '/verification/selfie';
  static const payment = '/events/payment';
  static const bookingSuccess = '/events/booked';

  // Live session
  static const waitingRoom = '/live/waiting';
  static const matchFound = '/live/match';
  static const liveCall = '/live/call';
  static const earlyDisconnect = '/live/early-disconnect';
  static const callEnded = '/live/ended';
  static const waitingResponse = '/live/waiting-response';
  static const mutualConnection = '/live/mutual';

  // Connections & chat
  static const likes = '/connections/likes';
  static const saved = '/connections/saved';
  static const connectionDetail = '/connections/detail';
  static const chats = '/chats';
  static const chat = '/chats/thread';
  static const chatSubscription = '/chat-pass';
  static const subscriptionSuccess = '/chat-pass/success';
  static const notifications = '/notifications';

  // Profile & refund
  static const profile = '/profile';
  static const profileDetails = '/profile/details';
  static const editProfile = '/profile/edit';
  static const refund = '/refund';
  static const refundConfirm = '/refund/confirm';
  static const refundDone = '/refund/done';
}
