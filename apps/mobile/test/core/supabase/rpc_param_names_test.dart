// Every circle/community mutation is a Postgres RPC, and PostgREST binds the
// client's `params:` map to the function *by parameter name*. A mismatch is not
// a compile error and not something the fakes can catch — the call just fails at
// runtime, and the circles screens answer that failure with a generic snackbar.
//
// That has happened three times to the same bug class: a plpgsql function whose
// parameter shares a column name (`circle_id`) makes every bare reference in its
// body ambiguous, so Postgres aborts with 42702 and the RPC has never worked
// since the day it was written — get_circle_leaderboard
// (fixed by 20260919203000), and delete_circle + remove_circle_member
// (fixed by 20260925160000).
//
// So this test reads the two sources of truth in the repo and checks they agree:
// the parameter names declared in supabase/migrations/ and the keys actually
// sent from lib/core/supabase/supabase_service.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `create [or replace] function [public.]name(...)` — capturing the name, then
/// scanning forward to the matching close paren so multi-line parameter lists
/// (update_circle_sharing, send_circle_reaction) are read whole.
final _functionDecl = RegExp(
  r'''create\s+(?:or\s+replace\s+)?function\s+(?:(?:"public"|public)\s*\.\s*)?([a-z_][a-z0-9_]*)\s*\(''',
  caseSensitive: false,
);

/// `_db.rpc('name', params: { ... })` — the params map is a flat literal, so
/// stopping at the first `}` is enough.
final _rpcCall = RegExp(
  r'''\.rpc\(\s*'([a-z_][a-z0-9_]*)'(?:\s*,\s*params:\s*\{([^}]*)\})?''',
);

final _paramKey = RegExp(r'''['"]([A-Za-z_][A-Za-z0-9_]*)['"]\s*:''');

/// Parameter names of one declared function, in declaration order.
List<String> _declaredParams(String params) => params
    .split(_topLevelCommas)
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .map((p) => _paramName.firstMatch(p)!.group(1)!)
    .toList();

/// Splits on commas that are not nested inside parentheses — `returns table(...)`
/// style nesting can appear in a parameter list.
final _topLevelCommas = RegExp(r',(?![^(]*\))');

final _paramName = RegExp(r'^(?:in\s+|out\s+)?([A-Za-z_][A-Za-z0-9_]*)', caseSensitive: false);

/// Reads the parenthesised block starting at [open], returning its contents and
/// the index just past the closing paren.
({String body, int end}) _readParens(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '(') {
      depth++;
    } else if (source[i] == ')') {
      depth--;
      if (depth == 0) {
        return (body: source.substring(open + 1, i), end: i + 1);
      }
    }
  }
  throw StateError('Unbalanced parentheses in a function declaration');
}

Map<String, List<String>> _signaturesFromMigrations(Directory migrations) {
  final files =
      migrations
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  // Later files re-create earlier functions (that is how a fix migration
  // supersedes the broken original), so iterate in timestamp order and let the
  // last definition win.
  final signatures = <String, List<String>>{};
  for (final file in files) {
    final source = file.readAsStringSync();
    for (final match in _functionDecl.allMatches(source)) {
      final open = source.indexOf('(', match.start + match[0]!.length - 1);
      final params = _readParens(source, open).body;
      signatures[match.group(1)!.toLowerCase()] = _declaredParams(params);
    }
  }
  return signatures;
}

void main() {
  test(
    'every rpc() params key matches a declared Postgres parameter name',
    () {
      final signatures = _signaturesFromMigrations(
        Directory('supabase/migrations'),
      );
      expect(
        signatures,
        isNotEmpty,
        reason: 'no create-function statements found — wrong cwd?',
      );

      final clientSource = File(
        'lib/core/supabase/supabase_service.dart',
      ).readAsStringSync();
      final calls = _rpcCall.allMatches(clientSource).toList();
      expect(calls, isNotEmpty, reason: 'found no .rpc() calls to check');

      final problems = <String>[];
      for (final call in calls) {
        final name = call.group(1)!;
        final declared = signatures[name];
        if (declared == null) {
          problems.add(
            '$name: called by the client but declared in no migration',
          );
          continue;
        }
        final sent =
            _paramKey
                .allMatches(call.group(2) ?? '')
                .map((m) => m.group(1)!)
                .toList();
        for (final key in sent) {
          if (!declared.contains(key)) {
            problems.add(
              '$name: client sends "$key", migration declares '
              '${declared.isEmpty ? "no parameters" : declared.join(', ')}',
            );
          }
        }
        if (sent.isEmpty && declared.isNotEmpty) {
          problems.add(
            '$name: migration declares ${declared.join(', ')} but the '
            'client sends no params',
          );
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    },
  );

  test(
    'every RPC parameter is p_-prefixed, except the grandfathered ones',
    () {
      final signatures = _signaturesFromMigrations(
        Directory('supabase/migrations'),
      );

      final problems = <String>[];
      for (final entry in signatures.entries) {
        if (_grandfathered.contains(entry.key)) continue;
        for (final param in entry.value) {
          if (!param.startsWith('p_')) {
            problems.add('${entry.key}: parameter "$param" is not p_-prefixed');
          }
        }
      }

      expect(
        problems,
        isEmpty,
        reason:
            'A plpgsql parameter that shares a column name makes every bare '
            'reference in the function body ambiguous, so Postgres aborts with '
            '42702 and the RPC fails on every call. Prefix parameters with '
            'p_ (and keep the client params map in step — test 1 above).\n'
            '${problems.join('\n')}',
      );
    },
  );
}

/// Functions that predate the p_ convention and work today. Renaming a live
/// parameter would break the released client that calls it by the old name, so
/// they stay — but nothing new may join this list.
///
/// - `rename_circle(circle_id, new_name)` is safe only because the `circles`
///   table has neither column, so its body has nothing to be ambiguous about.
const _grandfathered = {
  'rename_circle',
  'increment_community_adhkar_likes',
  'increment_community_duas_likes',
};
