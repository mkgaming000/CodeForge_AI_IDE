import 'package:codeforge/core/utils/undo_redo_stack.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text) => TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  group('UndoRedoStack', () {
    test('starts empty with nothing to undo or redo', () {
      final stack = UndoRedoStack();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.current, isNull);
    });

    test('reset seeds the stack with an initial value', () {
      final stack = UndoRedoStack();
      stack.reset(_value('hello'));
      expect(stack.current?.text, 'hello');
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });

    test('push records new text states and enables undo', () {
      final stack = UndoRedoStack();
      stack.reset(_value('a'));
      stack.push(_value('ab'));
      expect(stack.canUndo, isTrue);
      expect(stack.current?.text, 'ab');
    });

    test('undo reverts to the previous state and enables redo', () {
      final stack = UndoRedoStack();
      stack.reset(_value('a'));
      stack.push(_value('ab'));
      stack.push(_value('abc'));

      final undone = stack.undo();
      expect(undone?.text, 'ab');
      expect(stack.canRedo, isTrue);
    });

    test('redo re-applies an undone state', () {
      final stack = UndoRedoStack();
      stack.reset(_value('a'));
      stack.push(_value('ab'));
      stack.push(_value('abc'));

      stack.undo();
      final redone = stack.redo();
      expect(redone?.text, 'abc');
      expect(stack.canRedo, isFalse);
    });

    test('pushing a new state after an undo clears the redo stack', () {
      final stack = UndoRedoStack();
      stack.reset(_value('a'));
      stack.push(_value('ab'));
      stack.undo();
      expect(stack.canRedo, isTrue);

      stack.push(_value('ax'));
      expect(stack.canRedo, isFalse);
      expect(stack.current?.text, 'ax');
    });

    test('pushing the same text only updates selection, not a new undo entry', () {
      final stack = UndoRedoStack();
      stack.reset(_value('hello'));
      stack.push(const TextEditingValue(text: 'hello', selection: TextSelection.collapsed(offset: 2)));
      // Same text -> should not create a separate undo step.
      expect(stack.canUndo, isFalse);
      expect(stack.current?.selection.baseOffset, 2);
    });

    test('undo returns null when there is nothing to undo', () {
      final stack = UndoRedoStack();
      stack.reset(_value('only'));
      expect(stack.undo(), isNull);
    });

    test('redo returns null when there is nothing to redo', () {
      final stack = UndoRedoStack();
      stack.reset(_value('only'));
      expect(stack.redo(), isNull);
    });

    test('respects maxEntries by evicting the oldest snapshot', () {
      final stack = UndoRedoStack(maxEntries: 3);
      stack.reset(_value('1'));
      stack.push(_value('2'));
      stack.push(_value('3'));
      stack.push(_value('4')); // exceeds maxEntries=3, evicts '1'

      // Undo all the way; we should never reach '1'.
      final history = <String?>[];
      while (stack.canUndo) {
        history.add(stack.undo()?.text);
      }
      expect(history, isNot(contains('1')));
    });
  });
}
