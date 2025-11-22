import 'package:flutter/material.dart';
import 'package:flutter_socket_example/core/i18n/strings.dart';
import 'package:flutter_socket_example/core/locator.dart';
import 'package:flutter_socket_example/core/models/base_model.dart';

class ModelCache {
  final Map<Type, BaseModel> modelCache = {};

  Model builder<Model extends BaseModel>(Model Function() newModel) {
    final cached = modelCache[Model] as Model;
    return cached;
  }

  void dispose() {
    for (final model in modelCache.values) {
      model.dispose();
    }
    modelCache.clear();
  }
}

/// 이 기능은 위젯 트리의 더 상위 레벨에서 모델(Model)을 캐싱할 수 있도록 해줍니다.
/// 즉, 화면(View)의 생명주기와 상관없이 모델 인스턴스를 유지하고 재사용할 수 있습니다.
///
/// 사용 방법은 두 가지입니다:
///  1. [View]에 [CachedModelBuilder<Model>]을 전달하여 사용합니다.
///  2. 또는 [ModelCache] 위젯을 사용하고, 해당 위젯의 builder 함수를 전달해 사용합니다.
///
/// **중요**: 모델이 캐시될 경우 더 이상 프레임워크에서 자동으로 dispose되지 않습니다.
/// 즉, 화면이 종료되더라도 모델이 계속 살아있기 때문에
/// 메모리 누수를 방지하기 위해 모델을 직접 dispose하는 관리가 필요합니다.
/// (dispose 시점은 모델을 캐싱하는 위치에서 결정해야 합니다.)
typedef CachedModelBuilder<Model> = Model Function(Model Function() newModel);

class View<Model extends BaseModel> extends StatefulWidget {
  final Widget child;

  final Widget Function(BuildContext context, Model value, Widget child)
  builder;

  final Widget Function(BuildContext context)? loaderBuilder;

  final Widget Function(BuildContext context, Model model)? errorBuilder;

  final bool showLoader;

  final void Function(Model model)? onModelReady;

  final bool showError;

  /// 위젯 트리 상단에서 모델을 캐싱할 수 있는 기능을 제공합니다.
  /// 이 기능을 사용하려면:
  ///   - [View] 위젯에 [CachedModelBuilder<Model>]을 전달하거나,
  ///   - [ModelCache] 위젯을 사용하고 해당 builder 함수를 전달하면 됩니다.
  ///
  /// **주의사항**:
  /// 모델이 캐시되는 경우 더 이상 자동으로 dispose되지 않습니다.
  /// 즉, 모델의 생명주기가 화면(View)의 생명주기와 분리되므로
  /// 모델을 캐싱한 위치에서 직접 dispose를 호출하여 정리해야 합니다.
  final CachedModelBuilder<Model>? cachedModelBuilder;

  /// 위젯 트리 상위 레벨에서 모델을 캐싱할 수 있도록 합니다.
  /// **이 경우 모델의 생명주기가 자동으로 관리되지 않기 때문에,
  /// 캐싱한 위치에서 직접 dispose를 수행해야 합니다.**
  final Model? cachedModel;

  const View({
    super.key,
    required this.builder,
    required this.child,
    this.onModelReady,
    this.cachedModelBuilder,
    this.cachedModel,
    this.loaderBuilder,
    this.errorBuilder,
    this.showLoader = true,
    this.showError = true,
  }) : assert(
         (cachedModel == null) != (cachedModelBuilder == null),
         'You can only pass one of `cachedModel` and `cachedModelBuilder`',
       );

  @override
  State<View<Model>> createState() => _ViewState<Model>();
}

class _ViewState<Model extends BaseModel> extends State<View<Model>>
    with WidgetsBindingObserver {
  late Model _model;
  var _isCachedModel = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _model.didChangeAppLifecycleState(state);
  }

  Model _createModel() {
    final model = locate<Model>();
    widget.onModelReady?.call(model);
    return model;
  }

  @override
  void initState() {
    if (widget.cachedModel == null && widget.cachedModelBuilder == null) {
      _model = _createModel();
    } else {
      _isCachedModel = true;
      _model =
          widget.cachedModel ??
          widget.cachedModelBuilder?.call(_createModel) ??
          _createModel();
    }
    if (_model.usesAppLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    _model.addListener(_modelChanged);
    super.initState();
  }

  void _modelChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_modelChanged);
    if (!_isCachedModel) {
      _model.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _model.refreshProvided(context);
    return (widget.showLoader || widget.showError)
        ? AnimatedSwitcher(
          duration: const Duration(milliseconds: 330),
          child:
              _model.isLoading && widget.showLoader
                  ? widget.loaderBuilder?.call(context) ??
                      const Center(child: CircularProgressIndicator())
                  : _model.hasError && widget.showError
                  ? widget.errorBuilder?.call(context, _model) ??
                      ConnectionErrorIndicator(model: _model)
                  : widget.builder(context, _model, widget.child),
        )
        : widget.builder(context, _model, widget.child);
  }
}

class ConnectionErrorIndicator extends StatelessWidget {
  final BaseModel model;
  final double topPadding;

  const ConnectionErrorIndicator({
    super.key,
    required this.model,
    this.topPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: topPadding),
          const Icon(Icons.error),
          const SizedBox(height: 16),
          Text(
            Strings.of(context)?.errors.failedLoading ??
                'Something went wrong while loading.\n press retry to try again.',
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: model.retryLoading,
            child: Text(Strings.of(context)?.errors.tryAgain ?? 'Try again'),
          ),
        ],
      ),
    );
  }
}
