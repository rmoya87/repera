"""Regression contract for the iOS library's independent ordering and filtering."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=(ROOT/"Apps/Repera/Sources/LibraryView.swift").read_text(encoding="utf8")

class LibrarySortFilterContractTests(unittest.TestCase):
    def test_native_sheet_has_two_separate_sections(self):
        self.assertIn('Section("Ordenar")', SRC)
        self.assertIn('Section("Filtrar")', SRC)
        self.assertLess(SRC.index('Section("Ordenar")'), SRC.index('Section("Filtrar")'))
        self.assertIn('NavigationStack {\n            Form {', SRC)
        self.assertIn('.presentationDetents([.medium, .large])', SRC)
        self.assertIn('Button("Hecho") { showFilter = false }', SRC)

    def test_independent_sort_and_filter_choices(self):
        self.assertIn('private enum ExerciseSortMode', SRC)
        self.assertIn('private enum ExerciseFilterMode', SRC)
        self.assertIn('@State private var sortMode: ExerciseSortMode = .alphabetical', SRC)
        self.assertIn('@State private var filterMode: ExerciseFilterMode = .all', SRC)
        self.assertIn('sortMode = mode', SRC)
        self.assertIn('filterMode = mode', SRC)
        self.assertIn('sortMode: sort,', SRC)
        self.assertIn('filterMode: filter,', SRC)
        self.assertIn('if !q.isEmpty || sortMode == .alphabetical', SRC)
        self.assertIn('return Dictionary(grouping: rows', SRC)
        self.assertNotIn('ExerciseBrowseMode', SRC)
        self.assertNotIn('case .sport:', SRC)

    def test_facet_is_lifting_not_sport_grouping(self):
        self.assertIn('case .weightlifting: return "Halterofilia"', SRC)
        self.assertIn('case .weightlifting: return doc.disciplineTags.contains("Halterofilia")', SRC)
        for name in ['CrossFit','Gimnasia','HYROX','Movilidad','Favoritos','WODs','Todos']:
            self.assertIn(f'return "{name}"', SRC)
        self.assertIn('case .favorites: return doc.isFavorite', SRC)
        self.assertIn('case .mobility: return doc.disciplineTags.contains("Movilidad")', SRC)
        self.assertIn('case .hyrox: return doc.disciplineTags.contains("HYROX")', SRC)
        self.assertIn('filterMode == .wods', SRC)

if __name__=="__main__":
    unittest.main()
