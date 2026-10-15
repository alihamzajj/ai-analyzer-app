/// Classification of messages in a WhatsApp chat export.
enum MessageType {
  /// Regular user conversation message.
  text,

  /// Media placeholder (e.g. `"<Media omitted>"`, "image omitted").
  media,

  /// System notification (e.g. encryption notice, group changes).
  system,

  /// Deleted message indicator ("This message was deleted").
  deleted,
}
