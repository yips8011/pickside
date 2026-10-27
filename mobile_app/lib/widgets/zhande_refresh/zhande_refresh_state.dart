/// Refresh state machine for ZhandeRefreshIndicator.
///
/// Flow: idle → pulling → ready → refreshing → success → closing → idle
enum ZhandeRefreshState {
  /// Header fully collapsed. No pull in progress.
  idle,

  /// User dragging down, distance < triggerDistance.
  pulling,

  /// User dragging down, distance >= triggerDistance.
  ready,

  /// Refresh in progress. onRefresh() has been called and is pending.
  refreshing,

  /// Refresh completed. Showing success message.
  success,

  /// Header animating back to idle.
  closing,
}
