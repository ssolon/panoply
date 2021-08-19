
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/services/news_service.dart';

abstract class ArticleBlocEvent {}

/// Fetch a complete article based on the [header].
class ArticleBlocFetchArticleEvent extends ArticleBlocEvent {
  final Header header;

  ArticleBlocFetchArticleEvent(this.header);
}

/// Fetch an article body based on the [header].
class ArticleBlocFetchBodyEvent extends ArticleBlocEvent {
  final Header header;

  ArticleBlocFetchBodyEvent(this.header);
}

abstract class ArticleBlocState {}
class ArticleBlockInitialState extends ArticleBlocState {}

/// Return [header] and [body].
class ArticleBlocFetchedState extends ArticleBlocState {
  final Header header;
  final List<String> body;

  ArticleBlocFetchedState(this.header, this.body);
}

class ArticleBloc extends Bloc<ArticleBlocEvent, ArticleBlocState> {
  final NewsService _newsService;

  ArticleBloc(this._newsService) : super(ArticleBlockInitialState());

  @override
  Stream<ArticleBlocState> mapEventToState(ArticleBlocEvent event) async* {
    if (event is ArticleBlocFetchArticleEvent) {
      final response = await _newsService.fetchArticle(event.header);
      yield ArticleBlocFetchedState(response.headers, response.body);
    }
    if (event is ArticleBlocFetchBodyEvent) {
      yield ArticleBlocFetchedState(
          event.header, await _newsService.fetchBody(event.header));
    }
  }

}