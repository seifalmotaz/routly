library routly;

enum ParameterType {
  string,
  num,
  int,
  double,
  bool,
  any,
  path,
}

typedef NodeParameter = ({
  String name,
  ParameterType type,
});

class RoutlyNotFound extends Error {
  RoutlyNotFound();
}

class TreeNode<T> {
  final String path;
  final List<NodeParameter> parameters;
  final bool isStatic;
  final RegExp? regExp;
  final List<TreeNode<T>> children;
  final T? value;

  const TreeNode({
    required this.path,
    required this.regExp,
    required this.isStatic,
    required this.children,
    required this.value,
    required this.parameters,
  });

  bool match(String reqPath, Map<String, Object> params) {
    if (isStatic) {
      return path == reqPath;
    }

    final matches = regExp!.allMatches(reqPath).first;
    for (var i = 0; i < parameters.length; i++) {
      final param = parameters[i];
      final val = matches[i + 1] ?? '';
      late Object valueNativeTyped;
      switch (param.type) {
        case ParameterType.any:
          valueNativeTyped = val;
          break;
        case ParameterType.bool:
          valueNativeTyped = val == 'true' || val == '1' ? true : false;
        case ParameterType.double:
          valueNativeTyped = double.parse(val);
        case ParameterType.int:
          valueNativeTyped = int.parse(val);
        case ParameterType.num:
          valueNativeTyped = num.parse(val);
        case ParameterType.path:
          valueNativeTyped = val;
        case ParameterType.string:
          valueNativeTyped = val;
      }
      params[param.name] = valueNativeTyped;
    }

    return true;
  }

  ({TreeNode<T> node, Map<String, Object> params}) find(String path, Map<String, Object> params) {
    if (children.isEmpty) {
      return (node: this, params: params);
    }
    for (var c in children) {
      final isMatch = c.match(path, params);
      if (isMatch) {
        return (node: c, params: params);
      }
      continue;
    }
    throw RoutlyNotFound();
  }
}

class Routly<T> {
  final rootNode = TreeNode<T>(
    path: '',
    regExp: null,
    isStatic: true,
    children: [],
    value: null,
    parameters: [],
  );

  void add(String path, Object? val) {
    _parsePath(path, val, rootNode);
  }

  void sort() {
    _sortNodes(rootNode);
  }

  (Map<String, Object>, T val) match(String path) {
    final segments = path.split('/')..removeWhere((e) => e.isEmpty);
    final params = <String, Object>{};
    TreeNode currentNode = rootNode;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final match = currentNode.find(seg, params);
      currentNode = match.node;
    }
    return (params, currentNode.value);
  }
}

final RegExp _parmRegExp = RegExp(r"{(\w+)\:?(\w+)?}", caseSensitive: false);
TreeNode _parsePath(String path, Object? val, TreeNode root) {
  final normalizedPath = path.replaceAll('\\', '/');
  final segments = normalizedPath.split('/')..removeWhere((e) => e.isEmpty);

  TreeNode currentNode = root;

  for (final segment in segments) {
    if (segment.isEmpty) continue;

    final params = <NodeParameter>[];
    final segmentReg = segment.replaceAllMapped(_parmRegExp, (match) {
      String regex = '';

      String paramName = match[1]!;
      String? type = match[2];
      late ParameterType enumType;

      switch (type) {
        case 'int':
          regex += r"[0-9]+";
          enumType = ParameterType.int;
          break;
        case 'double':
          regex += r"[0-9]*\.[0-9]+";
          enumType = ParameterType.double;
          break;
        case 'num':
          regex += r"[0-9]*(\.[0-9]+)?";
          enumType = ParameterType.num;
          break;
        case 'any':
          regex += r"[^\\/]+";
          enumType = ParameterType.any;
          break;
        case 'path':
          regex += r"\/.*|";
          enumType = ParameterType.path;
          // usesWildcardMatcher = true;
          break;
        default:
          regex += r"[a-zA-Z0-9_\-\.]+";
          enumType = ParameterType.string;
      }
      params.add((name: paramName, type: enumType));
      return "($regex)";
    });

    TreeNode? child = currentNode.children.cast<TreeNode?>().firstWhere(
          (node) => node?.path == segment,
          orElse: () => null,
        );

    final bool isDynamicPath = segmentReg != segment;

    if (child == null) {
      child = TreeNode(
        path: segment,
        isStatic: isDynamicPath == false,
        children: [],
        value: val,
        parameters: params,
        regExp: isDynamicPath
            ? RegExp(
                segmentReg,
                caseSensitive: false,
              )
            : null,
      );
      currentNode.children.add(child);
    }
    currentNode = child;
  }
  return root;
}

void _sortNodes(TreeNode node) {
  // 1. static first
  // 2. less string length
  // 3. less children
  node.children.sort((a, b) {
    if (a.isStatic != b.isStatic) {
      final i = a.isStatic ? 1 : 0;
      final i2 = b.isStatic ? 1 : 0;
      return i2.compareTo(i);
    }
    // then string length (or regex length if both are regex)
    final s = a.regExp == null ? a.path : a.regExp!.pattern;
    final s2 = b.regExp == null ? b.path : b.regExp!.pattern;
    if (s.length != s2.length) {
      return s.length.compareTo(s2.length);
    }
    return a.children.length.compareTo(b.children.length);
  });
  for (var child in node.children) {
    _sortNodes(child);
  }
}
