/// Paths under /api/v1, copied from docs/reference/api-contract.xlsx.
/// Never add a path that is not in the contract (see AGENTS.md).
class ApiRoutes {
  ApiRoutes._();
  static const login = '/auth/login'; // EP-004
  static const refresh = '/auth/refresh'; // EP-005
  static const logout = '/auth/logout'; // EP-006
  static const categories = '/categories'; // EP-021
  static const locations = '/locations'; // EP-023
  static const offers = '/offers'; // EP-035
  static const me = '/users/me'; // EP-009
  static const myProvider = '/providers/me'; // EP-014 (read), EP-015 (update)
  static const myVerifications = '/providers/me/verifications'; // EP-018
  static const myTransactions = '/transactions'; // EP-065
  static const requestFeed = '/requests/feed'; // EP-043
  static const notifications = '/notifications'; // EP-109
  static const notificationsUnreadCount = '/notifications/unread-count'; // EP-110
  static const notificationsReadAll = '/notifications/read-all'; // EP-112
  static String notificationRead(String id) =>
      '/notifications/${Uri.encodeComponent(id)}/read'; // EP-111
  static String offer(String id) => '/offers/${Uri.encodeComponent(id)}'; // EP-037
  // EP-036 GET /offers/map comes with the map task; EP-019/EP-020 (public
  // provider profile and reviews) with the provider profile task.
}
