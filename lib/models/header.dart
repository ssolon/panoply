/// Overview for articles
/// Some

class Header {
  int number;
  String subject;
  String from;
  String date;
  String msgId;
  String references;
  int bytes;
  int lines;
  String xref;

  Header(
      this.number,
      this.subject,
      this.from,
      this.date,
      this.msgId,
      this.references,
      this.bytes,
      this.lines,
      this.xref,
      );
}

class ThreadedHeader extends Header {
  List<ThreadedHeader>? replys;

  ThreadedHeader(
      number,
      subject,
      from,
      date,
      msgId,
      references,
      bytes,
      lines,
      xref,
      this.replys,
      )  : super(
    number,
    subject,
    from,
    date,
    msgId,
    references,
    bytes,
    lines,
    xref,
  );
}
