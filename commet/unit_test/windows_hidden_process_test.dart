// The booth builds a source extension's command line itself on Windows, so
// that the program (and whatever it starts in turn) gets a console with no
// window instead of one that flashes up. These pin the quoting: a folder with
// a space in it, or the JSON request with its quotes and backslashes, has to
// arrive as one argument.
import 'package:commet/utils/windows_hidden_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a plain argument is left alone', () {
    expect(quoteWindowsArgument('--allow-all'), '--allow-all');
    expect(quoteWindowsArgument(r'C:\Users\dj\deps\deno.exe'),
        r'C:\Users\dj\deps\deno.exe');
  });

  test('an empty argument is still an argument', () {
    expect(quoteWindowsArgument(''), '""');
  });

  test('spaces and tabs are quoted', () {
    expect(quoteWindowsArgument(r'C:\Program Files\dj-songs\a.%(ext)s'),
        r'"C:\Program Files\dj-songs\a.%(ext)s"');
    expect(quoteWindowsArgument('Daft Punk - One More Time'),
        '"Daft Punk - One More Time"');
  });

  test('quotes are escaped', () {
    expect(quoteWindowsArgument('say "hi"'), r'"say \"hi\""');
  });

  test("a request's JSON, with a folder ending in a backslash", () {
    // jsonEncode({'d': r'C:\a\'}): the two backslashes before the closing
    // quote of the JSON string double, and the quote is escaped.
    expect(quoteWindowsArgument(r'{"d":"C:\\a\\"}'),
        r'"{\"d\":\"C:\\a\\\\\"}"');
  });

  test('backslashes only double where they would escape a quote', () {
    // Inside the argument they mean themselves...
    expect(quoteWindowsArgument(r'a\b c'), r'"a\b c"');
    // ...before a quote, and before the closing one, they do not.
    expect(quoteWindowsArgument(r'a\"b c'), r'"a\\\"b c"');
    expect(quoteWindowsArgument(r'C:\songs\ dir'), r'"C:\songs\ dir"');
    // A trailing one would escape the closing quote, so it is doubled.
    expect(quoteWindowsArgument('C:\\my songs\\'), r'"C:\my songs\\"');
    // Without a space there is no quote for it to escape.
    expect(quoteWindowsArgument('C:\\songs\\'), 'C:\\songs\\');
  });
}
