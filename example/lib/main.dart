import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sliver_value_listenable_builder/sliver_value_listenable_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final PagingController<int, String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<int, String>(
      initial: () async => const PageBlock<int, String>(
        items: [1, 2, 3, 4, 5],
        nextKey: 'first',
      ),
      append: (nextKey) async => const PageBlock<int, String>(
        items: [1, 2, 3, 4, 5, 6],
        nextKey: 'second',
      ),
    )..loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: CustomScrollView(
        slivers: [
          SliverValueListenableBuilder<PagingState<int, String>>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final pages = [...state.pages];
              if (pages.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final last = pages.removeLast();
              return MultiSliver(
                children: [
                  ...pages.map(
                    (page) => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ListTile(
                          title: Text(
                            page.items[index].toString(),
                          ),
                          subtitle: const Text('first'),
                        ),
                        childCount: page.items.length,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if ((last.items.length - 1) == index) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) async {
                              final key = last.nextKey;
                              if (key != null) {
                                await _controller.loadAppend(key);
                              }
                            },
                          );
                        }

                        return ListTile(
                          title: Text(
                            last.items[index].toString(),
                          ),
                          subtitle: const Text('second'),
                        );
                      },
                      childCount: last.items.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

typedef LoadInitial<T, K> = Future<PageBlock<T, K>> Function();

typedef LoadAppend<T, K> = Future<PageBlock<T, K>> Function(K nextKey);

class PagingController<T, K> extends ValueNotifier<PagingState<T, K>> {
  PagingController({
    required this.initial,
    required this.append,
  }) : super(
          const PagingState(
            state: ControllerState.init,
            pages: [],
          ),
        );

  final LoadInitial<T, K> initial;
  final LoadAppend<T, K> append;

  Future<void> refresh() async {
    value = const PagingState(
      state: ControllerState.init,
      pages: [],
    );

    await loadInitial();
  }

  Future<void> loadInitial() async {
    if (value.state != ControllerState.init) {
      return;
    }

    value = const PagingState(
      state: ControllerState.initLoading,
      pages: [],
    );
    final page = await initial();
    value = PagingState(
      state: ControllerState.loadSuccess,
      pages: [page],
    );
  }

  Future<void> loadAppend(K nextKey) async {
    if (value.state == ControllerState.appendLoading) {
      return;
    }

    value = PagingState(
      state: ControllerState.appendLoading,
      pages: value.pages,
    );
    final page = await append(nextKey);
    value = PagingState(
      state: ControllerState.loadSuccess,
      pages: [...value.pages, page],
    );
  }
}

@immutable
class PagingState<T, K> {
  const PagingState({
    required this.state,
    required this.pages,
  });

  final ControllerState state;

  final List<PageBlock<T, K>> pages;
}

@immutable
class PageBlock<T, K> {
  const PageBlock({
    required this.items,
    required this.nextKey,
  });

  final List<T> items;
  final K? nextKey;
}

enum ControllerState {
  init,
  initLoading,
  loadSuccess,
  loadFailure,
  appendLoading,
}
