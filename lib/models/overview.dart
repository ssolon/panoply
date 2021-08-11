/// Overview for articles
/// Some

class Overview {
  int number;
  String subject;
  String from;
  String date;
  String msgId;
  String references;
  int bytes;
  int lines;
  String xref;

  Overview(
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

class ThreadedOverview extends Overview {
  List<ThreadedOverview>? replys;

  ThreadedOverview(
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
