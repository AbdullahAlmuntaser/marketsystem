import 'package:drift/drift.dart';
import '../app_database.dart';

part 'gl_entries_dao.g.dart';

@DriftAccessor(tables: [GLEntries, GLLines])
class GLEntriesDao extends DatabaseAccessor<AppDatabase> with _$GLEntriesDaoMixin {
  GLEntriesDao(super.db);

  Future<int> insertGLEntry(GLEntriesCompanion companion) =>
      into(glEntries).insert(companion);

  Future<void> insertGLLines(List<GLLinesCompanion> lines) async {
    for (final line in lines) {
      await into(glLines).insert(line);
    }
  }

  Future<GLEntry?> getGLEntryById(int id) =>
      (select(glEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<GLEntry>> getAllGLEntries() => select(glEntries).get();

  Future<List<GLLine>> getGLLines(int entryId) =>
      (select(glLines)..where((t) => t.entryId.equals(entryId))).get();

  Future<bool> updateGLEntry(GLEntriesCompanion companion) =>
      (update(glEntries)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteGLEntry(int id) async {
    await (delete(glLines)..where((t) => t.entryId.equals(id))).go();
    return (await (delete(glEntries)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
